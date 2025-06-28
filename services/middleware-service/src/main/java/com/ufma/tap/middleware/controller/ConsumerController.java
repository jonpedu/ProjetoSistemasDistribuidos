// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/controller/ConsumerController.java
package com.ufma.tap.middleware.controller;

import com.ufma.tap.middleware.dto.ConsumerDto;
import com.ufma.tap.middleware.dto.MessageDto;
import com.ufma.tap.middleware.dto.Response;
import com.ufma.tap.middleware.model.Consumer;
import com.ufma.tap.middleware.service.IConsumerService;
import com.ufma.tap.middleware.dto.BrokerUpdate;
import com.ufma.tap.middleware.dto.QueueUpdate;
import com.ufma.tap.middleware.dto.StrategyUpdate;
import com.ufma.tap.middleware.dto.PersistenceUpdate;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.validation.annotation.Validated;

import java.util.List;

@RestController
@RequestMapping("/api/receivers")
@Validated
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ConsumerController {

    @Autowired
    private IConsumerService iConsumerService;

    @PostMapping
    public ResponseEntity<Response<ConsumerDto>> registerConsumer(
            @Valid @RequestBody ConsumerDto consumerDto,
            @RequestHeader("Authorization") String projectAuthToken) {
        // 1. Mude o tipo da variável de 'Consumer' para 'ConsumerDto'
        ConsumerDto registeredConsumerDto = iConsumerService.registerConsumer(consumerDto.toModel(), projectAuthToken); // LINHA CORRIGIDA

        // 2. A linha seguinte já deve usar o 'registeredConsumerDto' diretamente
        Response<ConsumerDto> apiResponse = new Response<>("Consumer registered.", HttpStatus.CREATED.value(), registeredConsumerDto);
        return new ResponseEntity<>(apiResponse, HttpStatus.CREATED);
    }

    @GetMapping("/{consumerId}")
    public ResponseEntity<Response<ConsumerDto>> getConsumer(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        ConsumerDto consumerDto = iConsumerService.getConsumer(consumerId, projectAuthToken);
        Response<ConsumerDto> apiResponse = new Response<>("Consumer info retrieved.", HttpStatus.OK.value(), consumerDto);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @DeleteMapping("/{consumerId}")
    public ResponseEntity<Response<Void>> deleteConsumer(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iConsumerService.deleteConsumer(consumerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Consumer deleted.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @GetMapping("/{consumerId}/receive")
    public SseEmitter connectConsumer(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        // Retorna SseEmitter para conexão de streaming de longa duração
        return iConsumerService.connectConsumer(consumerId, projectAuthToken);
    }

    @PostMapping("/{consumerId}/close")
    public ResponseEntity<Response<Void>> disconnectConsumer(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iConsumerService.disconnectConsumer(consumerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Consumer disconnected.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @GetMapping("/{consumerId}/messages")
    public ResponseEntity<Response<List<MessageDto>>> getMessages(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        List<MessageDto> messages = iConsumerService.getMessages(consumerId, projectAuthToken);
        Response<List<MessageDto>> apiResponse = new Response<>("Messages retrieved successfully.", HttpStatus.OK.value(), messages);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @GetMapping("/{consumerId}/message/{messageId}")
    public ResponseEntity<Response<MessageDto>> getMessage(
            @PathVariable String consumerId,
            @PathVariable String messageId,
            @RequestHeader("Authorization") String projectAuthToken) {
        MessageDto message = iConsumerService.getMessage(messageId, consumerId, projectAuthToken);
        Response<MessageDto> apiResponse = new Response<>("Message retrieved successfully.", HttpStatus.OK.value(), message);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @DeleteMapping("/{consumerId}/message/{messageId}")
    public ResponseEntity<Response<Void>> deleteMessage(
            @PathVariable String consumerId,
            @PathVariable String messageId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iConsumerService.deleteMessage(messageId, consumerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Message deleted successfully.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{consumerId}/broker")
    public ResponseEntity<Response<ConsumerDto>> setBroker(
            @PathVariable String consumerId,
            @Valid @RequestBody BrokerUpdate brokerUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ConsumerDto updatedConsumer = iConsumerService.setBroker(consumerId, brokerUpdate, projectAuthToken);
        Response<ConsumerDto> apiResponse = new Response<>("Consumer broker updated.", HttpStatus.OK.value(), updatedConsumer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{consumerId}/strategy")
    public ResponseEntity<Response<ConsumerDto>> setStrategy(
            @PathVariable String consumerId,
            @Valid @RequestBody StrategyUpdate strategyUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ConsumerDto updatedConsumer = iConsumerService.setStrategy(consumerId, strategyUpdate, projectAuthToken);
        Response<ConsumerDto> apiResponse = new Response<>("Consumer strategy updated.", HttpStatus.OK.value(), updatedConsumer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{consumerId}/queue")
    public ResponseEntity<Response<ConsumerDto>> setQueue(
            @PathVariable String consumerId,
            @Valid @RequestBody QueueUpdate queueUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ConsumerDto updatedConsumer = iConsumerService.setQueue(consumerId, queueUpdate, projectAuthToken);
        Response<ConsumerDto> apiResponse = new Response<>("Consumer queue updated.", HttpStatus.OK.value(), updatedConsumer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{consumerId}/persistence")
    public ResponseEntity<Response<ConsumerDto>> setPersistenceTime(
            @PathVariable String consumerId,
            @Valid @RequestBody PersistenceUpdate persistenceUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ConsumerDto updatedConsumer = iConsumerService.setPersistenceTime(consumerId, persistenceUpdate, projectAuthToken);
        Response<ConsumerDto> apiResponse = new Response<>("Consumer persistence time updated.", HttpStatus.OK.value(), updatedConsumer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }
}