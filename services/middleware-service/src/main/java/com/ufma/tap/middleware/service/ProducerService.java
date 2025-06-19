// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/service/ProducerService.java
package com.ufma.tap.middleware.service;

import com.google.gson.Gson;
import com.ufma.tap.middleware.auth.BasicAuthUtil; // Utilitário de autenticação básica
import com.ufma.tap.middleware.model.Producer;
import com.ufma.tap.middleware.model.Broker; // Model POJO para configurações de broker
import com.ufma.tap.middleware.model.MessageToSend; // Model POJO para mensagem a ser enviada
import com.ufma.tap.middleware.repository.ProducerRepository;
import com.ufma.tap.middleware.security.JWTUtil;
import com.ufma.tap.middleware.messagebroker.IProducerMessaging;
import com.ufma.tap.middleware.dto.MessageReceived;
import com.ufma.tap.middleware.dto.ProducerDto;
import com.ufma.tap.middleware.dto.StrategyUpdate;
import com.ufma.tap.middleware.dto.QueueUpdate;
import com.ufma.tap.middleware.dto.BrokerUpdate;
import com.ufma.tap.middleware.exception.InvalidCredentialsException;
import com.ufma.tap.middleware.exception.ProducerNotFoundException;
import com.ufma.tap.middleware.exception.UserConflictException;
import com.ufma.tap.middleware.exception.BrokerNotSupportedException;
import com.ufma.tap.middleware.exception.BrokerStrategyIncompatibleException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Service
public class ProducerService implements IProducerService {

    @Autowired
    private ProducerRepository producerRepository;

    @Autowired
    private JWTUtil jwtUtil;

    @Autowired
    private BasicAuthUtil basicAuthUtil; // Para decodificar credenciais básicas

    // Injetando as implementações específicas de produtores
    @Autowired
    @Qualifier("rabbitMQProducer")
    private IProducerMessaging rabbitMQProducer;

    // TODO: Adicionar @Autowired @Qualifier para KafkaProducer, ActiveMQ5Producer quando implementados
    // @Autowired
    // @Qualifier("kafkaProducer")
    // private IProducerMessaging kafkaProducer;

    private final Set<String> GLOBAL_SUPPORTED_BROKERS = Set.of("rabbitmq", "kafka", "activemq5");
    private final Gson gson = new Gson();

    @Override
    public ProducerDto registerProducer(Producer producer, String projectAuthToken) {
        // Validação do token do projeto (se necessário aqui, ou pode ser feito em um filtro de segurança global)
        // Assume que o projectAuthToken vem do registration-service e é válido para o projectId
        String projectId = jwtUtil.extractAllClaims(projectAuthToken.replace("Bearer ", "")).get("projectId", String.class);
        if (projectId == null) {
            throw new InvalidCredentialsException("Project token is invalid or missing ProjectId.");
        }

        if (producerRepository.existsByUsername(producer.getUsername())) {
            throw new UserConflictException("Producer with username '" + producer.getUsername() + "' already registered.");
        }

        if (!GLOBAL_SUPPORTED_BROKERS.contains(producer.getBroker().toLowerCase())) {
            throw new BrokerNotSupportedException("Broker '" + producer.getBroker() + "' is not globally supported.");
        }

        producer.setId(UUID.randomUUID().toString());
        producer.setProjectId(projectId); // Associa o produtor ao projeto validado pelo token

        // TODO: Criptografar a senha do produtor antes de salvar! (Usar BCryptPasswordEncoder)

        Producer savedProducer = producerRepository.save(producer);
        return ProducerDto.fromModel(savedProducer);
    }

    @Override
    public ProducerDto getProducer(String producerId, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        return ProducerDto.fromModel(producer);
    }

    @Override
    public void deleteProducer(String producerId, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        producerRepository.delete(producer);
    }

    @Override
    public void connectProducer(String producerId, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        // Conexão ao broker é tipicamente implícita no primeiro `send` ou no listener para consumidores.
        // Este método pode ser usado para inicializar recursos do broker que precisam ser mantidos abertos.
        Broker brokerConfig = buildBrokerConfig(producer);
        getProducerMessagingAdapter(producer.getBroker()).connect(brokerConfig);
        System.out.println("Producer " + producerId + " connected/validated to broker " + producer.getBroker());
    }

    @Override
    public void send(String producerId, MessageReceived messageReceived, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);

        // Prepara a MessageToSend com um novo MessageId
        MessageToSend messageToSend = new MessageToSend(UUID.randomUUID().toString(), messageReceived.getData(), messageReceived.getHeaders());
        // Se a mensagem recebida sobrescrever a estratégia/fila/exchange do produtor
        Broker brokerConfig = new Broker();
        brokerConfig.setName(producer.getBroker());
        brokerConfig.setStrategy(Optional.ofNullable(messageReceived.getStrategy()).orElse(producer.getStrategy()));
        brokerConfig.setExchange(Optional.ofNullable(messageReceived.getExchange()).orElse(producer.getExchange()));
        brokerConfig.setQueue(Optional.ofNullable(messageReceived.getQueue()).orElse(producer.getQueue()));
        brokerConfig.setRoutingKey(Optional.ofNullable(messageReceived.getRoutingKey()).orElse(producer.getRoutingKey()));
        brokerConfig.setHeaders(messageReceived.getHeaders() != null ? gson.toJson(messageReceived.getHeaders()) : producer.getHeaders()); // headers como JSON String

