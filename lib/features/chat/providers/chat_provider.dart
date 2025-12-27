import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';
import '../services/notification_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

final conversationListProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getConversations(user.uid);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  conversationId,
) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(conversationId);
});

/// Controller for sending messages and other actions
final chatControllerProvider = AsyncNotifierProvider<ChatController, void>(() {
  return ChatController();
});

class ChatController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // no-op
  }

  Future<void> sendMessage({
    required String receiverUid,
    required String text,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repository = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.sendMessage(
        senderUid: user.uid,
        receiverUid: receiverUid,
        text: text,
      ),
    );
  }

  Future<void> markAsRead(String conversationId, String messageId) async {
    final repository = ref.read(chatRepositoryProvider);
    await repository.markAsRead(conversationId, messageId);
  }
}

/// Global listener for new messages to trigger local notifications
final chatNotificationListenerProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final notificationService = ref.read(notificationServiceProvider);

  // Listen to all messages in the entire database where receiverUid is me
  // Implementation Note: Requires a composite index effectively, but for collectionGroup
  // simply querying by 'receiverUid' is often enough if single-field index exists (default).
  // We filter by 'isRead' == false and 'createdAt' > now (roughly) to avoid notifying old messages on startup
  // BUT: 'createdAt' > now is tricky with snapshots.
  // Better approach: Listen to snapshots, and only notify for *added* changes that are new.

  final subscription = firestore
      .collectionGroup('messages')
      .where('receiverUid', isEqualTo: user.uid)
      .where('isRead', isEqualTo: false)
      // Limit to recent to avoid pulling entire history (optional but good for performance if possible)
      // .where('createdAt', isGreaterThan: Timestamp.now()) // This might miss messages arriving exactly at startup
      .orderBy('createdAt', descending: true)
      .limit(1) // We just need to know if a NEW one comes in
      .snapshots()
      .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            // Simple check to ensure we don't notify for old messages loaded on initial stream
            // (Compare timestamp with app start time or just rely on 'added' event for active session)
            // For a perfect solution, we'd persist 'lastNotificationTime'.
            // For this implementation, we will check if the message is very recent (e.g. within last 10 seconds)
            // to avoid flood on startup.
            final createdAt = (data?['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null &&
                DateTime.now().difference(createdAt).inSeconds < 30) {
              notificationService.showNotification(
                id: change.doc.hashCode,
                title: 'New Message',
                body: data?['text'] ?? 'You received a new message',
              );
            }
          }
        }
      });

  ref.onDispose(() {
    subscription.cancel();
  });
});
