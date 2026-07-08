import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_interceptor.dart';
import 'auth_service.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(AuthState.unknown);

  Future<void> init() async {
    await _authService.init();
    state = _authService.isAuthenticated
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }

  Future<void> login() async {
    await _authService.login();
    state = _authService.isAuthenticated
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.unauthenticated;
  }

  Future<void> refresh() async {
    await _authService.refresh();
    state = _authService.isAuthenticated
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});

final apiClientProvider = Provider<Dio>((ref) {
  final authService = ref.watch(authServiceProvider);
  final dio = createApiClient();
  final interceptor = AuthInterceptor(authService, dio);
  dio.interceptors.add(interceptor);
  return dio;
});
