import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._firebaseAuth, this._firestore);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  // ---------- SIGN IN ----------
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _updateLastSeen(credential.user?.uid);
  }

  // ---------- SIGN UP ----------
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final userCredential =
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User could not be created.',
      );
    }

    await _firestore.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'email': email,
        'username': username,
        'displayName': displayName,
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return userCredential;
  }

  // ---------- SIGN OUT ----------
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ---------- REAUTH ----------
  Future<void> reauthenticate({
    required String email,
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
  }

  // ---------- UPDATE PASSWORD ----------
  Future<void> updatePassword({required String newPassword}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    await user.updatePassword(newPassword);
  }

  // ---------- RESET PASSWORD ----------
  Future<void> resetPassword({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // ---------- HELPERS ----------
  Future<void> _updateLastSeen(String? uid) async {
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
