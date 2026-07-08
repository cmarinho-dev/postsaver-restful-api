package br.com.cmarinho.postsaver.security;

import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

@Component
public class CurrentUserProvider {

    public Long getUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (!(authentication instanceof JwtAuthenticationToken jwtAuthentication)) {
            throw new AuthenticationCredentialsNotFoundException("No authenticated JWT principal found.");
        }
        Jwt jwt = jwtAuthentication.getToken();
        Long uid = jwt.getClaim("uid");
        if (uid == null) {
            throw new AuthenticationCredentialsNotFoundException("JWT is missing the 'uid' claim.");
        }
        return uid;
    }
}
