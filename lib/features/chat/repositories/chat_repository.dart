import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  // Helper: Generate deterministic conversation ID
  String _getConversationId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Stream<List<ConversationModel>> getConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ConversationModel.fromDocument(doc))
              .toList();
        });
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromDocument(doc))
              .toList();
        });
  }

  Future<String> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String text,
  }) async {
    final conversationId = _getConversationId(senderUid, receiverUid);
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    // Use a batch to update conversation and add message atomically
    final batch = _firestore.batch();

    // 1. Set Conversation Info (upsert)
    batch.set(conversationRef, {
      'participants': [senderUid, receiverUid], // Ensure both in list
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': senderUid,
    }, SetOptions(merge: true));

    // 2. Add Message
    final messageRef = conversationRef.collection('messages').doc();
    batch.set(messageRef, {
      'senderUid': senderUid,
      'receiverUid': receiverUid, // Essential for collectionGroup queries
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 3. (Optional) Create Placeholder for Cloud Function / Notifications
    // batch.set(
    //    _firestore.collection('notification_queue').doc(),
    //    {'type': 'chat', 'target': receiverUid, 'body': text}
    // );

    await batch.commit();
    return conversationId;
  }

  Future<void> markAsRead(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }
}
