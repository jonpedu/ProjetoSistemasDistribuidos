// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/exception/BrokerStrategyIncompatibleException.java
package com.ufma.tap.middleware.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST) // 400 Bad Request
public class BrokerStrategyIncompatibleException extends RuntimeException {
    public BrokerStrategyIncompatibleException(String message) {
        super(message);
    }
}