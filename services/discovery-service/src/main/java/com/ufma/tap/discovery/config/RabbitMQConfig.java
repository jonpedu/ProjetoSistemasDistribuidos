// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/config/RabbitMQConfig.java
package com.ufma.tap.discovery.config;

import com.google.gson.Gson;
import com.ufma.tap.discovery.dto.ConsumerConnectionEvent;
import com.ufma.tap.discovery.service.IDiscoveryService;
import org.springframework.amqp.core.AmqpAdmin;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange; // Usaremos TopicExchange para eventos
import org.springframework.amqp.rabbit.annotation.RabbitListener; // Import necessário
import org.springframework.amqp.rabbit.connection.CachingConnectionFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.context.annotation.Primary;

@Configuration
public class RabbitMQConfig {

    @Value("${spring.rabbitmq.host}")
    private String rabbitmqHost;

    @Value("${spring.rabbitmq.port}")
    private int rabbitmqPort;

    @Value("${spring.rabbitmq.username}")
    private String rabbitmqUsername;

    @Value("${spring.rabbitmq.password}")
    private String rabbitmqPassword;

    // Fila e Exchange para eventos de conexão de consumidores
    public static final String CONSUMER_CONNECTION_QUEUE = "consumer_connection_queue";
    public static final String CONSUMER_CONNECTION_EXCHANGE = "consumer.connection.events";
    public static final String CONSUMER_CONNECTION_ROUTING_KEY = "consumer.connection.*"; // Rotas para "connected", "disconnected"

    @Autowired
    private IDiscoveryService discoveryService;

    private final Gson gson = new Gson();

    @Bean
    public ConnectionFactory connectionFactory() {
        CachingConnectionFactory connectionFactory = new CachingConnectionFactory(rabbitmqHost);
        connectionFactory.setPort(rabbitmqPort);
        connectionFactory.setUsername(rabbitmqUsername);
        connectionFactory.setPassword(rabbitmqPassword);
        return connectionFactory;
    }

    @Bean
    public AmqpAdmin amqpAdmin(ConnectionFactory connectionFactory) {
        return new RabbitAdmin(connectionFactory);
    }

    @Bean
    @Primary
    public AmqpTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        return new RabbitTemplate(connectionFactory);
    }

    // Declara a fila, o exchange e o binding para eventos de conexão de consumidores
    @Bean
    Queue consumerConnectionQueue() {
        return new Queue(CONSUMER_CONNECTION_QUEUE, true); // Durável
    }

    @Bean
    TopicExchange consumerConnectionExchange() {
        return new TopicExchange(CONSUMER_CONNECTION_EXCHANGE);
    }

    @Bean
    Binding consumerConnectionBinding(Queue consumerConnectionQueue, TopicExchange consumerConnectionExchange) {
        return BindingBuilder.bind(consumerConnectionQueue).to(consumerConnectionExchange).with(CONSUMER_CONNECTION_ROUTING_KEY);
    }

    // Listener para eventos de conexão de consumidores do middleware-service
    @RabbitListener(queues = CONSUMER_CONNECTION_QUEUE)
    public void handleConsumerConnectionEvent(String message) {
        try {
            ConsumerConnectionEvent event = gson.fromJson(message, ConsumerConnectionEvent.class);
            discoveryService.handleConsumerConnectionEvent(event);
        } catch (Exception e) {
            System.err.println("Error processing RabbitMQ consumer connection event: " + e.getMessage());
            e.printStackTrace();
            // Em produção, você pode querer logar mais detalhes ou enviar para uma DLQ (Dead Letter Queue)
        }
    }
}