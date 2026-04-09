import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  late final fb.FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _firebaseAuth = fb.FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  /// Получить текущего пользователя
  User? get currentUser {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null) {
      return User.fromFirebase(
        fbUser.uid,
        fbUser.email ?? '',
        fbUser.displayName ?? 'Unknown',
      );
    }
    return null;
  }

  /// Поток текущего пользователя (для обновлений в реальном времени)
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser != null) {
        // Получить полные данные из Firestore
        final docSnapshot = await _firestore.collection('users').doc(fbUser.uid).get();
        if (docSnapshot.exists) {
          return User.fromMap(docSnapshot.data() ?? {});
        } else {
          return User.fromFirebase(fbUser.uid, fbUser.email ?? '', fbUser.displayName ?? '');
        }
      }
      return null;
    });
  }

  /// Регистрация нового пользователя
  Future<User> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Создать пользователя в Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user!;

      // Создать пользователя в Firestore
      final user = User.fromFirebase(
        fbUser.uid,
        email,
        username,
      );

      await _firestore.collection('users').doc(fbUser.uid).set(user.toMap());

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Вход пользователя
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user!;

      // Получить данные из Firestore
      final docSnapshot = await _firestore.collection('users').doc(fbUser.uid).get();
      if (docSnapshot.exists) {
        return User.fromMap(docSnapshot.data() ?? {});
      } else {
        return User.fromFirebase(fbUser.uid, fbUser.email ?? '', fbUser.displayName ?? '');
      }
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Выход из аккаунта
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Ошибка выхода: $e';
    }
  }

  /// Восстановление пароля
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Получить пользователя по ID
  Future<User?> getUserById(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return User.fromMap(docSnapshot.data() ?? {});
      }
      return null;
    } catch (e) {
      throw 'Ошибка получения пользователя: $e';
    }
  }

  /// Обновить профиль пользователя
  Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? photoURL,
    String? currentCharacterId,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (username != null) updates['username'] = username;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (currentCharacterId != null) updates['currentCharacterId'] = currentCharacterId;

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw 'Ошибка обновления профиля: $e';
    }
  }

  /// Проверить доступность username
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      throw 'Ошибка проверки username: $e';
    }
  }

  /// Обработка Firebase Auth ошибок
  String _handleAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-disabled':
        return 'Аккаунт отключен';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Пароль слишком простой';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'network-request-failed':
        return 'Ошибка сети';
      default:
        return 'Ошибка аутентификации: ${e.message}';
    }
  }
}

