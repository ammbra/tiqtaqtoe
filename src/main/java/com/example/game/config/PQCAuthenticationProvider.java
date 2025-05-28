package com.example.game.config;

import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import javax.crypto.KEM;
import javax.crypto.SecretKey;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.List;

public class PQCAuthenticationProvider implements AuthenticationProvider {

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("ML-KEM");
            KeyPair keyPair = keyPairGenerator.generateKeyPair();

            KEM kem = KEM.getInstance("ML-KEM");
            KEM.Encapsulator encapsulator = kem.newEncapsulator(keyPair.getPublic());
            KEM.Encapsulated encapsulated = encapsulator.encapsulate();

            SecretKey sharedKey = encapsulated.key();

            return new UsernamePasswordAuthenticationToken(
                authentication.getName(),
                sharedKey,
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
            );
        } catch (Exception e) {
            throw new AuthenticationServiceException("PQC Authentication failed", e);
        }
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
