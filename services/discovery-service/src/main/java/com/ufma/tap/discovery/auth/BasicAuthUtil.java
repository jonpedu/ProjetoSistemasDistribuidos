// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/auth/BasicAuthUtil.java
package com.ufma.tap.discovery.auth;

import org.springframework.stereotype.Component;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

@Component
public class BasicAuthUtil {

    public String[] decodeBasicAuth(String basicAuthHeader) {
        if (basicAuthHeader != null && basicAuthHeader.startsWith("Basic ")) {
            String base64Credentials = basicAuthHeader.substring("Basic ".length()).trim();
            byte[] decodedBytes = Base64.getDecoder().decode(base64Credentials);
            String credentials = new String(decodedBytes, StandardCharsets.UTF_8);
            return credentials.split(":", 2); // username:password
        }
        return null;
    }
}