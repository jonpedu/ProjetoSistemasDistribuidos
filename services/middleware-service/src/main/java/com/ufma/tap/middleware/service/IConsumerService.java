// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/service/IConsumerService.java
package com.ufma.tap.middleware.service;

import com.ufma.tap.middleware.model.Consumer;
import com.ufma.tap.middleware.dto.ConsumerDto;
import com.ufma.tap.middleware.dto.MessageDto;
import com.ufma.tap.middleware.dto.StrategyUpdate;
import com.ufma.tap.middleware.dto.QueueUpdate;
import com.ufma.tap.middleware.dto.BrokerUpdate;
import com.ufma.tap.middleware.dto.PersistenceUpdate;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

public interface IConsumerService {
    ConsumerDto registerConsumer(Consumer consumer, String projectAuthToken);
    ConsumerDto getConsumer(String consumerId, String projectAuthToken);
    void deleteConsumer(String consumerId, String projectAuthToken);
    SseEmitter connectConsumer(String consumerId, String projectAuthToken); // Retorna SseEmitter para conexão de streaming
    void disconnectConsumer(String consumerId, String projectAuthToken);
    List<MessageDto> getMessages(String consumerId, String projectAuthToken); // Obter mensagens persistidas
    MessageDto getMessage(String messageId, String consumerId, String projectAuthToken);
    void deleteMessage(String messageId, String consumerId, String projectAuthToken);

    // Métodos para atualização de campos específicos
    ConsumerDto setBroker(String consumerId, BrokerUpdate brokerUpdate, String projectAuthToken);
    ConsumerDto setStrategy(String consumerId, StrategyUpdate strategyUpdate, String projectAuthToken);
    ConsumerDto setQueue(String consumerId, QueueUpdate queueUpdate, String projectAuthToken);
    ConsumerDto setPersistenceTime(String consumerId, PersistenceUpdate persistenceUpdate, String projectAuthToken);
}