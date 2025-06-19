// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/exception/InvalidCredentialsException.java
package com.ufma.tap.discovery.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.UNAUTHORIZED) // 401 Unauthorized
public class InvalidCredentialsException extends RuntimeException {
    public InvalidCredentialsException(String message) {
        super(message);
    }
}