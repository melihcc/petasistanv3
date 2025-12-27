import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'users';

  // ---------- READ ----------
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();

    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  // ---------- WATCH (ileride çok işine yarar) ----------
  Stream<UserModel?> watchUser(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
  }

  // ---------- UPDATE (SADECE profil alanları) ----------
  Future<void> updateProfile({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    await _firestore.collection(_collection).doc(uid).update({
      'username': username,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- SEARCH ----------
  Future<List<UserModel>> searchUsers(String query) async {
    // This is a basic prefix search (case-sensitive usually in Firestore)
    // Ideally, store a lowercase version field 'username_lower' for better search
    // But for now, we'll search by standard 'username' field.

    // We assume 'query' is what the user typed.
    // Firestore prefix search trick: startAt(query) and endAt(query + '\uf8ff')

    if (query.isEmpty) return [];

    final snapshot =
        await _firestore
            .collection(_collection)
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThan: '${query}z')
            .get();

    return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  }
}
