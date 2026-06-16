import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

// 1. Модель пользователя
class User {
  final String id;
  final String nickname;
  final String email;
  final int idRole;
  final String? avatarUrl;

  User({
    required this.id,
    required this.nickname,
    required this.email,
    required this.idRole,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      idRole: json['id_role'] as int,
      avatarUrl: json['avatar_url'] is String ? json['avatar_url'] as String : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'email': email,
      'id_role': idRole,
      'avatar_url': avatarUrl,
    };
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;
  final AuthService _authService = AuthService();

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;

  AuthProvider() {
    _initAuthListener();
    loadSession();
  }

  // Слушатель изменений состояния аутентификации Supabase
  void _initAuthListener() {
    _authService.supabaseClient.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

       debugPrint('Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        final userData = session.user.userMetadata ?? {};
        _currentUser = User(
          id: session.user.id,
          email: session.user.email!,
          nickname: userData['nickname'] ?? '',
          idRole: userData['id_role'] ?? 2,
          avatarUrl: userData['avatar_url'],
        );
        _isAuthenticated = true;
        _saveSession(_currentUser!);
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isAuthenticated = false;
        _clearSession();
        notifyListeners();
      }
    });
  }

  // Загрузка сохраненной сессии при старте
  Future<void> loadSession() async {
    final session = _authService.supabaseClient.auth.currentSession;

    if (session != null) {
      final userData = session.user.userMetadata ?? {};
      _currentUser = User(
        id: session.user.id,
        email: session.user.email!,
        nickname: userData['nickname'] ?? '',
        idRole: userData['id_role'] ?? 2,
        avatarUrl: userData['avatar_url'],
      );
      _isAuthenticated = true;
      await _saveSession(_currentUser!);
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
      } catch (e) {
        _isAuthenticated = false;
        _currentUser = null;
        await prefs.remove('user_data');
      }
    }
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // Выход из системы
  Future<void> logout() async {
    await _authService.supabaseClient.auth.signOut();
    _currentUser = null;
    _isAuthenticated = false;
    _clearSession();
    notifyListeners();
  }

  // OTP flows
  Future<bool> sendOTP(String email, {required bool isRegistration}) async {
    return await _authService.sendOTP(email, isRegistration: isRegistration);
  }

  Future<bool> loginWithOTP(String email, String otp) async {
    final userData = await _authService.loginWithOTP(email, otp);
    if (userData != null) {
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      await _saveSession(_currentUser!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> registerWithOTP(String nickname, String email, String otp) async {
    final userData = await _authService.registerWithOTP(nickname, email, otp);
    if (userData != null) {
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      await _saveSession(_currentUser!);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ВАЖНО: Метод loginUser создает сессию! Не использовать для проверки пароля до OTP!
  // Использовать AuthService.verifyPassword для проверки пароля без создания сессии
  Future<bool> login(String email, String password) async {
    // Этот метод НЕ должен использоваться - он создает сессию и обходит OTP
    debugPrint('WARNING: login() called - this creates a session! Use verifyPassword() instead');
    final userData = await _authService.loginUser(email, password);
    return userData != null;
  }

  // Логика регистрации (только создание аккаунта, без установки сессии)
  Future<bool> register(String nickname, String email, String password) async {
    final userData = await _authService.registerUser(nickname, email, password);
    return userData != null;
  }

  Future<void> clearAllCaches() async {
    await AuthService.clearCaches();
  }
}
