// ============================================================
// auth_service.dart
// Maneja todo lo relacionado con autenticación de usuarios:
// registro, login, logout y verificación de sesión.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}