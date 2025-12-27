import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/search_provider.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();

  void _onSearchChanged(String query) {
    // Deboucing could be added here, but for now we just trigger search
    ref.read(userSearchProvider.notifier).search(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(userSearchProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by username...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _onSearchChanged,
        ),
      ),
      body: searchResultsAsync.when(
        data: (users) {
          if (users.isEmpty) {
            if (_searchController.text.isNotEmpty) {
              return const Center(child: Text('No users found.'));
            }
            return const Center(child: Text('Type a username to search.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              // Don't show myself in search results
              if (user.uid == currentUser?.uid) return const SizedBox.shrink();

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.displayName),
                subtitle: Text('@${user.username}'),
                onTap: () {
                  // Navigate to chat with this user
                  context.push('/chat/new?otherUid=${user.uid}');
                  // Note: 'new' is a placeholder ID. The ChatScreen logic
                  // or the Repository logic in 'sendMessage' handles generating the ID
                  // deterministicly based on UIDs.
                  // Howerver, my ChatScreen takes `conversationId`.
                  // So I need a way to get the conversation ID *before* navigating OR
                  // Update ChatScreen to accept otherUid and calculate ID itself.

                  // For simplicity:
                  // 1. Calculate deterministic ID here or use a helper.
                  // 2. Navigate to /chat/<generatedID>?otherUid=<uid>

                  final uid1 = currentUser!.uid;
                  final uid2 = user.uid;
                  final conversationId =
                      uid1.compareTo(uid2) < 0
                          ? '${uid1}_$uid2'
                          : '${uid2}_$uid1';

                  context.push('/chat/$conversationId?otherUid=${user.uid}');
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
