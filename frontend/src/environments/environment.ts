// Default values, used as-is by `ng serve` (development configuration).
// Must match app.oauth.issuer in application-dev.yaml exactly -- the OIDC
// client validates the token's "iss" claim against this value.
export const environment = {
  production: false,
  apiBase: '/api/v1',
  oauthIssuer: 'http://localhost:8080',
  oauthClientId: 'postsaver-web',
};
