// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/service/DiscoveryService.java
package com.ufma.tap.discovery.service;

import com.google.gson.Gson; // Para desserializar eventos RabbitMQ
import com.ufma.tap.discovery.dto.ConsumerConnectionEvent;
import com.ufma.tap.discovery.dto.ReceiverInstanceDto;
import com.ufma.tap.discovery.exception.ReceiverNotFoundException;
import com.ufma.tap.discovery.exception.InvalidCredentialsException;
import com.ufma.tap.discovery.model.ReceiverInstance;
import com.ufma.tap.discovery.repository.ReceiverInstanceRepository;
import com.ufma.tap.discovery.security.JWTUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class DiscoveryService implements IDiscoveryService {

    @Autowired
    private ReceiverInstanceRepository receiverInstanceRepository;

    @Autowired
    private JWTUtil jwtUtil;

    private final Gson gson = new Gson();

    // Método que será chamado pelo RabbitMQ Listener
    @Override
    public void handleConsumerConnectionEvent(ConsumerConnectionEvent event) {
        System.out.println("Discovery Service - Received event: " + event.getEventType() + " for consumer: " + event.getConsumerId() + " on replica: " + event.getReplicaIp());

        if ("CONNECTED".equals(event.getEventType())) {
            ReceiverInstance instance = new ReceiverInstance(event.getConsumerId(), event.getReplicaIp(), event.getProjectId());
            receiverInstanceRepository.save(instance);
            System.out.println("Discovery Service - Registered/Updated consumer " + event.getConsumerId() + " to replica " + event.getReplicaIp());
        } else if ("DISCONNECTED".equals(event.getEventType())) {
            receiverInstanceRepository.deleteById(event.getConsumerId());
            System.out.println("Discovery Service - Removed consumer " + event.getConsumerId() + " from registry.");
        } else {
            System.err.println("Discovery Service - Unknown event type: " + event.getEventType() + " for consumer: " + event.getConsumerId());
        }
    }

    // Endpoint GET /api/receivers/{consumerId} para rotear requests de update/delete
    @Override
    public ReceiverInstanceDto getReceiverReplica(String consumerId, String projectAuthToken) {
        // Validar token e associação ao projeto (muito importante para segurança)
        ReceiverInstance instance = findAndValidateReceiverInstance(consumerId, projectAuthToken);
        return ReceiverInstanceDto.fromModel(instance);
    }

    @Override
    public void removeReceiverReplica(String consumerId, String projectAuthToken) {
        ReceiverInstance instance = findAndValidateReceiverInstance(consumerId, projectAuthToken);
        receiverInstanceRepository.delete(instance);
        System.out.println("Discovery Service - Explicitly removed consumer " + consumerId + " from registry by API call.");
    }

    @Override
    public ReceiverInstanceDto registerOrUpdateReceiverReplica(ReceiverInstance instance, String projectAuthToken) {
        String projectIdFromToken = jwtUtil.extractAllClaims(projectAuthToken.replace("Bearer ", "")).get("projectId", String.class);
        if (projectIdFromToken == null || !instance.getProjectId().equals(projectIdFromToken)) {
            throw new InvalidCredentialsException("Unauthorized access or invalid project token for registration.");
        }
        ReceiverInstance savedInstance = receiverInstanceRepository.save(instance);
        return ReceiverInstanceDto.fromModel(savedInstance);
    }


    // Método auxiliar para validar e buscar ReceiverInstance
    private ReceiverInstance findAndValidateReceiverInstance(String consumerId, String projectAuthToken) {
        ReceiverInstance instance = receiverInstanceRepository.findById(consumerId)
                .orElseThrow(() -> new ReceiverNotFoundException("Receiver instance for consumer ID '" + consumerId + "' not found."));

        String projectIdFromToken = jwtUtil.extractAllClaims(projectAuthToken.replace("Bearer ", "")).get("projectId", String.class);
        if (projectIdFromToken == null || !instance.getProjectId().equals(projectIdFromToken)) {
            throw new InvalidCredentialsException("Unauthorized access to receiver instance or invalid project token.");
        }
        return instance;
    }
}