// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/service/ConsumerService.java
package com.ufma.tap.middleware.service;

import com.google.gson.Gson;
import com.ufma.tap.middleware.auth.BasicAuthUtil;
import com.ufma.tap.middleware.model.Consumer;
import com.ufma.tap.middleware.model.Broker;
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
import com.ufma.tap.middleware.dto.ConsumerConnectionEvent; // <<< NOVO IMPORT
import com.ufma.tap.middleware.exception.InvalidCredentialsException;
import com.ufma.tap.middleware.exception.ConsumerNotFoundException;
import com.ufma.tap.middleware.exception.UserConflictException;
import com.ufma.tap.middleware.exception.BrokerNotSupportedException;
import com.ufma.tap.middleware.exception.BrokerStrategyIncompatibleException;
import com.ufma.tap.middleware.exception.MessageNotFoundException;
import org.springframework.amqp.core.AmqpTemplate; // <<< NOVO IMPORT
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Date;
import java.util.List;
import java.util.Optional;
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

    @Autowired
    private AmqpTemplate rabbitTemplate; // <<< INJEÇÃO DO RABBIT TEMPLATE

    // Injetando as implementações específicas de consumidores
    @Autowired
    @Qualifier("rabbitMQConsumer")
    private IConsumerMessaging rabbitMQConsumer;

    // TODO: Adicionar @Autowired @Qualifier para KafkaConsumer, ActiveMQ5Consumer quando implementados

    private final Set<String> GLOBAL_SUPPORTED_BROKERS = Set.of("rabbitmq", "kafka", "activemq5");
    private final Gson gson = new Gson();

    // Constantes para o RabbitMQ (DEVE SER AS MESMAS NO discovery-service/config/RabbitMQConfig.java)
    private static final String CONSUMER_CONNECTION_EXCHANGE = "consumer.connection.events";
    private static final String CONSUMER_CONNECTED_ROUTING_KEY = "consumer.connection.connected";
    private static final String CONSUMER_DISCONNECTED_ROUTING_KEY = "consumer.connection.disconnected";


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

        // Publica evento de consumidor desconectado após exclusão
        publishConsumerConnectionEvent(consumer.getId(), consumer.getProjectId(), "DISCONNECTED", "Consumer " + consumer.getId() + " deleted.");
    }

    @Override
    public SseEmitter connectConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);

        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);

        emitter.onCompletion(() -> {
            emitterRepository.remove(consumerId);
            // Publica evento de consumidor desconectado (por completion)
            publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "DISCONNECTED", "Consumer " + consumerId + " disconnected (completion).");
        });
        emitter.onTimeout(() -> {
            emitterRepository.remove(consumerId);
            // Publica evento de consumidor desconectado (por timeout)
            publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "DISCONNECTED", "Consumer " + consumerId + " disconnected (timeout).");
        });
        emitter.onError((e) -> {
            System.err.println("SSE Emitter error for consumer " + consumerId + ": " + e.getMessage());
            emitterRepository.remove(consumerId);
            // Publica evento de consumidor desconectado (por erro)
            publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "DISCONNECTED", "Consumer " + consumerId + " disconnected (error: " + e.getMessage() + ").");
        });

        emitterRepository.add(consumerId, emitter);

        Broker brokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(brokerConfig.getName())
                .connectAndListen(consumer, receivedMessage -> {
                    handleBrokerMessage(receivedMessage, emitter);
                });

        // Publica evento de consumidor conectado
        publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "CONNECTED", "Consumer " + consumerId + " connected.");
        return emitter;
    }

    @Override
    public void disconnectConsumer(String consumerId, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId());
        emitterRepository.remove(consumer.getId());

        // Publica evento de consumidor desconectado por chamada explícita de API
        publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "DISCONNECTED", "Consumer " + consumer.getId() + " disconnected by API call.");
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

        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId()); // Desconecta do broker antigo

        consumer.setBroker(brokerUpdate.getBroker());
        consumer.setStrategy(brokerUpdate.getStrategy());
        consumer.setExchange(brokerUpdate.getExchange());
        consumer.setQueue(brokerUpdate.getQueue());
        consumer.setRoutingKey(brokerUpdate.getRoutingKey());
        consumer.setHeaders(brokerUpdate.getHeaders() != null ? gson.toJson(brokerUpdate.getHeaders()) : null);

        Consumer savedConsumer = consumerRepository.save(consumer);

        // Reconecta com as novas configurações (a conexão SSE é mantida)
        Broker newBrokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(newBrokerConfig.getName())
                .connectAndListen(savedConsumer, receivedMessage -> { // Passa o savedConsumer para o callback
                    handleBrokerMessage(receivedMessage, emitterRepository.get(consumerId).orElse(null));
                });

        // Publica evento de atualização (reconexão)
        publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "CONNECTED", "Consumer " + consumerId + " reconnected (broker updated).");

        return ConsumerDto.fromModel(savedConsumer);
    }

    @Override
    public ConsumerDto setStrategy(String consumerId, StrategyUpdate strategyUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        validateBrokerStrategy(consumer.getBroker(), strategyUpdate.getStrategy());

        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId()); // Desconecta do broker antigo

        consumer.setStrategy(strategyUpdate.getStrategy());
        consumer.setExchange(strategyUpdate.getExchange());
        consumer.setQueue(strategyUpdate.getQueue());
        consumer.setRoutingKey(strategyUpdate.getRoutingKey());
        consumer.setHeaders(strategyUpdate.getHeaders() != null ? gson.toJson(strategyUpdate.getHeaders()) : null);

        Consumer savedConsumer = consumerRepository.save(consumer);

        Broker newBrokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(newBrokerConfig.getName())
                .connectAndListen(savedConsumer, receivedMessage -> {
                    handleBrokerMessage(receivedMessage, emitterRepository.get(consumerId).orElse(null));
                });

        publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "CONNECTED", "Consumer " + consumerId + " reconnected (strategy updated).");

        return ConsumerDto.fromModel(savedConsumer);
    }

    @Override
    public ConsumerDto setQueue(String consumerId, QueueUpdate queueUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);

        getConsumerMessagingAdapter(consumer.getBroker()).close(consumer.getId()); // Desconecta do broker antigo

        consumer.setQueue(queueUpdate.getQueue());
        consumer.setExchange(queueUpdate.getExchange());
        consumer.setRoutingKey(queueUpdate.getRoutingKey());
        consumer.setHeaders(queueUpdate.getHeaders() != null ? gson.toJson(queueUpdate.getHeaders()) : null);

        Consumer savedConsumer = consumerRepository.save(consumer);

        Broker newBrokerConfig = buildBrokerConfig(consumer);
        getConsumerMessagingAdapter(newBrokerConfig.getName())
                .connectAndListen(savedConsumer, receivedMessage -> {
                    handleBrokerMessage(receivedMessage, emitterRepository.get(consumerId).orElse(null));
                });

        publishConsumerConnectionEvent(consumerId, consumer.getProjectId(), "CONNECTED", "Consumer " + consumerId + " reconnected (queue updated).");

        return ConsumerDto.fromModel(savedConsumer);
    }

    @Override
    public ConsumerDto setPersistenceTime(String consumerId, PersistenceUpdate persistenceUpdate, String projectAuthToken) {
        Consumer consumer = findAndValidateConsumer(consumerId, projectAuthToken);
        consumer.setPersistenceTime(persistenceUpdate.getPersistenceTime());
        Consumer savedConsumer = consumerRepository.save(consumer);
        // Não há necessidade de reconectar ou publicar evento de conexão para mudança de persistenceTime
        return ConsumerDto.fromModel(savedConsumer);
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

    private void handleBrokerMessage(Message receivedMessage, SseEmitter emitter) {
        try {
            if (receivedMessage.getExpireAt() != null) {
                messageRepository.save(receivedMessage);
            }

            if (emitter != null) {
                emitter.send(SseEmitter.event()
                        .id(receivedMessage.getMessageId())
                        .name("message")
                        .data(MessageDto.fromModel(receivedMessage)));
                System.out.println("Message " + receivedMessage.getMessageId() + " sent via SSE to consumer " + receivedMessage.getConsumerId());
            } else {
                System.out.println("SSE Emitter for consumer " + receivedMessage.getConsumerId() + " is null or closed. Message not sent via SSE.");
            }
        } catch (IOException e) {
            System.err.println("Error sending message via SSE for consumer " + receivedMessage.getConsumerId() + ": " + e.getMessage());
            emitterRepository.remove(receivedMessage.getConsumerId());
        } catch (Exception e) {
            System.err.println("Error handling received broker message for consumer " + receivedMessage.getConsumerId() + ": " + e.getMessage());
        }
    }

    // --- NOVO MÉTODO AUXILIAR PARA PUBLICAR EVENTOS DE CONEXÃO ---
    private void publishConsumerConnectionEvent(String consumerId, String projectId, String eventType, String logMessage) {
        try {
            ConsumerConnectionEvent event = new ConsumerConnectionEvent();
            event.setConsumerId(consumerId);
            event.setProjectId(projectId);
            // IP da réplica onde este middleware-service está rodando
            // Em um ambiente real, isso viria de uma variável de ambiente ou serviço de metadados da VM/container
            event.setReplicaIp(System.getenv("POD_IP") != null ? System.getenv("POD_IP") : "localhost:8081"); // Exemplo simples
            event.setEventType(eventType);

            String eventJson = gson.toJson(event);
            String routingKey = CONSUMER_CONNECTION_EXCHANGE + "." + eventType.toLowerCase(); // Ex: consumer.connection.events.connected

            rabbitTemplate.convertAndSend(CONSUMER_CONNECTION_EXCHANGE, routingKey, eventJson);
            System.out.println("Published consumer connection event: " + logMessage);
        } catch (Exception e) {
            System.err.println("Failed to publish consumer connection event for consumer " + consumerId + ": " + e.getMessage());
            e.printStackTrace();
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
                break;
        }
    }
}