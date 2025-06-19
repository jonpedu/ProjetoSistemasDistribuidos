// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/security/JWTUtil.java
package com.ufma.tap.middleware.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JWTUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    public String generateToken(String userId, String projectId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("projectId", projectId);
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(userId)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(getSigningKey())
                .compact();
    }

    public Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public String extractSubject(String token) {
        return extractAllClaims(token).getSubject();
    }

    public Date extractExpiration(String token) {
        return extractAllClaims(token).getExpiration();
    }

    public Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public Boolean validateToken(String token, String expectedProjectId) {
        try {
            String cleanToken = token.startsWith("Bearer ") ? token.substring(7) : token;
            Claims claims = extractAllClaims(cleanToken);
            String projectIdInToken = claims.get("projectId", String.class);
            return (projectIdInToken != null && projectIdInToken.equals(expectedProjectId) && !isTokenExpired(cleanToken));
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            System.err.println("JWT Expired: " + e.getMessage());
            return false;
        } catch (io.jsonwebtoken.security.SignatureException e) {
            System.err.println("Invalid JWT Signature: " + e.getMessage());
            return false;
        } catch (Exception e) {
            System.err.println("Invalid JWT: " + e.getMessage());
            return false;
        }
    }
}