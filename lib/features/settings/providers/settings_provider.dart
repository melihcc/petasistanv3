import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, void>(SettingsController.new);

class SettingsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op
  }

  /// Firestore users/{uid} -> displayName + username update eder
  Future<void> updateProfile({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);

      // ✅ HATA 3 FIX: updateUser(...) yerine updateProfile(...) kullan
      await repo.updateProfile(
        uid: uid,
        username: username,
        displayName: displayName,
      );

      // (opsiyonel) profile provider’ı refresh etmek istersen:
      // ref.invalidate(currentUserProfileProvider);
    });
  }

  /// Firebase re-auth + updatePassword
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final auth = ref.read(authServiceProvider);
      final user = auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'User is not authenticated.',
        );
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-email',
          message: 'User email is missing.',
        );
      }

      // ✅ HATA 4 FIX: password: değil currentPassword: kullanılacak
      await auth.reauthenticate(email: email, currentPassword: currentPassword);

      await auth.updatePassword(newPassword: newPassword);

      // (opsiyonel) UI tarafında formu temizlemek için state dışında bir şey gerekmez
    });
  }
}
