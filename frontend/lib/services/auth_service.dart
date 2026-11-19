import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen for Firebase login/logout changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the currently authenticated Firebase user.
  User? get currentUser => _auth.currentUser;

  // Login using Firebase Authentication.
  Future<UserModel> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = result.user;

    if (firebaseUser == null) {
      throw Exception('Login failed. No authenticated user was returned.');
    }

    final profile = await getUserProfile(firebaseUser.uid);

    if (profile == null) {
      throw Exception(
        'Your account exists, but your user profile was not found.',
      );
    }

    return profile;
  }

  // Register using Firebase Authentication and save the profile in Firestore.
  Future<UserModel> register({
    required String fullName,
    required String staffId,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedRole = role.toLowerCase();

    if (normalizedRole != 'chief' && normalizedRole != 'invigilator') {
      throw Exception('Invalid account role.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Registration failed. No user account was created.');
    }

    final newUser = UserModel(
      uid: firebaseUser.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      staffId: staffId.trim(),
      role: normalizedRole,
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(newUser.toMap());

    return newUser;
  }

  // Send an email verification link.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await user.sendEmailVerification();
  }

  // Refresh the Firebase user and check email verification status.
  Future<bool> reloadEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    return _auth.currentUser?.emailVerified ?? false;
  }

  // Retrieve a user's profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!, uid);
  }

  // Update the authenticated user's Firestore profile.
  Future<UserModel> updateUserProfile(
    UserModel user, {
    required String fullName,
    required String staffId,
  }) async {
    final updated = user.copyWith(
      fullName: fullName.trim(),
      staffId: staffId.trim(),
    );

    await _firestore.collection('users').doc(user.uid).update({
      'fullName': updated.fullName,
      'staffId': updated.staffId,
    });

    return updated;
  }

  // Logout from Firebase.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send a genuine Firebase password reset email.
  Future<bool> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    return true;
  }
}
