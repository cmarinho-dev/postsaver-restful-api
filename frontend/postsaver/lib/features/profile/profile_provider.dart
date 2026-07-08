import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/user_api.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user.dart';

class ProfileState {
  final User? user;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Dio _dio;
  final Ref _ref;

  ProfileNotifier(this._dio, this._ref) : super(const ProfileState());

  Future<void> loadUser() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await getMe(dio: _dio);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<User?> updateUser(UserRequest request) async {
    state = state.copyWith(clearError: true);

    try {
      final user = await updateMe(dio: _dio, user: request);
      state = state.copyWith(user: user);
      return user;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> deleteUser() async {
    state = state.copyWith(clearError: true);

    try {
      await deleteMe(dio: _dio);
      await _ref.read(authStateProvider.notifier).logout();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final dio = ref.watch(apiClientProvider);
  final notifier = ProfileNotifier(dio, ref);
  notifier.loadUser();
  return notifier;
});
