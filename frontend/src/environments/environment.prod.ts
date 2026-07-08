// Swapped in for environment.ts by the "production" build configuration
// (see angular.json fileReplacements).
//
// Assumes the backend serves the built Angular app itself (same origin) --
// the simplest production topology and the one WebConfig/CORS defaults to.
// If frontend and backend end up on different domains, replace oauthIssuer
// with the backend's real origin (CORS for /oauth2 and /.well-known is
// already in place for that case -- see WebConfig).
export const environment = {
  production: true,
  apiBase: '/api/v1',
  oauthIssuer: window.location.origin,
  oauthClientId: 'postsaver-web',
};
