import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Слушаем изменения состояния авторизации
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<Map<String, String>> getCurrentUser() async {
    if (currentUser == null) {
      return {
        'email': '',
        'name': 'Гость',
        'phone': '',
      };
    }

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      final data = doc.data();

      return {
        'email': currentUser!.email ?? '',
        'name': data?['name'] ?? currentUser!.displayName ?? 'Гость',
        'phone': data?['phone'] ?? '',
      };
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return {
        'email': currentUser!.email ?? '',
        'name': currentUser!.displayName ?? 'Гость',
        'phone': '',
      };
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("✅ Login successful: $email");
      return AuthResult(success: true, message: 'Вход выполнен успешно');
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Login failed: ${e.code}");
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      debugPrint("❌ Login error: $e");
      return AuthResult(success: false, message: 'Ошибка входа');
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Создаем пользователя
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ждем немного чтобы Firebase обновился
      await Future.delayed(const Duration(milliseconds: 500));

      // Получаем текущего пользователя
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Пользователь не создан');
      }

      // Сохраняем информацию в Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Registration successful: $email");
      notifyListeners();
      return AuthResult(success: true, message: 'Регистрация выполнена успешно');
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Registration failed: ${e.code}");
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      debugPrint("❌ Registration error: $e");
      return AuthResult(success: false, message: 'Ошибка регистрации');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint("✅ Logout successful");
    } catch (e) {
      debugPrint("❌ Logout error: $e");
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      if (currentUser == null) return false;

      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(currentUser!.uid).update(updates);
      }

      debugPrint("✅ Profile updated");
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Profile update error: $e");
      return false;
    }
  }

  // Сброс пароля
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true, message: 'Письмо для сброса пароля отправлено на email');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Ошибка сброса пароля');
    }
  }

  // Получение понятных сообщений об ошибках
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Пароль слишком простой';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение';
      default:
        return 'Ошибка авторизации: ${e.message}';
    }
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}
