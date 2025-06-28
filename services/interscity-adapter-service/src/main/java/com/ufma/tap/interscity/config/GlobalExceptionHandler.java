// Caminho: services/interscity-adapter-service/src/main/java/com/ufma/tap/interscity/config/GlobalExceptionHandler.java
package com.ufma.tap.interscity.config;

import com.ufma.tap.interscity.dto.Response; // <<<< GARANTA ESTE IMPORT
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.client.HttpClientErrorException; // Import para erros de cliente HTTP (4xx)
import org.springframework.web.client.HttpServerErrorException; // Import para erros de servidor HTTP (5xx)
import org.springframework.web.client.ResourceAccessException; // Import para erros de conexão (timeout, host desconhecido)

import java.util.stream.Collectors;

@ControllerAdvice
public class GlobalExceptionHandler {

    // Se houver DTOs com validação no futuro
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Response<Void>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        String errors = ex.getBindingResult()
                .getAllErrors()
                .stream()
                .map(error -> error.getDefaultMessage())
                .collect(Collectors.joining("; "));
        Response<Void> errorResponse = new Response<>("Validation failed: " + errors, 1400, null);
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    // Erros 4xx da chamada para InterSCity
    @ExceptionHandler(HttpClientErrorException.class)
    public ResponseEntity<Response<Void>> handleHttpClientErrorException(HttpClientErrorException ex) {
        HttpStatus status = (HttpStatus) ex.getStatusCode();
        Response<Void> errorResponse = new Response<>("InterSCity API Client Error: " + ex.getMessage(), status.value(), null);
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, status);
    }

    // Erros 5xx da chamada para InterSCity
    @ExceptionHandler(HttpServerErrorException.class)
    public ResponseEntity<Response<Void>> handleHttpServerErrorException(HttpServerErrorException ex) {
        HttpStatus status = (HttpStatus) ex.getStatusCode();
        Response<Void> errorResponse = new Response<>("InterSCity API Server Error: " + ex.getMessage(), status.value(), null);
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, status);
    }

    // Erros de conexão (host desconhecido, timeout) para InterSCity API
    @ExceptionHandler(ResourceAccessException.class)
    public ResponseEntity<Response<Void>> handleResourceAccessException(ResourceAccessException ex) {
        Response<Void> errorResponse = new Response<>("InterSCity API Connection Error: " + ex.getMessage(), 1502, null); // 1502 para Connection Error
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.SERVICE_UNAVAILABLE); // 503 Service Unavailable
    }


    // Catch-all para outras exceções não tratadas especificamente
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Response<Void>> handleGenericException(Exception ex) {
        Response<Void> errorResponse = new Response<>("An unexpected error occurred: " + ex.getMessage(), 1500, null);
        errorResponse.setStatus("ERROR");
        ex.printStackTrace();
        return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}