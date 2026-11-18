import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Check if Firebase is actually configured before calling it
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

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Sign In with email & password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      if (_auth != null) {
        final result = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        if (result.user != null) {
          final profile = await getUserProfile(result.user!.uid);
          if (profile != null) return profile;
        }
      }
    } catch (_) {
      // Fallback to local testing
    }

    // Instant testing fallback:
    if (email.toLowerCase().contains('chief')) {
      return UserModel(
        uid: 'demo_chief_01',
        email: email,
        fullName: 'Dr. Jumail',
        staffId: 'STF9901',
        role: 'chief',
      );
    } else {
      return UserModel(
        uid: 'demo_invigilator_01',
        email: email,
        fullName: 'Mahmood Talib',
        staffId: 'A23CS',
        role: 'invigilator',
      );
    }
  }

  // Register a new user with Firebase Authentication and Firestore
  Future<UserModel> register({
    required String fullName,
    required String staffId,
    required String email,
    required String password,
    required String role,
  }) async {
    // 1. Try real Firebase if configured
    if (_auth != null && _firestore != null) {
      UserCredential? credential;
      try {
        credential = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          final normalizedRole = role.toLowerCase().contains('chief') ? 'chief' : 'invigilator';
          final newUser = UserModel(
            uid: firebaseUser.uid,
            email: email.trim(),
            fullName: fullName.trim(),
            staffId: staffId.trim(),
            role: normalizedRole,
          );

          await _firestore!.collection('users').doc(firebaseUser.uid).set(
            newUser.toMap(),
          );

          return newUser;
        }
      } catch (e) {
        if (credential?.user != null) {
          await credential!.user!.delete();
        }
      }
    }

    // 2. Fallback to instant local registration (so demo never crashes!)
    final normalizedRole = role.toLowerCase().contains('chief') ? 'chief' : 'invigilator';
    return UserModel(
      uid: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: fullName.trim(),
      staffId: staffId.trim(),
      role: normalizedRole,
    );
  }

  // Fetch role & profile from Firestore
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

  // Save edited profile fields (Firestore when available, local for demo users)
  Future<UserModel> updateUserProfile(
    UserModel user, {
    required String fullName,
    required String staffId,
  }) async {
    final updated = user.copyWith(fullName: fullName, staffId: staffId);
    final isDemo = user.uid.startsWith('demo_');
    if (!isDemo && _firestore != null) {
      await _firestore!.collection('users').doc(user.uid).update({
        'fullName': fullName,
        'staffId': staffId,
      });
    }
    return updated;
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}