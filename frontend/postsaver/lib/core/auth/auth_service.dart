import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/environment.dart';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;

  Future<void> init() async {
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (_refreshToken != null) {
      await refresh();
    }
  }

  Future<void> login() async {
    final env = Environment.current;

    final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        'postsaver-mobile',
        env.redirectUri,
        issuer: env.issuer,
        scopes: ['openid', 'profile'],
      ),
    );

    if (result != null) {
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
    }
  }

  Future<void> refresh() async {
    if (_refreshToken == null) return;

    final env = Environment.current;

    final TokenResponse? result = await _appAuth.token(
      TokenRequest(
        'postsaver-mobile',
        env.redirectUri,
        issuer: env.issuer,
        refreshToken: _refreshToken,
        scopes: ['openid', 'profile'],
      ),
    );

    if (result != null) {
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
    } else {
      await logout();
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'refresh_token');
  }
}
