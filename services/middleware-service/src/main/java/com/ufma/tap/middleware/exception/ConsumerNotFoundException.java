// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/exception/ConsumerNotFoundException.java
package com.ufma.tap.middleware.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ConsumerNotFoundException extends RuntimeException {
    public ConsumerNotFoundException(String message) {
        super(message);
    }
}