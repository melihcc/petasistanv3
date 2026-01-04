import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current user profile
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    // Initialize notification listener (foreground)
    ref.watch(chatNotificationListenerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Asistan Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
        data: (user) {
          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                child: const Text('Session expired – Login again'),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${user.displayName}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Email: ${user.email}'),
                const SizedBox(height: 8),
                Text('Username: ${user.username}'),
                const SizedBox(height: 24),
                const Text(
                  'More features coming here\n(Messages • Calls)',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/ble-scan'),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('BLE Scanner'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/map'),
                  icon: const Icon(Icons.map),
                  label: const Text('Maps'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
