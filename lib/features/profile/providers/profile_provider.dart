import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/user_repository.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

final userProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(uid);
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return null;
  }
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(user.uid);
});
