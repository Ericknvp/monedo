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
  /// el `uid` del usuario.
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

    try {
      await invalidatePendingPins(uid);
    } on FirebaseException catch (e) {
      throw TelegramLinkException(_describeFirebaseError(e));
    }

    final now = DateTime.now();
    final expiresAt = now.add(pinLifetime);

    // El ID del documento es el propio PIN: si el ID ya existe, ese
    // PIN está tomado por otro usuario y hay que generar otro. Con un
    // espacio de 6 dígitos (1 millón de combinaciones) el choque es
    // rarísimo, pero se comprueba dentro de una transacción para que
    // dos usuarios que consigan el mismo PIN al mismo tiempo no puedan
    // pisarse: la escritura solo se confirma si el documento seguía
    // sin existir.
    for (var attempt = 0; attempt < 10; attempt++) {
      final pin = _generatePin();
      final docRef = _firestore.collection(pinsCollection).doc(pin);
      try {
        await _firestore.runTransaction((txn) async {
          final snapshot = await txn.get(docRef);
          if (snapshot.exists) {
            throw const _PinTakenException();
          }
          txn.set(docRef, {
            'pin': pin,
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiresAt),
            'used': false,
          });
        });

        return TelegramPin(
          pin: pin,
          uid: uid,
          createdAt: now,
          expiresAt: expiresAt,
          used: false,
        );
      } on _PinTakenException {
        // Ese PIN ya existe: probamos con otro.
        continue;
      } on FirebaseException catch (e) {
        throw TelegramLinkException(_describeFirebaseError(e));
      }
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

  /// Borra los PINs pendientes del usuario que ya no sirven.
  ///
  /// Se filtra solo por `uid` (un único filtro de igualdad) en vez de
  /// por `uid` + `used`: con un solo campo basta el índice de campo
  /// simple, sin depender del merge de índices, y la regla de seguridad
  /// se puede comprobar sin ambigüedad. Un usuario tiene como mucho un
  /// PIN vivo, así que filtrar por `used` en Dart no cuesta nada.
  Future<void> invalidatePendingPins(String uid) async {
    final pending = await _firestore
        .collection(pinsCollection)
        .where('uid', isEqualTo: uid)
        .get();

    final stale = pending.docs.where((doc) => doc.get('used') != true);
    if (stale.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in stale) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Elimina un PIN concreto (por ejemplo cuando expira sin usarse).
  Future<void> deletePin(String pin) async {
    await _firestore.collection(pinsCollection).doc(pin).delete();
  }

  /// Estado de vinculación del usuario, en tiempo real.
  ///
  /// Combina el documento del usuario (`users/{uid}`), que es la fuente
  /// de verdad de `telegramLinked`, con el registro del chat
  /// (`telegram_links/{uid}`), que aporta el @usuario de Telegram.
  Stream<TelegramUserState> watchState(String uid) {
    return Stream.multi((controller) {
      var cancelled = false;
      bool? linked;
      String? chatId;
      String? monedoUsername;
      String? telegramUsername;

      void emit() {
        if (cancelled || linked == null) return;
        controller.add(TelegramUserState(
          uid: uid,
          linked: linked!,
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
        linked = data[linkedField] as bool? ?? false;
        chatId = data[chatIdField]?.toString();
        monedoUsername = data['username'] as String?;
        emit();
      });

      final linkSub = _firestore
          .collection(linksCollection)
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        final data = snapshot.data();
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
  Future<void> unlink(String uid) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection(linksCollection).doc(uid));
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

/// Señal interna: el PIN generado ya existe en Firestore y hay que
/// probar con otro. No sale del servicio.
class _PinTakenException implements Exception {
  const _PinTakenException();
}
