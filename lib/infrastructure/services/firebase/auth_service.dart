import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 Registrar usuario
  Future<User?> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  // 🔑 Iniciar sesión
  Future<User?> logIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  // 🔁 Escuchar sesión activa
  Stream<User?> get userStream => _auth.authStateChanges();

  // 🚪 Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 👤 Obtener usuario actual
  User? get currentUser => _auth.currentUser;
}
