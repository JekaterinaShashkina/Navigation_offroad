import 'package:offroad_nav/core/result.dart';
import 'package:offroad_nav/features/auth/domain/entities/auth_user.dart';

abstract class IAuthRepository {
  /// Стрим авторизованного пользователя (или null, если разлогинен)
  Stream<AuthUser?> authStateChanges();

  /// Текущий пользователь (если залогинен)
  AuthUser? get currentUser;

  /// Логин по email/паролю
  Future<Result<AuthUser>> signInWithEmail(String email, String password);

  /// Регистрация по email/паролю
  Future<Result<AuthUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Сброс пароля
  Future<Result<void>> sendPasswordReset(String email);

  /// Логин через Google
  Future<Result<AuthUser>> signInWithGoogle();

  /// Выход
  Future<Result<void>> signOut();
}
