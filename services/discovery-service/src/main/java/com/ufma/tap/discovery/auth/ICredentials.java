// Caminho: services/discoveru-service/src/main/java/com/ufma/tap/discovery/auth/ICredentials.java
package com.ufma.tap.discovery.auth;

// Pode ser uma interface vazia ou definir um contrato para ter username/password
public interface ICredentials {
    String getUsername();
    String getPassword();
}