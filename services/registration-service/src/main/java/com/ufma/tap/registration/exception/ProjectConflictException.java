// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/exception/ProjectConflictException.java
package com.ufma.tap.registration.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT) // Define o código de status HTTP quando esta exceção é lançada
public class ProjectConflictException extends RuntimeException {
    public ProjectConflictException(String message) {
        super(message);
    }
}