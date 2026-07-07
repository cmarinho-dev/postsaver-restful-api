package br.com.cmarinho.postsaver.config;

import br.com.cmarinho.postsaver.security.AppUserPrincipal;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.Resource;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.core.oidc.OidcScopes;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.config.annotation.web.configuration.OAuth2AuthorizationServerConfiguration;
import org.springframework.security.oauth2.server.authorization.settings.AuthorizationServerSettings;
import org.springframework.security.oauth2.server.authorization.settings.ClientSettings;
import org.springframework.security.oauth2.server.authorization.settings.TokenSettings;
import org.springframework.security.oauth2.server.authorization.token.JwtEncodingContext;
import org.springframework.security.oauth2.server.authorization.token.OAuth2TokenCustomizer;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Duration;
import java.util.UUID;

/**
 * Wires the app's own backend as an OAuth2/OIDC Authorization Server (co-hosted
 * with the resource server in the same JVM/deploy), issuing JWTs via the
 * Authorization Code + PKCE flow for first-party clients (web today, mobile later).
 */
@Configuration
public class AuthorizationServerConfig {

    @Bean
    @Profile("!prd")
    public JWKSource<SecurityContext> devJwkSource() {
        KeyPair keyPair = generateRsaKeyPair();
        RSAKey rsaKey = new RSAKey.Builder((RSAPublicKey) keyPair.getPublic())
                .privateKey((RSAPrivateKey) keyPair.getPrivate())
                .keyID(UUID.randomUUID().toString())
                .build();
        return new ImmutableJWKSet<>(new JWKSet(rsaKey));
    }

    @Bean
    @Profile("prd")
    public JWKSource<SecurityContext> prdJwkSource(
            @Value("${app.security.jwk.keystore-location}") Resource keystoreLocation,
            @Value("${app.security.jwk.keystore-password}") String keystorePassword,
            @Value("${app.security.jwk.key-alias}") String keyAlias) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        try (var in = keystoreLocation.getInputStream()) {
            keyStore.load(in, keystorePassword.toCharArray());
        }
        RSAPrivateKey privateKey = (RSAPrivateKey) keyStore.getKey(keyAlias, keystorePassword.toCharArray());
        Certificate certificate = keyStore.getCertificate(keyAlias);
        RSAKey rsaKey = new RSAKey.Builder((RSAPublicKey) certificate.getPublicKey())
                .privateKey(privateKey)
                .keyID(keyAlias)
                .build();
        return new ImmutableJWKSet<>(new JWKSet(rsaKey));
    }

    @Bean
    public JwtDecoder jwtDecoder(JWKSource<SecurityContext> jwkSource) {
        return OAuth2AuthorizationServerConfiguration.jwtDecoder(jwkSource);
    }

    @Bean
    public AuthorizationServerSettings authorizationServerSettings(@Value("${app.oauth.issuer}") String issuer) {
        return AuthorizationServerSettings.builder()
                .issuer(issuer)
                .build();
    }

    @Bean
    public RegisteredClientRepository registeredClientRepository(
            @Value("${app.oauth.web-redirect-uri}") String webRedirectUri,
            @Value("${app.oauth.web-post-logout-redirect-uri}") String webPostLogoutRedirectUri,
            @Value("${app.oauth.mobile-redirect-uri}") String mobileRedirectUri) {

        TokenSettings tokenSettings = TokenSettings.builder()
                .accessTokenTimeToLive(Duration.ofMinutes(15))
                .refreshTokenTimeToLive(Duration.ofDays(30))
                .reuseRefreshTokens(false)
                .build();

        ClientSettings clientSettings = ClientSettings.builder()
                .requireAuthorizationConsent(false)
                .requireProofKey(true)
                .build();

        RegisteredClient webClient = RegisteredClient.withId(UUID.randomUUID().toString())
                .clientId("postsaver-web")
                .clientAuthenticationMethod(ClientAuthenticationMethod.NONE)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .redirectUri(webRedirectUri)
                .postLogoutRedirectUri(webPostLogoutRedirectUri)
                .scope(OidcScopes.OPENID)
                .scope(OidcScopes.PROFILE)
                .clientSettings(clientSettings)
                .tokenSettings(tokenSettings)
                .build();

        // Not consumed by any client yet -- registered ahead of time so the future
        // mobile app only needs a redirect URI update, not a backend change.
        RegisteredClient mobileClient = RegisteredClient.withId(UUID.randomUUID().toString())
                .clientId("postsaver-mobile")
                .clientAuthenticationMethod(ClientAuthenticationMethod.NONE)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .redirectUri(mobileRedirectUri)
                .scope(OidcScopes.OPENID)
                .scope(OidcScopes.PROFILE)
                .clientSettings(clientSettings)
                .tokenSettings(tokenSettings)
                .build();

        return new InMemoryRegisteredClientRepository(webClient, mobileClient);
    }

    @Bean
    public OAuth2TokenCustomizer<JwtEncodingContext> jwtTokenCustomizer() {
        return context -> {
            if (context.getPrincipal().getPrincipal() instanceof AppUserPrincipal principal) {
                context.getClaims().claim("uid", principal.getId());
            }
        };
    }

    private static KeyPair generateRsaKeyPair() {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            return keyPairGenerator.generateKeyPair();
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
