// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/service/ProducerService.java
package com.ufma.tap.middleware.service;

import com.google.gson.Gson;
import com.ufma.tap.middleware.auth.BasicAuthUtil;
import com.ufma.tap.middleware.model.Producer;
import com.ufma.tap.middleware.model.Broker;
import com.ufma.tap.middleware.model.MessageToSend;
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
import org.springframework.amqp.core.AmqpAdmin; // Import para AmqpAdmin
import org.springframework.amqp.core.DirectExchange; // Import para DirectExchange
import org.springframework.amqp.core.BindingBuilder; // Import para BindingBuilder
import org.springframework.amqp.core.Queue; // Import para Queue
import org.springframework.amqp.core.Binding; // Import para Binding
import org.springframework.amqp.core.AmqpTemplate; // Import para AmqpTemplate (se usar diretamente no send)


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
    private BasicAuthUtil basicAuthUtil;

    @Autowired
    private AmqpTemplate rabbitTemplate; // Para enviar para o InterSCity Adapter

    @Autowired
    private AmqpAdmin amqpAdmin; // Para declarar filas/exchanges para o InterSCity Adapter

    // Injetando as implementações específicas de produtores
    @Autowired
    @Qualifier("rabbitMQProducer")
    private IProducerMessaging rabbitMQProducer;

    // Constantes para o InterSCity Adapter (devem ser as mesmas do interscity-adapter-service/config/RabbitMQConfig.java)
    private static final String INTERSCITY_ADAPTER_QUEUE = "interscity.adapter.queue";
    private static final String INTERSCITY_ADAPTER_EXCHANGE = "interscity.adapter.exchange";
    private static final String INTERSCITY_ADAPTER_ROUTING_KEY = "interscity.adapter.key";
    private static final String INTERSCITY_ADAPTER_STRATEGY_NAME = "interscity-adapter-strategy";


    private final Set<String> GLOBAL_SUPPORTED_BROKERS = Set.of("rabbitmq", "kafka", "activemq5", "interscity-adapter"); // Adicionado "interscity-adapter"
    private final Gson gson = new Gson();

    @Override
    public ProducerDto registerProducer(Producer producer, String projectAuthToken) {
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
        producer.setProjectId(projectId);

        // TODO: (Futuro) Criptografar a senha do produtor antes de salvar! (Usar BCryptPasswordEncoder)

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
        // A conexão ao broker é tipicamente implícita no primeiro `send` ou no listener para consumidores.
        // Este método pode ser usado para inicializar recursos do broker que precisam ser mantidos abertos
        // para adaptadores específicos (ex: InterSCity Adapter).
        // Se o produtor for para o InterSCity Adapter, declaramos as queues/exchanges necessárias.
        if (INTERSCITY_ADAPTER_STRATEGY_NAME.equals(producer.getBroker())) {
            declareInterscityAdapterQueueAndExchange();
            System.out.println("Producer " + producerId + " (InterSCity Adapter) resources declared.");
        } else {
            Broker brokerConfig = buildBrokerConfig(producer);
            getProducerMessagingAdapter(producer.getBroker()).connect(brokerConfig);
            System.out.println("Producer " + producerId + " connected/validated to broker " + producer.getBroker());
        }
    }

    @Override
    public void send(String producerId, MessageReceived messageReceived, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);

        // Prepara a MessageToSend com um novo MessageId
        MessageToSend messageToSend = new MessageToSend(UUID.randomUUID().toString(), messageReceived.getData(), messageReceived.getHeaders());

        // Constrói a configuração do broker para o envio
        Broker brokerConfig = new Broker();
        brokerConfig.setName(producer.getBroker());
        brokerConfig.setStrategy(Optional.ofNullable(messageReceived.getStrategy()).orElse(producer.getStrategy()));
        brokerConfig.setExchange(Optional.ofNullable(messageReceived.getExchange()).orElse(producer.getExchange()));
        brokerConfig.setQueue(Optional.ofNullable(messageReceived.getQueue()).orElse(producer.getQueue()));
        brokerConfig.setRoutingKey(Optional.ofNullable(messageReceived.getRoutingKey()).orElse(producer.getRoutingKey()));
        brokerConfig.setHeaders(messageReceived.getHeaders() != null ? gson.toJson(messageReceived.getHeaders()) : producer.getHeaders());

        // Verifica a compatibilidade da estratégia com o broker selecionado
        validateBrokerStrategy(brokerConfig.getName(), brokerConfig.getStrategy());

        // --- Lógica para rotear para o InterSCity Adapter ou para o broker padrão ---
        if (INTERSCITY_ADAPTER_STRATEGY_NAME.equals(brokerConfig.getStrategy())) {
            // Se a mensagem for destinada ao InterSCity Adapter
            declareInterscityAdapterQueueAndExchange(); // Garante que a infra RabbitMQ está pronta
            String messageJson = gson.toJson(messageToSend); // Serializa MessageToSend completo
            rabbitTemplate.convertAndSend(INTERSCITY_ADAPTER_EXCHANGE, INTERSCITY_ADAPTER_ROUTING_KEY, messageJson);
            System.out.println("Message sent to InterSCity Adapter via RabbitMQ: " + messageToSend.getMessageId());
        } else {
            // Envia a mensagem usando o adaptador apropriado para o broker padrão (ex: RabbitMQ, Kafka)
            getProducerMessagingAdapter(brokerConfig.getName()).send(messageToSend, brokerConfig);
        }
    }

    @Override
    public void disconnectProducer(String producerId, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);
        // Se for um produtor para InterSCity Adapter, não há conexão persistente para fechar aqui
        if (!INTERSCITY_ADAPTER_STRATEGY_NAME.equals(producer.getBroker())) {
            getProducerMessagingAdapter(producer.getBroker()).close(producerId);
        }
        System.out.println("Producer " + producerId + " disconnected from broker " + producer.getBroker());
    }

    @Override
    public ProducerDto setBroker(String producerId, BrokerUpdate brokerUpdate, String projectAuthToken) {
        Producer producer = findAndValidateProducer(producerId, projectAuthToken);

        if (!GLOBAL_SUPPORTED_BROKERS.contains(brokerUpdate.getBroker().toLowerCase())) {
            throw new BrokerNotSupportedException("Broker '" + brokerUpdate.getBroker() + "' is not globally supported.");
        }
        validateBrokerStrategy(brokerUpdate.getBroker(), brokerUpdate.getStrategy());

        producer.setBroker(brokerUpdate.getBroker());
        producer.setStrategy(brokerUpdate.getStrategy());
        producer.setExchange(brokerUpdate.getExchange());
        producer.setQueue(brokerUpdate.getQueue());
        producer.setRoutingKey(brokerUpdate.getRoutingKey());
        producer.setHeaders(brokerUpdate.getHeaders() != null ? gson.toJson(brokerUpdate.getHeaders()) : null);

        // Se o novo broker for InterSCity Adapter, declare seus recursos RabbitMQ
        if (INTERSCITY_ADAPTER_STRATEGY_NAME.equals(producer.getBroker())) {
            declareInterscityAdapterQueueAndExchange();
        }

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
        // Garanta que `getHeaders()` sempre retorne JSON String ou null
        brokerConfig.setHeaders(producer.getHeaders());
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
            // TODO: (Futuro) Adicionar outros brokers quando implementados (Kafka, ActiveMQ5)
            // case "kafka":
            //     return kafkaProducer;
            // case "activemq5":
            //     return activeMQ5Producer;
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
            case "activemq5":
                if (!Set.of("direct", "topic").contains(strategy.toLowerCase())) {
                    throw new BrokerStrategyIncompatibleException("ActiveMQ5 only supports 'direct' and 'topic' strategies.");
                }
                break;
            case INTERSCITY_ADAPTER_STRATEGY_NAME: // A estratégia para rotear para o InterSCity Adapter
                // Se o broker é o InterSCity Adapter, a única estratégia válida é a dele
                if (!INTERSCITY_ADAPTER_STRATEGY_NAME.equals(strategy.toLowerCase())) {
                    throw new BrokerStrategyIncompatibleException("InterSCity Adapter only supports '" + INTERSCITY_ADAPTER_STRATEGY_NAME + "' strategy.");
                }
                break;
            default:
                // Já tratado por BrokerNotSupportedException
                break;
        }
    }

    // --- NOVO MÉTODO AUXILIAR PARA DECLARAR RECURSOS DO RABBITMQ PARA O INTERSCITY ADAPTER ---
    private void declareInterscityAdapterQueueAndExchange() {
        // Declara a fila
        Queue interscityQueue = new Queue(INTERSCITY_ADAPTER_QUEUE, true); // Durável
        amqpAdmin.declareQueue(interscityQueue);

        // Declara o exchange (DirectExchange, conforme o RabbitMQConfig do interscity-adapter-service)
        DirectExchange interscityExchange = new DirectExchange(INTERSCITY_ADAPTER_EXCHANGE);
        amqpAdmin.declareExchange(interscityExchange);

        // Declara o binding
        Binding binding = BindingBuilder.bind(interscityQueue).to(interscityExchange).with(INTERSCITY_ADAPTER_ROUTING_KEY);
        amqpAdmin.declareBinding(binding);
        System.out.println("Declared RabbitMQ resources for InterSCity Adapter.");
    }

}