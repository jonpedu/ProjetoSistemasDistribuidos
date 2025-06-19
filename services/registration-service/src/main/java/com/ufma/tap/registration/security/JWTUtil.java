// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/security/JWTUtil.java
// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/security/JWTUtil.java

package com.ufma.tap.registration.security; // ou com.ufma.tap.middleware.security

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys; // Continua sendo io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JWTUtil {

    @Value("${jwt.secret}") // Chave secreta para assinatura do JWT
    private String secret;

    @Value("${jwt.expiration}") // Tempo de expiração do JWT
    private Long expiration;

   
    private Key getSigningKey() {
        
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    public String generateToken(String userId, String projectId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("projectId", projectId); // Informações adicionais no token

        
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
                .setSigningKey(getSigningKey()) // Usa a mesma chave para verificar a assinatura
                .build() // Constrói a instância do parser
                .parseClaimsJws(token) // Faz o parsing do JWS (JSON Web Signature)
                .getBody(); // Extrai os claims (corpo do JWT)
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
            // Remove o prefixo "Bearer " se estiver presente, antes de validar o token
            String cleanToken = token.startsWith("Bearer ") ? token.substring(7) : token;

            Claims claims = extractAllClaims(cleanToken);
            String projectIdInToken = claims.get("projectId", String.class);

            // Valida se o ID do projeto no token corresponde ao esperado E se o token não está expirado
            return (projectIdInToken != null && projectIdInToken.equals(expectedProjectId) && !isTokenExpired(cleanToken));
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            // Captura exceção específica para token expirado
            System.err.println("JWT Expired: " + e.getMessage());
            return false;
        } catch (io.jsonwebtoken.security.SignatureException e) {
            // Captura exceção específica para assinatura inválida (token adulterado)
            System.err.println("Invalid JWT Signature: " + e.getMessage());
            return false;
        } catch (Exception e) {
            // Captura qualquer outra exceção (formato inválido, etc.)
            System.err.println("Invalid JWT: " + e.getMessage());
            return false;
        }
    }
}