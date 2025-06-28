// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/controller/ProducerController.java
package com.ufma.tap.middleware.controller;

import com.ufma.tap.middleware.dto.MessageReceived;
import com.ufma.tap.middleware.dto.ProducerDto;
import com.ufma.tap.middleware.dto.Response;
import com.ufma.tap.middleware.model.Producer;
import com.ufma.tap.middleware.service.IProducerService;
import com.ufma.tap.middleware.dto.BrokerUpdate;
import com.ufma.tap.middleware.dto.QueueUpdate;
import com.ufma.tap.middleware.dto.StrategyUpdate;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.annotation.Validated;

@RestController
@RequestMapping("/api/senders")
@Validated
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ProducerController {

    @Autowired
    private IProducerService iProducerService;

    @PostMapping
    public ResponseEntity<Response<ProducerDto>> registerProducer(
            @Valid @RequestBody ProducerDto producerDto,
            @RequestHeader("Authorization") String projectAuthToken) {
        // Mude de 'Producer' para 'ProducerDto' aqui
        ProducerDto registeredProducerDto = iProducerService.registerProducer(producerDto.toModel(), projectAuthToken); // LINHA CORRIGIDA

        // E ajuste a linha seguinte para usar 'registeredProducerDto' diretamente
        Response<ProducerDto> apiResponse = new Response<>("Producer registered.", HttpStatus.CREATED.value(), registeredProducerDto);
        return new ResponseEntity<>(apiResponse, HttpStatus.CREATED);
    }

    @GetMapping("/{producerId}")
    public ResponseEntity<Response<ProducerDto>> getProducer(
            @PathVariable String producerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        ProducerDto producerDto = iProducerService.getProducer(producerId, projectAuthToken);
        Response<ProducerDto> apiResponse = new Response<>("Producer info retrieved.", HttpStatus.OK.value(), producerDto);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @DeleteMapping("/{producerId}")
    public ResponseEntity<Response<Void>> deleteProducer(
            @PathVariable String producerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iProducerService.deleteProducer(producerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Producer deleted.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PostMapping("/{producerId}/connect")
    public ResponseEntity<Response<Void>> connectProducer(
            @PathVariable String producerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iProducerService.connectProducer(producerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Producer connected.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PostMapping("/{producerId}/send")
    public ResponseEntity<Response<Void>> send(
            @PathVariable String producerId,
            @Valid @RequestBody MessageReceived messageReceived,
            @RequestHeader("Authorization") String projectAuthToken) {
        iProducerService.send(producerId, messageReceived, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Message successfully sent.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PostMapping("/{producerId}/close")
    public ResponseEntity<Response<Void>> disconnectProducer(
            @PathVariable String producerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iProducerService.disconnectProducer(producerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Producer disconnected.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{producerId}/broker")
    public ResponseEntity<Response<ProducerDto>> setBroker(
            @PathVariable String producerId,
            @Valid @RequestBody BrokerUpdate brokerUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ProducerDto updatedProducer = iProducerService.setBroker(producerId, brokerUpdate, projectAuthToken);
        Response<ProducerDto> apiResponse = new Response<>("Producer broker successfully updated.", HttpStatus.OK.value(), updatedProducer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{producerId}/strategy")
    public ResponseEntity<Response<ProducerDto>> setStrategy(
            @PathVariable String producerId,
            @Valid @RequestBody StrategyUpdate strategyUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ProducerDto updatedProducer = iProducerService.setStrategy(producerId, strategyUpdate, projectAuthToken);
        Response<ProducerDto> apiResponse = new Response<>("Producer strategy successfully updated.", HttpStatus.OK.value(), updatedProducer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{producerId}/queue")
    public ResponseEntity<Response<ProducerDto>> setQueue(
            @PathVariable String producerId,
            @Valid @RequestBody QueueUpdate queueUpdate,
            @RequestHeader("Authorization") String projectAuthToken) {
        ProducerDto updatedProducer = iProducerService.setQueue(producerId, queueUpdate, projectAuthToken);
        Response<ProducerDto> apiResponse = new Response<>("Producer queue successfully updated.", HttpStatus.OK.value(), updatedProducer);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }
}