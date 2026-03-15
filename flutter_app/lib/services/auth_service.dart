/// Auth Service
/// 
/// Manages authentication state using Provider pattern.
/// Stores JWT token in SharedPreferences for persistence.
/// Exposes current user info and login/logout methods.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadStoredAuth();
  }

  /// Try to restore session from stored token
  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('jwt_token');

      if (storedToken != null) {
        _token = storedToken;
        // Verify token is still valid by fetching user info
        final response = await ApiService.getMe();
        if (response['user'] != null) {
          _currentUser = User.fromJson(response['user']);
        } else {
          // Token expired or invalid
          await _clearAuth();
        }
      }
    } catch (e) {
      await _clearAuth();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with username and password
  Future<String?> login(String username, String password) async {
    try {
      final response = await ApiService.login(username, password);

      if (response['token'] != null) {
        _token = response['token'];
        _currentUser = User.fromJson(response['user']);

        // Store token for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);

        notifyListeners();
        return null; // No error
      }

      return response['error'] ?? 'Login failed';
    } catch (e) {
      return 'Connection error. Check your network.';
    }
  }

  /// Register a new account (user role)
  Future<String?> register(String username, String email, String password) async {
    try {
      final response = await ApiService.register(username, email, password);

      if (response['token'] != null) {
        _token = response['token'];
        _currentUser = User.fromJson(response['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);

        notifyListeners();
        return null; // No error
      }

      return response['error'] ?? 'Registration failed';
    } catch (e) {
      return 'Connection error. Check your network.';
    }
  }

  /// Logout and clear stored session
  Future<void> logout() async {
    await _clearAuth();
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
