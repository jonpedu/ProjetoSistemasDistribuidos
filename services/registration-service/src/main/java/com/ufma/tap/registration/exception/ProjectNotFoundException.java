// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/exception/ProjectNotFoundException.java
package com.ufma.tap.registration.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ProjectNotFoundException extends RuntimeException {
    public ProjectNotFoundException(String message) {
        super(message);
    }
}