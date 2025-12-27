import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state needed
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).signOut();
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    try {
      final credential = await ref
          .read(authServiceProvider)
          .signUp(
            email: email,
            password: password,
            username: username,
            displayName: displayName,
          );
      state = const AsyncData(null);
      return credential;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signOut(),
    );
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).resetPassword(email: email),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