        // Verifica a compatibilidade da estratégia com o broker selecionado
        validateBrokerStrategy(brokerConfig.getName(), brokerConfig.getStrategy());

        // Envia a mensagem usando o adaptador apropriado
        getProducerMessagingAdapter(brokerConfig.getName()).send(messageToSend, brokerConfig);
    }

    @Override
    public void disconnectProducer(String producerId, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        getProducerMessagingAdapter(producer.getBroker()).close(producerId);
        System.out.println("Producer " + producerId + " disconnected from broker " + producer.getBroker());
    }

    @Override
    public ProducerDto setBroker(String producerId, BrokerUpdate brokerUpdate, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);

        if (!GLOBAL_SUPPORTED_BROKERS.contains(brokerUpdate.getBroker().toLowerCase())) {
            throw new BrokerNotSupportedException("Broker '" + brokerUpdate.getBroker() + "' is not globally supported.");
        }
        validateBrokerStrategy(brokerUpdate.getBroker(), brokerUpdate.getStrategy()); // Validar nova estratégia

        producer.setBroker(brokerUpdate.getBroker());
        producer.setStrategy(brokerUpdate.getStrategy());
        producer.setExchange(brokerUpdate.getExchange());
        producer.setQueue(brokerUpdate.getQueue());
        producer.setRoutingKey(brokerUpdate.getRoutingKey());
        producer.setHeaders(brokerUpdate.getHeaders() != null ? gson.toJson(brokerUpdate.getHeaders()) : null);

        return ProducerDto.fromModel(producerRepository.save(producer));
    }

    @Override
    public ProducerDto setStrategy(String producerId, StrategyUpdate strategyUpdate, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        validateBrokerStrategy(producer.getBroker(), strategyUpdate.getStrategy()); // Validar nova estratégia

        producer.setStrategy(strategyUpdate.getStrategy());
        producer.setExchange(strategyUpdate.getExchange());
        producer.setQueue(strategyUpdate.getQueue());
        producer.setRoutingKey(strategyUpdate.getRoutingKey());
        producer.setHeaders(strategyUpdate.getHeaders() != null ? gson.toJson(strategyUpdate.getHeaders()) : null);

        return ProducerDto.fromModel(producerRepository.save(producer));
    }

    @Override
    public ProducerDto setQueue(String producerId, QueueUpdate queueUpdate, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        // Validar se a estratégia atual permite a alteração de fila/exchange/routingKey
        // Dependendo da estratégia, queue pode ser obrigatório
        producer.setQueue(queueUpdate.getQueue());
        producer.setExchange(queueUpdate.getExchange());
        producer.setRoutingKey(queueUpdate.getRoutingKey());
        producer.setHeaders(queueUpdate.getHeaders() != null ? gson.toJson(queueUpdate.getHeaders()) : null);

        return ProducerDto.fromModel(producerRepository.save(producer));
    }

    private Broker buildBrokerConfig(Producer producer) {
        Broker brokerConfig = new Broker();
        brokerConfig.setName(producer.getBroker());
        brokerConfig.setStrategy(producer.getStrategy());
        brokerConfig.setExchange(producer.getExchange());
        brokerConfig.setQueue(producer.getQueue());
        brokerConfig.setRoutingKey(producer.getRoutingKey());
        brokerConfig.setHeaders(producer.getHeaders()); // Já deve ser JSON String
        return brokerConfig;
    }


    // --- Métodos Auxiliares ---
    private Producer findAndValidateProducer(String producerId, String projectAuthToken) {
        Producer producer = producerRepository.findById(producerId)
                .orElseThrow(() -> new ProducerNotFoundException("Producer with ID '" + producerId + "' not found."));

        String projectIdFromToken = jwtUtil.extractAllClaims(projectAuthToken.replace("Bearer ", "")).get("projectId", String.class);
        if (projectIdFromToken == null || !producer.getProjectId().equals(projectIdFromToken)) {
            throw new InvalidCredentialsException("Unauthorized access to producer or invalid project token.");
        }
        return producer;
    }

    // Retorna a implementação correta de IProducerMessaging
    private IProducerMessaging getProducerMessagingAdapter(String brokerName) {
        switch (brokerName.toLowerCase()) {
            case "rabbitmq":
                return rabbitMQProducer;
            // TODO: Adicionar outros brokers quando implementados
            // case "kafka":
            //     return kafkaProducer;
            default:
                throw new BrokerNotSupportedException("Broker '" + brokerName + "' not supported by this service instance.");
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
            // TODO: Adicionar validações para outros brokers
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

    // TODO: Adicionar o @Service e @Component para cada classe de DTO de atualização (BrokerUpdate, StrategyUpdate, QueueUpdate, PersistenceUpdate)
    // Para simplificar, vou manter apenas o StrategyUpdate como exemplo no código DTOs abaixo.

}