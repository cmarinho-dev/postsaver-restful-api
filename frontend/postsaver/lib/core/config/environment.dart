import 'package:flutter/foundation.dart';

class Environment {
  const Environment._({
    required this.issuer,
    required this.apiBase,
    required this.redirectUri,
  });

  // O backend anuncia http://localhost:8080 como issuer no discovery
  // document, então o app precisa acessá-lo pelo mesmo host. No Android,
  // mapeie a porta com: adb reverse tcp:8080 tcp:8080
  static const _devIssuer = 'http://localhost:8080';
  // Deve bater com o nome do serviço no render.yaml (APP_OAUTH_ISSUER).
  static const _prodIssuer = 'https://postsaver-api.onrender.com';

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

  /// AppAuth bloqueia issuers http:// por padrão; liberado apenas para
  /// o backend local de desenvolvimento.
  bool get allowInsecureConnections => issuer.startsWith('http://');

  static Environment get current => kDebugMode ? dev : prod;
}
