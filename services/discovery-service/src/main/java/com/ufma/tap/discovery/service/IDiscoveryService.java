// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/service/IDiscoveryService.java
package com.ufma.tap.discovery.service;

import com.ufma.tap.discovery.dto.ReceiverInstanceDto;
import com.ufma.tap.discovery.dto.ConsumerConnectionEvent;
import com.ufma.tap.discovery.model.ReceiverInstance;

public interface IDiscoveryService {
    // Método para ser chamado por um RabbitMQ Listener
    void handleConsumerConnectionEvent(ConsumerConnectionEvent event);

    // Método para ser chamado por outros serviços via API REST (para roteamento)
    ReceiverInstanceDto getReceiverReplica(String consumerId, String projectAuthToken);

    // Método para ser chamado para simular ou forçar a remoção de um registro
    void removeReceiverReplica(String consumerId, String projectAuthToken);

    // Método para ser chamado para atualizar (ou registrar) uma réplica diretamente
    ReceiverInstanceDto registerOrUpdateReceiverReplica(ReceiverInstance instance, String projectAuthToken);
}