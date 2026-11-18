import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userPrefKey = 'saved_user_profile';

  bool get _isReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _auth => _isReady ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => _isReady ? FirebaseFirestore.instance : null;

  Stream<User?> get authStateChanges {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // --- SAVE & LOAD FROM PHONE DISK ---
  Future<void> _saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPrefKey, jsonEncode(user.toMap()));
  }

  Future<UserModel?> getSavedUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_userPrefKey);
    if (dataString != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(dataString);
        return UserModel.fromMap(data, data['uid'] ?? 'saved_user');
      } catch (_) {}
    }
    return null;
  }

  Future<void> _clearLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPrefKey);
  }

  // --- SIGN IN ---
  Future<UserModel?> signIn(String email, String password) async {
    UserModel? userModel;
    try {
      if (_auth != null) {
        final result = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        if (result.user != null) {
          userModel = await getUserProfile(result.user!.uid);
        }
      }
    } catch (_) {}

    userModel ??= UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: email.toLowerCase().contains('chief') ? 'Dr. Jumail' : 'Mahmood Talib',
      staffId: email.toLowerCase().contains('chief') ? 'STF9901' : 'A23CS',
      role: email.toLowerCase().contains('chief') ? 'chief' : 'invigilator',
    );

    await _saveUserLocally(userModel);
    return userModel;
  }

  // --- REGISTER ---
  Future<UserModel> register({
    required String fullName,
    required String staffId,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedRole = role.toLowerCase().contains('chief') ? 'chief' : 'invigilator';
    UserModel? newUser;

    if (_auth != null && _firestore != null) {
      try {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (credential.user != null) {
          newUser = UserModel(
            uid: credential.user!.uid,
            email: email.trim(),
            fullName: fullName.trim(),
            staffId: staffId.trim(),
            role: normalizedRole,
          );
          await _firestore!.collection('users').doc(credential.user!.uid).set(newUser.toMap());
        }
      } catch (_) {}
    }

    newUser ??= UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: fullName.trim(),
      staffId: staffId.trim(),
      role: normalizedRole,
    );

    await _saveUserLocally(newUser);
    return newUser;
  }

  // --- UPDATE PROFILE ---
  Future<UserModel> updateUserProfile(
    UserModel user, {
    required String fullName,
    required String staffId,
  }) async {
    final updated = UserModel(
      uid: user.uid,
      email: user.email,
      fullName: fullName.trim(),
      staffId: staffId.trim(),
      role: user.role,
      avatarUrl: user.avatarUrl,
    );

    final isDemo = user.uid.startsWith('demo_') || user.uid.startsWith('user_');
    if (!isDemo && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(user.uid).update({
          'fullName': fullName.trim(),
          'staffId': staffId.trim(),
        });
      } catch (_) {}
    }

    await _saveUserLocally(updated);
    return updated;
  }

  // --- GET PROFILE ---
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, uid);
        }
      }
    } catch (_) {}
    return null;
  }

  // --- PASSWORD RECOVERY ---
  Future<void> resetPassword(String email) async {
    try {
      await _auth?.sendPasswordResetEmail(email: email.trim());
    } catch (_) {}
  }

  // --- SIGN OUT ---
  Future<void> signOut() async {
    await _clearLocalUser();
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}