import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/features/auth/data/google_auth_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // 📧 Логин по email/паролю
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 📧 Сброс пароля
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

    // 🟦 Логин через Google (через твой GoogleAuthService)
  Future<UserCredential> signInWithGoogle() {
    return GoogleAuthService.instance.signInWithGoogle();
  }

  // 🚪 Выход (через GoogleAuthService, он же дергает _auth.signOut)
  Future<void> signOut() async {
    await GoogleAuthService.instance.signOut();
  }
}
