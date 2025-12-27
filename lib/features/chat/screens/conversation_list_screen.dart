import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../../profile/providers/profile_provider.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);
    final currentUser = ref.read(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/search-users');
        },
        child: const Icon(Icons.person_add),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              // Identify the other participant
              final otherUid = conversation.participants.firstWhere(
                (uid) => uid != currentUser?.uid,
                orElse: () => '',
              );

              return Consumer(
                builder: (context, ref, child) {
                  // Fetch other user's profile for name/avatar
                  final otherUserProfileAsync = ref.watch(
                    userProfileProvider(otherUid),
                  );

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: otherUserProfileAsync.maybeWhen(
                      data: (user) => Text(user?.displayName ?? 'Unknown User'),
                      orElse: () => const Text('Loading...'),
                    ),
                    subtitle: Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            conversation.lastSenderUid != currentUser?.uid
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      DateFormat.Hm().format(conversation.lastMessageAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      context.push(
                        '/chat/${conversation.id}?otherUid=$otherUid',
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
