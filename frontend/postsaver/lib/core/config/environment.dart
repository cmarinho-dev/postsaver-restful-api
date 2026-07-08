import 'package:flutter/foundation.dart';

class Environment {
  const Environment._({
    required this.issuer,
    required this.apiBase,
    required this.redirectUri,
  });

  static const _devIssuer = 'http://10.0.2.2:8080';
  static const _iosSimIssuer = 'http://localhost:8080';
  static const _prodIssuer = 'https://postsaver.example.com';

  static final Environment dev = Environment._(
    issuer: _devIssuer,
    apiBase: _devIssuer,
    redirectUri: 'br.com.cmarinho.postsaver://callback',
  );

  static final Environment prod = Environment._(
    issuer: _prodIssuer,
    apiBase: _prodIssuer,
    redirectUri: 'br.com.cmarinho.postsaver://callback',
  );

  final String issuer;
  final String apiBase;
  final String redirectUri;

  static Environment get current {
    if (kDebugMode) {
      // iOS Simulator uses localhost instead of 10.0.2.2
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return Environment._(
          issuer: _iosSimIssuer,
          apiBase: _devIssuer,
          redirectUri: 'br.com.cmarinho.postsaver://callback',
        );
      }
      return dev;
    }
    return prod;
  }
}
