// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/service/ConsumerService.java
package com.ufma.tap.middleware.service;

import com.google.gson.Gson;
import com.ufma.tap.middleware.auth.BasicAuthUtil;
import com.ufma.tap.middleware.model.Consumer;
import com.ufma.tap.middleware.model.Broker; // Model POJO para configurações de broker
import com.ufma.tap.middleware.model.Message;
import com.ufma.tap.middleware.repository.ConsumerRepository;
import com.ufma.tap.middleware.repository.EmitterRepository;
import com.ufma.tap.middleware.repository.MessageRepository;
import com.ufma.tap.middleware.security.JWTUtil;
import com.ufma.tap.middleware.messagebroker.IConsumerMessaging;
import com.ufma.tap.middleware.dto.ConsumerDto;
import com.ufma.tap.middleware.dto.MessageDto;
import com.ufma.tap.middleware.dto.StrategyUpdate;
import com.ufma.tap.middleware.dto.QueueUpdate;
import com.ufma.tap.middleware.dto.BrokerUpdate;
import com.ufma.tap.middleware.dto.PersistenceUpdate;
import com.ufma.tap.middleware.exception.InvalidCredentialsException;
import com.ufma.tap.middleware.exception.ConsumerNotFoundException;
import com.ufma.tap.middleware.exception.UserConflictException;
import com.ufma.tap.middleware.exception.BrokerNotSupportedException;
import com.ufma.tap.middleware.exception.BrokerStrategyIncompatibleException;
import com.ufma.tap.middleware.exception.MessageNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ConsumerService implements IConsumerService {

    @Autowired
    private ConsumerRepository consumerRepository;
    @Autowired
    private MessageRepository messageRepository;
    @Autowired
    private EmitterRepository emitterRepository;

    @Autowired
    private JWTUtil jwtUtil;
    @Autowired
    private BasicAuthUtil basicAuthUtil;

    // Injetando as implementações específicas de consumidores
    @Autowired
    @Qualifier("rabbitMQConsumer")
    private IConsumerMessaging rabbitMQConsumer;

    // TODO: Adicionar @Autowired @Qualifier para KafkaConsumer, ActiveMQ5Consumer quando implementados

    private final Set<String> GLOBAL_SUPPORTED_BROKERS = Set.of("rabbitmq", "kafka", "activemq5");
    private final Gson gson = new Gson();

    @Override
    public ConsumerDto registerConsumer(Consumer consumer, String projectAuthToken) {
        String projectId = jwtUtil.extractAllClaims(projectAuthToken.replace("Bearer ", "")).get("projectId", String.class);
        if (projectId == null) {
            throw new InvalidCredentialsException("Project token is invalid or missing ProjectId.");
        }

        if (consumerRepository.existsByUsername(consumer.getUsername())) {
            throw new UserConflictException("Consumer with username '" + consumer.getUsername() + "' already registered.");
        }

        if (!GLOBAL_SUPPORTED_BROKERS.contains(consumer.getBroker().toLowerCase())) {
            throw new BrokerNotSupportedException("Broker '" + consumer.getBroker() + "' is not globally supported.");
        }

        validateBrokerStrategy(consumer.getBroker(), consumer.getStrategy());

        consumer.setId(UUID.randomUUID().toString());
        consumer.setProjectId(projectId);

        // TODO: Criptografar a senha do consumidor antes de salvar!

        Consumer savedConsumer = consumerRepository.save(consumer);
        return ConsumerDto.fromModel(savedConsumer);
    }

    @Override
    public ConsumerDto getConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        return ConsumerDto.fromModel(consumer);
    }

    @Override
    public void deleteConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        // Desconecta o consumidor do broker primeiro
        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId());
        // Remove o SSEmitter se houver
        emitterRepository.remove(consumer.getId());
        // Deleta mensagens persistidas associadas a este consumidor
        messageRepository.deleteAllByConsumerId(consumer.getId());
        // Deleta o consumidor do banco de dados
        consumerRepository.delete(consumer);
    }

    @Override
    public SseEmitter connectConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);

        // Cria um novo SseEmitter para a conexão de longa duração
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); // Long.MAX_VALUE para não expirar automaticamente

        emitter.onCompletion(() -> emitterRepository.remove(consumerId));
        emitter.onTimeout(() -> emitterRepository.remove(consumerId));
        emitter.onError((e) -> {
            System.err.println("SSE Emitter error for consumer " + consumerId + ": " + e.getMessage());
            emitterRepository.remove(consumerId);
        });

        emitterRepository.add(consumerId, emitter);

        // Conecta o consumidor ao broker e define o handler de mensagens
        Broker brokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(brokerConfig.getName())
                .connectAndListen(consumer, receivedMessage -> {
                    // Este é o callback do adaptador de mensageria quando uma mensagem é recebida do broker
                    handleBrokerMessage(receivedMessage, emitter);
                });

        return emitter;
    }

    @Override
    public void disconnectConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId());
        emitterRepository.remove(consumer.getId()); // Garante que o emitter seja removido
    }

    @Override
    public List<MessageDto> getMessages(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        return messageRepository.findByConsumerId(consumerId).stream()
                .map(MessageDto::fromModel)
                .collect(Collectors.toList());
    }

    @Override
    public MessageDto getMessage(String messageId, String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        return messageRepository.findByMessageIdAndConsumerId(messageId, consumerId)
                .map(MessageDto::fromModel)
                .orElseThrow(() -> new MessageNotFoundException("Message with ID '" + messageId + "' for consumer '" + consumerId + "' not found."));
    }

    @Override
    public void deleteMessage(String messageId, String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        messageRepository.findByMessageIdAndConsumerId(messageId, consumerId)
                .orElseThrow(() -> new MessageNotFoundException("Message with ID '" + messageId + "' for consumer '" + consumerId + "' not found."));
        messageRepository.deleteByMessageIdAndConsumerId(messageId, consumerId);
    }

    @Override
    public ConsumerDto setBroker(String consumerId, BrokerUpdate brokerUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);

        if (!GLOBAL_SUPPORTED_BROKERS.contains(brokerUpdate.getBroker().toLowerCase())) {
            throw new BrokerNotSupportedException("Broker '" + brokerUpdate.getBroker() + "' is not globally supported.");
        }
        validateBrokerStrategy(brokerUpdate.getBroker(), brokerUpdate.getStrategy());

        // Desconectar do broker antigo antes de reconfigurar
        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId());

        consumer.setBroker(brokerUpdate.getBroker());
        consumer.setStrategy(brokerUpdate.getStrategy());
        consumer.setExchange(brokerUpdate.getExchange());
        consumer.setQueue(brokerUpdate.getQueue());
        consumer.setRoutingKey(brokerUpdate.getRoutingKey());
        consumer.setHeaders(brokerUpdate.getHeaders() != null ? gson.toJson(brokerUpdate.getHeaders()) : null);

        // Reconectar com as novas configurações (a conexão SSE é mantida)
        Broker newBrokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(newBrokerConfig.getName())
                .connectAndListen(consumer, receivedMessage -> {
                    handleBrokerMessage(receivedMessage, emitterRepository.get(consumerId).orElse(null));
                });

        return ConsumerDto.fromModel(consumerRepository.save(consumer));
    }

    @Override
    public ConsumerDto setStrategy(String consumerId, StrategyUpdate strategyUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        validateBrokerStrategy(consumer.getBroker(), strategyUpdate.getStrategy());

        // Desconectar do broker antigo antes de reconfigurar
        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId());

        consumer.setStrategy(strategyUpdate.getStrategy());
        consumer.setExchange(strategyUpdate.getExchange());
        consumer.setQueue(strategyUpdate.getQueue());
        consumer.setRoutingKey(strategyUpdate.getRoutingKey());
        consumer.setHeaders(strategyUpdate.getHeaders() != null ? gson.toJson(strategyUpdate.getHeaders()) : null);

        // Reconectar
        Broker newBrokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(newBrokerConfig.getName())
                .connectAndListen(consumer, receivedMessage -> {
                    handleBrokerMessage(receivedMessage, emitterRepository.get(consumerId).orElse(null));
                });

        return ConsumerDto.fromModel(consumerRepository.save(consumer));
    }

    @Override
    public ConsumerDto setQueue(String consumerId, QueueUpdate queueUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);

        // Desconectar do broker antigo antes de reconfigurar
        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId());

        consumer.setQueue(queueUpdate.getQueue());
        consumer.setExchange(queueUpdate.getExchange());
        consumer.setRoutingKey(queueUpdate.getRoutingKey());
        consumer.setHeaders(queueUpdate.getHeaders() != null ? gson.toJson(queueUpdate.getHeaders()) : null);

        // Reconectar
        Broker newBrokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(newBrokerConfig.getName())
                .connectAndListen(consumer, receivedMessage -> {
                    handleBrokerMessage(receivedMessage, emitterRepository.get(consumerId).orElse(null));
                });

        return ConsumerDto.fromModel(consumerRepository.save(consumer));
    }

    @Override
    public ConsumerDto setPersistenceTime(String consumerId, PersistenceUpdate persistenceUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        consumer.setPersistenceTime(persistenceUpdate.getPersistenceTime());
        return ConsumerDto.fromModel(consumerRepository.save(consumer));
    }


    // --- Métodos Auxiliares ---
    private Consumer findAndValidateConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = consumerRepository.findById(consumerId)
                .orElseThrow(() -> new ConsumerNotFoundException("Consumer with ID '" + consumerId + "' not found."));

        String projectIdFromToken = jwtUtil.extractAllClaims(projectAuthToken.replace("Bearer ", "")).get("projectId", String.class);
        if (projectIdFromToken == null || !consumer.getProjectId().equals(projectIdFromToken)) {
            throw new InvalidCredentialsException("Unauthorized access to consumer or invalid project token.");
        }
        return consumer;
    }

    private IConsumerMessaging getConsumerMessagingAdapter(String brokerName) {
        switch (brokerName.toLowerCase()) {
            case "rabbitmq":
                return rabbitMQConsumer;
            // TODO: Adicionar outros brokers quando implementados
            // case "kafka":
            //     return kafkaConsumer;
            default:
                throw new BrokerNotSupportedException("Broker '" + brokerName + "' not supported by this service instance.");
        }
    }

    // Método para construir o objeto Broker POJO a partir do Consumer
    private Broker buildBrokerConfig(Consumer consumer) {
        Broker broker = new Broker();
        broker.setName(consumer.getBroker());
        broker.setStrategy(consumer.getStrategy());
        broker.setExchange(consumer.getExchange());
        broker.setQueue(consumer.getQueue());
        broker.setRoutingKey(consumer.getRoutingKey());
        broker.setHeaders(consumer.getHeaders());
        return broker;
    }

    // Callback para lidar com a mensagem recebida do broker
    private void handleBrokerMessage(Message receivedMessage, SseEmitter emitter) {
        try {
            // Persistir a mensagem se o persistenceTime do consumidor for > 0
            if (receivedMessage.getExpireAt() != null) { // Verifica se há uma data de expiração (indicando persistência)
                messageRepository.save(receivedMessage);
            }

            // Enviar a mensagem via SSE (se o emitter estiver ativo)
            if (emitter != null) {
                emitter.send(SseEmitter.event()
                        .id(receivedMessage.getMessageId())
                        .name("message")
                        .data(MessageDto.fromModel(receivedMessage))); // Envia o DTO da mensagem
                System.out.println("Message " + receivedMessage.getMessageId() + " sent via SSE to consumer " + receivedMessage.getConsumerId());
            } else {
                System.out.println("SSE Emitter for consumer " + receivedMessage.getConsumerId() + " is null or closed. Message not sent via SSE.");
            }
        } catch (IOException e) {
            System.err.println("Error sending message via SSE for consumer " + receivedMessage.getConsumerId() + ": " + e.getMessage());
            emitterRepository.remove(receivedMessage.getConsumerId()); // Remove o emitter se houver erro de IO
        } catch (Exception e) {
            System.err.println("Error handling received broker message for consumer " + receivedMessage.getConsumerId() + ": " + e.getMessage());
        }
    }

    // Valida se a estratégia é compatível com o broker
    private void validateBrokerStrategy(String brokerName, String strategy) {
        switch (brokerName.toLowerCase()) {
            case "rabbitmq":
                if (!Set.of("direct", "topic", "fanout", "headers").contains(strategy.toLowerCase())) {
                    throw new BrokerStrategyIncompatibleException("RabbitMQ does not support strategy: " + strategy);
                }
                break;
            case "kafka":
                if (!Set.of("topic").contains(strategy.toLowerCase())) {
                    throw new BrokerStrategyIncompatibleException("Kafka only supports 'topic' strategy.");
                }
                break;
            case "activemq5":
                if (!Set.of("direct", "topic").contains(strategy.toLowerCase())) {
                    throw new BrokerStrategyIncompatibleException("ActiveMQ5 only supports 'direct' and 'topic' strategies.");
                }
                break;
            default:
                // Já tratado por BrokerNotSupportedException
                break;
        }
    }
}