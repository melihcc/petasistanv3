import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/ble/screens/ble_scan_screen.dart';
import '../features/chat/screens/conversation_list_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/profile/screens/user_search_screen.dart';
import '../features/ble/screens/ble_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authAsync.asData?.value != null;

      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/ble-scan',
        builder: (context, state) => const BleScanScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ConversationListScreen(),
      ),
      GoRoute(
        path: '/search-users',
        builder: (context, state) => const UserSearchScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final otherUid = state.uri.queryParameters['otherUid'] ?? '';
          return ChatScreen(conversationId: conversationId, otherUid: otherUid);
        },
      ),
      GoRoute(
        path: '/ble/:deviceId',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId']!;
          return BleDetailScreen(deviceId: deviceId);
        },
      ),
    ],
  );
});
