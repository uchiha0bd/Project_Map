import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isInitialized = false;
  bool _isEmailVerified = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isInitialized => _isInitialized;
  bool get isEmailVerified => _isEmailVerified;
  String? get errorMessage => _errorMessage;

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Your password is too weak.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    if (error is FirebaseException) {
      return error.message ?? 'A Firebase error occurred.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  // Restore an existing Firebase session when the app starts.
  Future<void> initializeSession() async {
    try {
      final firebaseUser = _authService.currentUser;

      if (firebaseUser != null) {
        _isEmailVerified = await _authService.reloadEmailVerification();

        final refreshedUser = _authService.currentUser;

        if (refreshedUser != null) {
          _currentUser = await _authService.getUserProfile(refreshedUser.uid);
        }
      } else {
        _currentUser = null;
        _isEmailVerified = false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    }

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email, password);
      _isEmailVerified = await _authService.reloadEmailVerification();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String staffId,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        fullName: fullName,
        staffId: staffId,
        email: email,
        password: password,
        role: role,
      );

      _isEmailVerified = false;

      try {
        await _authService.sendEmailVerification();
      } catch (e) {
        _errorMessage = _getErrorMessage(e);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check whether the user's email has been verified.
  Future<bool> checkEmailVerification() async {
    try {
      _isEmailVerified = await _authService.reloadEmailVerification();
      notifyListeners();
      return _isEmailVerified;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Resend the email verification link.
  Future<bool> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String staffId,
  }) async {
    final user = _currentUser;
    if (user == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateUserProfile(
        user,
        fullName: fullName,
        staffId: staffId,
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _isEmailVerified = false;
    notifyListeners();
  }
}
