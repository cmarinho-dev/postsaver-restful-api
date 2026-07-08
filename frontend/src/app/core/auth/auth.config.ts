import { AuthConfig } from 'angular-oauth2-oidc';
import { environment } from '../../../environments/environment';

export const authConfig: AuthConfig = {
  issuer: environment.oauthIssuer,
  redirectUri: window.location.origin + '/callback',
  postLogoutRedirectUri: window.location.origin + '/login',
  clientId: environment.oauthClientId,
  responseType: 'code',
  scope: 'openid profile',
  useRefreshTokens: true,
  showDebugInformation: !environment.production,
  requireHttps: environment.production,
};
