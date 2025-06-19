// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/config/GlobalExceptionHandler.java
package com.ufma.tap.discovery.config;

import com.ufma.tap.discovery.dto.Response;
import com.ufma.tap.discovery.exception.ReceiverNotFoundException;
import com.ufma.tap.discovery.exception.InvalidCredentialsException; // Se copiou a exceção
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.stream.Collectors;

@ControllerAdvice
public class GlobalExceptionHandler {

    // Exceções de JWT/Autenticação
    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<Response<Void>> handleInvalidCredentials(InvalidCredentialsException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1402, null); // 1402 para InvalidCredentials
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.UNAUTHORIZED);
    }

    // Exceções de Não Encontrado
    @ExceptionHandler(ReceiverNotFoundException.class)
    public ResponseEntity<Response<Void>> handleReceiverNotFound(ReceiverNotFoundException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1404, null); // 1404 para Not Found
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    // Tratamento para erros de validação de DTOs (ex: @NotBlank, @Size)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Response<Void>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        String errors = ex.getBindingResult()
                .getAllErrors()
                .stream()
                .map(error -> error.getDefaultMessage())
                .collect(Collectors.joining("; "));
        Response<Void> errorResponse = new Response<>("Validation failed: " + errors, 1400, null); // 1400 para BadRequest
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    // Catch-all para outras exceções não tratadas especificamente
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Response<Void>> handleGenericException(Exception ex) {
        Response<Void> errorResponse = new Response<>("An unexpected error occurred: " + ex.getMessage(), 1500, null); // 1500 genérico
        errorResponse.setStatus("ERROR");
        ex.printStackTrace();
        return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}