// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/auth/ICredentials.java
package com.ufma.tap.middleware.auth;

// Pode ser uma interface vazia ou definir um contrato para ter username/password
public interface ICredentials {
    String getUsername();
    String getPassword();
}