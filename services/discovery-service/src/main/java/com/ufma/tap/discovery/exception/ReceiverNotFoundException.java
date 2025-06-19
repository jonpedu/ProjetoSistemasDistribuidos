// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/exception/ReceiverNotFoundException.java
package com.ufma.tap.discovery.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ReceiverNotFoundException extends RuntimeException {
    public ReceiverNotFoundException(String message) {
        super(message);
    }
}