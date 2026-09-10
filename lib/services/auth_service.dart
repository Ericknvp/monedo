// ============================================================
// auth_service.dart
// Maneja todo lo relacionado con autenticación de usuarios:
// registro, login, logout y verificación de sesión.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---- Obtiene el usuario actual de Firebase ----
  User? get currentUser => _auth.currentUser;

  // ---- Stream que escucha cambios en la sesión ----
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---- Verifica si un nombre de usuario ya existe ----
  Future<bool> usernameExists(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return query.docs.isNotEmpty;
  }

  // ---- Registro de nuevo usuario ----
  Future<String?> register({
    required String username,
    required String email,
    required String password,
    String? currency,
  }) async {
    try {
      // Crea el usuario en Firebase Auth primero: las reglas de Firestore
      // solo permiten leer la colección 'users' a usuarios autenticados
      // (igual que en el flujo de Google), así que la verificación de
      // username único debe hacerse después de tener sesión.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (await usernameExists(username)) {
        await credential.user!.delete();
        return 'El nombre de usuario ya está en uso';
      }

      // Guarda la info del usuario en Firestore
      final user = UserModel(
        id: credential.user!.uid,
        username: username,
        email: email,
        createdAt: DateTime.now(),
        currency: currency,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      return null; // null significa que no hubo error
    } on FirebaseAuthException catch (e) {
      // Mensajes de error en español
      switch (e.code) {
        case 'email-already-in-use':
          return 'El correo ya está registrado';
        case 'weak-password':
          return 'La contraseña es muy débil';
        case 'invalid-email':
          return 'El correo no es válido';
        default:
          return 'Error al registrarse. Intenta de nuevo';
      }
    } catch (_) {
      return 'Error al registrarse. Intenta de nuevo';
    }
  }

  // ---- Inicio de sesión ----
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // null significa que no hubo error
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe una cuenta con ese correo';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-email':
          return 'El correo no es válido';
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos';
        default:
          return 'Error al iniciar sesión. Intenta de nuevo';
      }
    }
  }

  // ---- Inicio de sesión o registro con Google ----
  // Retorna un mensaje de error (o null si todo salió bien) junto con si
  // la cuenta de Firestore se acaba de crear (usuario nuevo).
  Future<(String? error, bool isNewUser)> signInWithGoogle() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        credential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          // El usuario cerró el selector de cuentas sin elegir ninguna
          return (null, false);
        }
        final googleAuth = await googleUser.authentication;
        final oauthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(oauthCredential);
      }

      final user = credential.user!;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final isNewUser = !doc.exists;

      if (isNewUser) {
        final username = await _generateUsernameFrom(user);
        final userModel = UserModel(
          id: user.uid,
          username: username,
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }

      return (null, isNewUser);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return (
            'Ya existe una cuenta con ese correo usando otro método de inicio de sesión',
            false
          );
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return (null, false);
        default:
          return ('Error al iniciar sesión con Google. Intenta de nuevo', false);
      }
    } catch (_) {
      return ('Error al iniciar sesión con Google. Intenta de nuevo', false);
    }
  }

  // ---- Genera un nombre de usuario único a partir del perfil de Google ----
  Future<String> _generateUsernameFrom(User user) async {
    final base = (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim().replaceAll(RegExp(r'\s+'), '_')
            : user.email?.split('@').first) ??
        'usuario';
    var candidate = base;
    var suffix = 0;
    while (await usernameExists(candidate)) {
      suffix++;
      candidate = '$base$suffix';
    }
    return candidate;
  }

  // ---- Envía un correo para restablecer la contraseña ----
  // Por seguridad, no revela si el correo está registrado o no: siempre
  // retorna null (éxito) salvo que el formato del correo sea inválido o
  // falle el envío por un problema real (ej. de red).
  //
  // El link del correo abre directamente nuestra propia pantalla (en vez
  // de la página genérica de Firebase), para que se vea con la marca
  // Monedo. En web usa el dominio/puerto actual; fuera de web (la app
  // abre en el navegador del celular) usa el hosting de Firebase.
  Future<String?> sendPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Ingresa tu correo electrónico';
    try {
      final origin =
          kIsWeb ? Uri.base.origin : 'https://monedo-e7849.web.app';
      await _auth.sendPasswordResetEmail(
        email: trimmed,
        actionCodeSettings: ActionCodeSettings(
          url: '$origin/?view=reset-password',
          handleCodeInApp: true,
        ),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'El correo no es válido';
        case 'user-not-found':
          return null;
        default:
          return 'No se pudo enviar el correo. Intenta de nuevo';
      }
    } catch (_) {
      return 'No se pudo enviar el correo. Intenta de nuevo';
    }
  }

  // ---- Verifica que un link de restablecimiento sea válido ----
  // Retorna el correo asociado (o un mensaje de error si expiró / no es
  // válido / ya fue usado).
  Future<(String? email, String? error)> verifyPasswordResetCode(
      String oobCode) async {
    try {
      final email = await _auth.verifyPasswordResetCode(oobCode);
      return (email, null);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'expired-action-code':
          return (null, 'Este link ya expiró. Solicita uno nuevo.');
        case 'invalid-action-code':
          return (null, 'Este link no es válido o ya fue usado.');
        default:
          return (null, 'No se pudo verificar el link.');
      }
    } catch (_) {
      return (null, 'No se pudo verificar el link.');
    }
  }

  // ---- Confirma la nueva contraseña usando el código del link ----
  Future<String?> confirmPasswordReset(
      String oobCode, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(
        code: oobCode,
        newPassword: newPassword,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'expired-action-code':
          return 'Este link ya expiró. Solicita uno nuevo.';
        case 'invalid-action-code':
          return 'Este link no es válido o ya fue usado.';
        case 'weak-password':
          return 'La contraseña es muy débil.';
        default:
          return 'No se pudo actualizar la contraseña. Intenta de nuevo.';
      }
    } catch (_) {
      return 'No se pudo actualizar la contraseña. Intenta de nuevo.';
    }
  }

  // ---- Indica si la cuenta tiene contraseña (no solo Google, etc.) ----
  bool get hasPasswordProvider =>
      currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  // ---- Cambia la contraseña del usuario autenticado ----
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) return 'No hay una sesión activa';
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'La contraseña actual es incorrecta';
        case 'weak-password':
          return 'La nueva contraseña es muy débil';
        case 'requires-recent-login':
          return 'Por seguridad, vuelve a iniciar sesión e intenta de nuevo';
        default:
          return 'No se pudo cambiar la contraseña. Intenta de nuevo';
      }
    } catch (_) {
      return 'No se pudo cambiar la contraseña. Intenta de nuevo';
    }
  }

  // ---- Cerrar sesión ----
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---- Obtiene los datos del usuario actual desde Firestore ----
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ---- Cambia el nombre de usuario (debe ser único) ----
  Future<String?> updateUsername(String newUsername) async {
    final trimmed = newUsername.trim();
    if (trimmed.isEmpty) return 'El nombre de usuario no puede estar vacío';
    if (currentUser == null) return 'No hay una sesión activa';

    final current = await getCurrentUserData();
    if (current?.username == trimmed) return null; // sin cambios

    if (await usernameExists(trimmed)) {
      return 'El nombre de usuario ya está en uso';
    }

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update({'username': trimmed});
    return null;
  }

  // ---- Guarda la moneda preferida del usuario actual ----
  Future<void> updateCurrency(String currencyCode) async {
    if (currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update({'currency': currencyCode});
  }
}