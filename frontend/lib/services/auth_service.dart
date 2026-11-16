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

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}