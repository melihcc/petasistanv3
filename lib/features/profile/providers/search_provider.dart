import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

import 'profile_provider.dart'; // To access userRepositoryProvider

final userSearchProvider =
    AsyncNotifierProvider.autoDispose<UserSearchNotifier, List<UserModel>>(
      UserSearchNotifier.new,
    );

class UserSearchNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    return [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();

    // Using AsyncValue.guard to handle errors automatically
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      return repository.searchUsers(query);
    });
  }
}
