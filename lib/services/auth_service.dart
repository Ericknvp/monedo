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
      // Verifica que el nombre de usuario no exista
      if (await usernameExists(username)) {
        return 'El nombre de usuario ya está en uso';
      }

      // Crea el usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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