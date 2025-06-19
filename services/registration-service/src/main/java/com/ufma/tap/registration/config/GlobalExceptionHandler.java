// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/config/GlobalExceptionHandler.java
package com.ufma.tap.registration.config;

import com.ufma.tap.registration.dto.Response;
import com.ufma.tap.registration.exception.InvalidTokenException;
import com.ufma.tap.registration.exception.ProjectConflictException;
import com.ufma.tap.registration.exception.ProjectNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.stream.Collectors;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ProjectConflictException.class)
    public ResponseEntity<Response<Void>> handleProjectConflict(ProjectConflictException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1409, null); // Código de erro 1409 para Conflito
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.CONFLICT);
    }

    @ExceptionHandler(ProjectNotFoundException.class)
    public ResponseEntity<Response<Void>> handleProjectNotFound(ProjectNotFoundException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1404, null); // Código de erro 1404 para Não Encontrado
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(InvalidTokenException.class)
    public ResponseEntity<Response<Void>> handleInvalidToken(InvalidTokenException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1401, null); // Código de erro 1401 para Token Inválido
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.UNAUTHORIZED);
    }

    // Tratamento para erros de validação de DTOs (ex: @NotBlank, @Size)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Response<Void>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        String errors = ex.getBindingResult()
                .getAllErrors()
                .stream()
                .map(error -> error.getDefaultMessage())
                .collect(Collectors.joining("; "));
        Response<Void> errorResponse = new Response<>("Validation failed: " + errors, 1400, null); // Código de erro 1400 para BadRequest
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    // Catch-all para outras exceções não tratadas especificamente
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Response<Void>> handleGenericException(Exception ex) {
        Response<Void> errorResponse = new Response<>("An unexpected error occurred: " + ex.getMessage(), 1500, null); // Código genérico de erro 1500
        errorResponse.setStatus("ERROR");
        ex.printStackTrace(); // Log da stack trace para depuração
        return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}