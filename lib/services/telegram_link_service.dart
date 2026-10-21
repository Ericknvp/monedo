import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/telegram_pin.dart';
import '../models/telegram_user_state.dart';

/// Error de negocio del flujo de vinculación con Telegram.
class TelegramLinkException implements Exception {
  final String message;

  const TelegramLinkException(this.message);

  @override
  String toString() => message;
}

/// Servicio de vinculación entre la cuenta de Monedo y una de Telegram.
///
/// ## Cómo funciona el flujo
///
/// 1. La app genera un PIN de 6 dígitos y lo guarda en
///    `telegram_pins/{pin}` con el `uid` del usuario y una ventana de
///    validez de 5 minutos.
/// 2. El usuario abre el bot de Telegram y envía `/vincular <usuario> <PIN>`.
/// 3. El bot (que usa credenciales de servidor y por tanto ignora las
///    reglas de seguridad) busca `telegram_pins/{pin}`, comprueba que
///    `used == false` y que `expiresAt` todavía no pasó, marca el
///    documento como `used: true`, escribe la relación en
///    `telegram_links/{uid}` y actualiza el documento del usuario con
///    `telegramLinked: true` y `telegramChatId: <chat id>`.
///
/// Desde la app solo se escribe en `telegram_pins` y en el documento
/// del propio usuario; `telegram_links` únicamente se lee y se borra
/// al desvincular.
class TelegramLinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random.secure();

  /// Colección con los PINs pendientes de canjear. El ID del documento
  /// ES el PIN, para que el bot pueda buscarlo directamente.
  static const String pinsCollection = 'telegram_pins';

  /// Colección con la relación chat_id <-> uid. El ID del documento es
  /// el `chat.id` de Telegram, NO el uid.
  ///
  /// Keying por chat y no por uid porque la relación es 1 a 1 en las dos
  /// direcciones: una cuenta no puede tener dos chats y un chat no puede
  /// pertenecer a dos cuentas. Con la clave por chat el segundo vinculo
  /// es estructuralmente imposible, y el bot resuelve "de que cuenta es
  /// este chat" con una lectura directa por ID en vez de una consulta.
  static const String linksCollection = 'telegram_links';

  /// Colección de usuarios de Monedo (la misma que usa `AuthService`).
  static const String usersCollection = 'users';

  /// Campo booleano del documento del usuario que indica si ya está
  /// vinculado a un chat de Telegram.
  static const String linkedField = 'telegramLinked';

  /// Campo del documento del usuario con el `chat.id` de Telegram.
  static const String chatIdField = 'telegramChatId';

  /// Ventana de validez del PIN.
  static const Duration pinLifetime = Duration(minutes: 5);

  /// Longitud del PIN.
  static const int pinLength = 6;

  /// Intentos de generación antes de rendirse. Diez colisiones seguidas
  /// sobre un espacio de un millón de combinaciones no son una
  /// colisión: son un problema de permisos.
  static const int maxPinAttempts = 10;

  /// Usuario del bot de Telegram.
  static const String botUsername = 'MonedoApp_bot';

  /// Enlace directo al chat del bot.
  static String get botUrl => 'https://t.me/$botUsername';

  /// UID del usuario con sesión iniciada.
  String? get currentUid => _auth.currentUser?.uid;

  /// Genera un PIN de 6 dígitos, lo persiste y lo devuelve.
  ///
  /// Los PINs anteriores sin usar del mismo usuario se invalidan, para
  /// que solo haya uno vigente en cada momento.
  Future<TelegramPin> createPin() async {
    final uid = currentUid;
    if (uid == null) {
      throw const TelegramLinkException('No hay una sesión activa');
    }

    // La limpieza de PINs previos es best-effort: si falla, el PIN
    // nuevo se genera igual.
    await purgeUserPins(uid);

    final now = DateTime.now();
    final expiresAt = now.add(pinLifetime);

    // La escritura va directa con `set()`, sin transaccion.
    //
    // La version con transaccion no funcionaba: la transaccion empieza
    // LEYENDO el documento para comprobar que el identificador sigue
    // libre, y Firestore deniega la lectura de un documento que aun no
    // existe. El error era de permisos, no de conexion.
    //
    // Sin transaccion no hace falta: las reglas de seguridad ya
    // impiden que un PIN se sobrescriba (`allow update: if false`) y
    // que se cree en nombre de otro usuario. Si el identificador esta
    // ocupado, la escritura se deniega y basta con probar otro PIN.
    var denegados = 0;
    for (var attempt = 0; attempt < maxPinAttempts; attempt++) {
      final pin = _generatePin();
      final docRef = _firestore.collection(pinsCollection).doc(pin);
      try {
        await docRef.set({
          'pin': pin,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'used': false,
        });

        return TelegramPin(
          pin: pin,
          uid: uid,
          createdAt: now,
          expiresAt: expiresAt,
          used: false,
        );
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // El identificador ya esta ocupado: probamos con otro.
          denegados++;
          continue;
        }
        throw TelegramLinkException(_describeFirebaseError(e));
      }
    }

    // Diez denegaciones seguidas casi nunca son una colision real: el
    // espacio es de un millon de combinaciones. Lo probable es que las
    // reglas de seguridad no permitan crear el PIN, y conviene decirlo
    // en vez de pedir que se reintente sin sentido.
    if (denegados == maxPinAttempts) {
      throw const TelegramLinkException(
        'Tu cuenta no tiene permiso para crear el PIN. Revisa las reglas '
        'de seguridad de Firestore.',
      );
    }

    throw const TelegramLinkException(
      'No se pudo generar el PIN. Inténtalo de nuevo',
    );
  }

  /// Traduce un error de Firestore a un mensaje que le diga al usuario
  /// qué pasó y qué puede hacer al respecto.
  ///
  /// Sin esto, cualquier fallo (permisos, red, sesión caducada) llegaba
  /// al diálogo como el mismo "revisa tu conexión", que además era
  /// falso: el error más habitual era un permiso denegado por las
  /// reglas de seguridad.
  String _describeFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Tu cuenta no tiene permiso para crear el PIN. Revisa las '
            'reglas de seguridad de Firestore.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No pudimos conectar con el servidor. Revisa tu conexión e '
            'inténtalo de nuevo.';
      case 'unauthenticated':
        return 'Tu sesión caducó. Vuelve a iniciar sesión e inténtalo de nuevo.';
      case 'failed-precondition':
        return 'El servicio no está disponible en este momento. Inténtalo de '
            'nuevo.';
      default:
        return 'No se pudo generar el PIN. Inténtalo de nuevo.';
    }
  }

  /// Borra los documentos de PIN que dejó el usuario en Firestore.
  ///
  /// Se borran los dos tipos: los pendientes (quedan obsoletos en
  /// cuanto se genera otro) y los ya canjeados (el bot ya los consumio y
  /// son peso muerto). Un PIN canjeado que se queda en Firestore
  /// acabaria siendo un registro permanente de que PIN uso cada
  /// usuario, y no hay ninguna politica de TTL que lo limpie.
  ///
  /// Excepcion: un PIN canjeado que ademas guarde el `chatId` de
  /// Telegram esta sirviendo de indice de "este chat es de esta
  /// cuenta" para el bot, asi que no se toca. Los PINs que solo
  /// guardan `used` ya no sirven para nada y se pueden borrar.
  ///
  /// Es una limpieza de cortesía, no parte del flujo: si la consulta
  /// falla, el PIN se genera igual.
  Future<void> purgeUserPins(String uid) async {
    try {
      final docs = await _firestore
          .collection(pinsCollection)
          .where('uid', isEqualTo: uid)
          .get();

      // Ojo: `DocumentSnapshot.get('campo')` LANZA un StateError si el
      // campo no existe, y en Dart no devuelve null como hace el SDK de
      // JavaScript. Hay que leer del mapa del documento, que si tolera
      // que falte la clave.
      final dead = docs.docs
          .where((doc) => doc.data()['telegramChatId'] == null);
      if (dead.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in dead) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // Sin penalizacion: seguimos con el PIN nuevo. La limpieza es
      // best-effort y no puede impedir generar un PIN.
    }
  }

  /// Elimina un PIN concreto (por ejemplo cuando expira sin usarse).
  Future<void> deletePin(String pin) async {
    await _firestore.collection(pinsCollection).doc(pin).delete();
  }

  /// Estado de vinculación del usuario, en tiempo real.
  ///
  /// Combina el documento del usuario (`users/{uid}`), que es la fuente
  /// de verdad de `telegramLinked`, con el registro del chat
  /// (`telegram_links/{chatId}`), que aporta el @usuario de Telegram.
  ///
  /// El registro del chat se busca por `uid` porque es lo que la app
  /// conoce; el bot lo busca por `chatId`, que es su clave.
  Stream<TelegramUserState> watchState(String uid) {
    return Stream.multi((controller) {
      var cancelled = false;
      bool? linkedFromUser;
      String? chatId;
      String? monedoUsername;
      String? telegramUsername;
      bool linkExists = false;

      void emit() {
        if (cancelled || linkedFromUser == null) return;
        controller.add(TelegramUserState(
          uid: uid,
          // El vinculo cuenta si lo dice el documento del usuario O si
          // existe el registro del chat. Asi el estado no depende de
          // que el bot escriba los dos: con que escriba uno, la app
          // muestra la verdad. Si solo escribiera el registro del chat,
          // la app creeria que la cuenta sigue sin vincular y dejaria
          // que el usuario enchufara un segundo Telegram.
          linked: linkedFromUser! || linkExists,
          chatId: chatId,
          monedoUsername: monedoUsername,
          telegramUsername: telegramUsername,
        ));
      }

      final userSub = _firestore
          .collection(usersCollection)
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        final data = snapshot.data() ?? const <String, dynamic>{};
        linkedFromUser = data[linkedField] as bool? ?? false;
        chatId = data[chatIdField]?.toString();
        monedoUsername = data['username'] as String?;
        emit();
      });

      // El vinculo del chat se busca por el uid del usuario: la app
      // conoce el suyo, pero no conoce el chat hasta que el bot escribe
      // el documento del usuario.
      final linkSub = _firestore
          .collection(linksCollection)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
        // El bot garantiza 1 a 1, pero si algun dia hubiera mas de uno
        // se muestra el primero en lugar de romperse.
        final docs = snapshot.docs;
        final data = docs.isEmpty ? null : docs.first.data();
        linkExists = data != null;
        telegramUsername = (data?['username'] as String?)?.trim();
        emit();
      });

      controller.onCancel = () {
        cancelled = true;
        userSub.cancel();
        linkSub.cancel();
      };
    });
  }

  /// Nombre de usuario de Monedo del usuario actual, para construir el
  /// comando `/vincular <usuario> <PIN>`.
  Future<String?> getMonedoUsername(String uid) async {
    final snapshot = await _firestore.collection(usersCollection).doc(uid).get();
    return snapshot.data()?['username'] as String?;
  }

  /// Desvincula la cuenta de Telegram.
  ///
  /// Borra la relación chat_id <-> uid y deja el documento del usuario
  /// con `telegramLinked: false` y `telegramChatId: null`, todo en un
  /// único lote para que no quede un estado intermedio.
  ///
  /// [chatId] es el chat que se está desconectando. Puede ser `null`
  /// si el documento del usuario todavía no lo tiene: en ese caso solo
  /// se limpia el estado del usuario.
  Future<void> unlink(String uid, String? chatId) async {
    final batch = _firestore.batch();
    final chat = chatId?.trim();
    if (chat != null && chat.isNotEmpty) {
      batch.delete(_firestore.collection(linksCollection).doc(chat));
    }
    batch.update(_firestore.collection(usersCollection).doc(uid), {
      linkedField: false,
      chatIdField: null,
    });
    await batch.commit();
  }

  /// PIN aleatorio de 6 dígitos, generado con entropía criptográfica.
  String _generatePin() {
    return List.generate(pinLength, (_) => _random.nextInt(10)).join();
  }
}
