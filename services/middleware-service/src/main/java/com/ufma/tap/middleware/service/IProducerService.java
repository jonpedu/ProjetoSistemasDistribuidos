// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/service/IProducerService.java
package com.ufma.tap.middleware.service;

import com.ufma.tap.middleware.model.Producer;
import com.ufma.tap.middleware.dto.MessageReceived;
import com.ufma.tap.middleware.dto.ProducerDto; // DTO para update
import com.ufma.tap.middleware.dto.StrategyUpdate; // DTO de atualização
import com.ufma.tap.middleware.dto.QueueUpdate; // DTO de atualização
import com.ufma.tap.middleware.dto.BrokerUpdate; // DTO de atualização

public interface IProducerService {
    ProducerDto registerProducer(Producer producer, String projectAuthToken); // Retorna DTO para não expor senha
    ProducerDto getProducer(String producerId, String projectAuthToken);
    void deleteProducer(String producerId, String projectAuthToken);
    void connectProducer(String producerId, String projectAuthToken); // Conectar o produtor ao broker (pode ser implícita no send)
    void send(String producerId, MessageReceived messageReceived, String projectAuthToken);
    void disconnectProducer(String producerId, String projectAuthToken); // Desconectar o produtor do broker

    // Métodos para atualização de campos específicos
    ProducerDto setBroker(String producerId, BrokerUpdate brokerUpdate, String projectAuthToken);
    ProducerDto setStrategy(String producerId, StrategyUpdate strategyUpdate, String projectAuthToken);
    ProducerDto setQueue(String producerId, QueueUpdate queueUpdate, String projectAuthToken);
}