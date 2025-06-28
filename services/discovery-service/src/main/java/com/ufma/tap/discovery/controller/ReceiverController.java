// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/controller/ReceiverController.java
package com.ufma.tap.discovery.controller;

import com.ufma.tap.discovery.dto.ReceiverInstanceDto;
import com.ufma.tap.discovery.dto.Response;
import com.ufma.tap.discovery.service.IDiscoveryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.annotation.Validated;
import jakarta.validation.Valid; // Para validação de DTOs de entrada

@RestController
@RequestMapping("/api/receivers") // Note que é /api/receivers, igual ao middleware, mas em portas diferentes
@Validated
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ReceiverController {

    @Autowired
    private IDiscoveryService iDiscoveryService;

    // Endpoint para outros serviços (ex: middleware-service) registrarem/atualizarem uma réplica de consumidor
    // Pode ser chamado diretamente por outros serviços que conhecem o Discovery
    @PostMapping("/register-replica")
    public ResponseEntity<Response<ReceiverInstanceDto>> registerOrUpdateReceiverReplica(
            @Valid @RequestBody ReceiverInstanceDto receiverInstanceDto,
            @RequestHeader("Authorization") String projectAuthToken) {
        // Converte DTO para modelo antes de passar para o serviço
        ReceiverInstanceDto returnedDto = iDiscoveryService.registerOrUpdateReceiverReplica(receiverInstanceDto.toModel(), projectAuthToken);
        Response<ReceiverInstanceDto> apiResponse = new Response<>("Receiver instance registered/updated.", HttpStatus.OK.value(), returnedDto); // Use 'returnedDto' aqui
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);



    }

    // Endpoint para outros serviços (ex: middleware-service, se ele precisar rotear updates)
    // consultarem a réplica atual de um consumidor
    @GetMapping("/{consumerId}/replica")
    public ResponseEntity<Response<ReceiverInstanceDto>> getReceiverReplica(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        ReceiverInstanceDto dto = iDiscoveryService.getReceiverReplica(consumerId, projectAuthToken);
        Response<ReceiverInstanceDto> apiResponse = new Response<>("Receiver replica info retrieved.", HttpStatus.OK.value(), dto);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    // Endpoint para outros serviços removerem o registro de uma réplica (ex: ao desconectar permanentemente)
    @DeleteMapping("/{consumerId}/replica")
    public ResponseEntity<Response<Void>> removeReceiverReplica(
            @PathVariable String consumerId,
            @RequestHeader("Authorization") String projectAuthToken) {
        iDiscoveryService.removeReceiverReplica(consumerId, projectAuthToken);
        Response<Void> apiResponse = new Response<>("Receiver instance removed.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    // TODO: Outros endpoints para update/delete de consumer, que seriam roteados por aqui,
    // iriam fazer chamadas HTTP para a replicaIp do middleware-service
}