// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/config/GlobalExceptionHandler.java
package com.ufma.tap.middleware.config;

import com.ufma.tap.middleware.dto.Response;
import com.ufma.tap.middleware.exception.*; // Importa todas as suas exceções personalizadas
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

    // Exceções de Conflito de Usuário/Recurso
    @ExceptionHandler(UserConflictException.class)
    public ResponseEntity<Response<Void>> handleUserConflict(UserConflictException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1410, null); // 1410 para UserConflict
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.CONFLICT);
    }

    // Exceções de Não Encontrado
    @ExceptionHandler(ProducerNotFoundException.class)
    public ResponseEntity<Response<Void>> handleProducerNotFound(ProducerNotFoundException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1404, null); // 1404 para UserNotFound (Producer)
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(ConsumerNotFoundException.class)
    public ResponseEntity<Response<Void>> handleConsumerNotFound(ConsumerNotFoundException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1404, null); // 1404 para UserNotFound (Consumer)
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(MessageNotFoundException.class)
    public ResponseEntity<Response<Void>> handleMessageNotFound(MessageNotFoundException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1407, null); // 1407 para MessageNotFound
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.NOT_FOUND);
    }

    // Exceções de Broker/Estratégia
    @ExceptionHandler(BrokerNotSupportedException.class)
    public ResponseEntity<Response<Void>> handleBrokerNotSupported(BrokerNotSupportedException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1415, null); // 1415 para BrokerNotSupported
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(BrokerStrategyIncompatibleException.class)
    public ResponseEntity<Response<Void>> handleBrokerStrategyIncompatible(BrokerStrategyIncompatibleException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1416, null); // 1416 para BrokerStrategyIncompatible
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.BAD_REQUEST);
    }

    // Exceções de Mensageria
    @ExceptionHandler(MessageSendException.class)
    public ResponseEntity<Response<Void>> handleMessageSendException(MessageSendException ex) {
        Response<Void> errorResponse = new Response<>(ex.getMessage(), 1501, null); // 1501 para CouldNotSendMessage
        errorResponse.setStatus("ERROR");
        return new ResponseEntity<>(errorResponse, HttpStatus.INTERNAL_SERVER_ERROR);
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