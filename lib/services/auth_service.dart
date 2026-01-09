import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';

  // Mock user database (in real app this would be Firebase/backend)
  static final Map<String, String> _users = {
    'test@test.com': '123456',
  };

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<Map<String, String>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyUserEmail) ?? '',
      'name': prefs.getString(_keyUserName) ?? 'Гость',
      'phone': prefs.getString(_keyUserPhone) ?? '',
    };
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if user exists and password matches
      if (_users.containsKey(email) && _users[email] == password) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserEmail, email);

        // Get name from email (before @)
        final name = email.split('@')[0];
        await prefs.setString(_keyUserName, name);

        debugPrint("Login successful: $email");
        return AuthResult(success: true, message: 'Вход выполнен успешно');
      } else {
        debugPrint("Login failed: invalid credentials");
        return AuthResult(success: false, message: 'Неверный email или пароль');
      }
    } catch (e) {
      debugPrint("Login error: $e");
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
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if user already exists
      if (_users.containsKey(email)) {
        debugPrint("Registration failed: user already exists");
        return AuthResult(success: false, message: 'Пользователь с таким email уже существует');
      }

      // Validate email
      if (!email.contains('@') || !email.contains('.')) {
        return AuthResult(success: false, message: 'Некорректный email');
      }

      // Validate password
      if (password.length < 6) {
        return AuthResult(success: false, message: 'Пароль должен быть минимум 6 символов');
      }

      // Add user to mock database
      _users[email] = password;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserName, name);
      if (phone != null) {
        await prefs.setString(_keyUserPhone, phone);
      }

      debugPrint("Registration successful: $email");
      return AuthResult(success: true, message: 'Регистрация выполнена успешно');
    } catch (e) {
      debugPrint("Registration error: $e");
      return AuthResult(success: false, message: 'Ошибка регистрации');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      // Don't clear user data, just mark as logged out
      debugPrint("Logout successful");
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (name != null) {
        await prefs.setString(_keyUserName, name);
      }

      if (phone != null) {
        await prefs.setString(_keyUserPhone, phone);
      }

      debugPrint("Profile updated");
      return true;
    } catch (e) {
      debugPrint("Profile update error: $e");
      return false;
    }
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}
