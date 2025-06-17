// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/exception/MessageSendException.java
package com.ufma.tap.middleware.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR) // 500 Internal Server Error
public class MessageSendException extends RuntimeException {
    public MessageSendException(String message) {
        super(message);
    }

    public MessageSendException(String message, Throwable cause) {
        super(message, cause);
    }
}