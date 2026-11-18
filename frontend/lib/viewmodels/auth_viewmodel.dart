import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSaving => _isLoading; // <-- Satisfies Rifqi's profile_view.dart
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    checkSavedSession();
  }

  // Check saved session from phone disk on launch
  Future<void> checkSavedSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getSavedUserLocally();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String staffId,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        fullName: fullName,
        staffId: staffId,
        email: email,
        password: password,
        role: role,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Update Profile
  Future<bool> updateUserProfile({
    required String fullName,
    required String staffId,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _authService.updateUserProfile(
        _currentUser!,
        fullName: fullName,
        staffId: staffId,
      );
      _currentUser = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Alias for Rifqi's profile_view.dart
  Future<bool> updateProfile({
    String? fullName,
    String? staffId,
  }) {
    return updateUserProfile(
      fullName: fullName ?? _currentUser?.fullName ?? '',
      staffId: staffId ?? _currentUser?.staffId ?? '',
    );
  }

  // Logout
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}