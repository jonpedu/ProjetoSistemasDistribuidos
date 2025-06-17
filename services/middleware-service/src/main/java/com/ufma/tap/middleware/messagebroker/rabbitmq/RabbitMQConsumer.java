// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/messagebroker/rabbitmq/RabbitMQConsumer.java
package com.ufma.tap.middleware.messagebroker.rabbitmq;

import com.google.gson.Gson;
import com.ufma.tap.middleware.model.Broker;
import com.ufma.tap.middleware.model.Consumer;
import com.ufma.tap.middleware.model.Message;
import com.ufma.tap.middleware.exception.BrokerStrategyIncompatibleException;
import com.ufma.tap.middleware.messagebroker.IConsumerMessaging;
import org.springframework.amqp.AmqpException;
import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.listener.SimpleMessageListenerContainer;
import org.springframework.amqp.rabbit.listener.adapter.MessageListenerAdapter; // <<< Import alterado/adicionado
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;

import java.io.IOException; // Adicionar se não estiver presente
import java.nio.charset.StandardCharsets;
import java.util.Date; // Adicionar se não estiver presente
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
//import java.util.function.Consumer; // A interface funcional, como discutido

@Component
@Qualifier("rabbitMQConsumer")
public class RabbitMQConsumer implements IConsumerMessaging {

    @Autowired
    private AmqpAdmin amqpAdmin;

    @Autowired
    private ConnectionFactory rabbitConnectionFactory;

    private final Gson gson = new Gson();

    private final Map<String, SimpleMessageListenerContainer> listenerContainers = new ConcurrentHashMap<>();
    private final Map<String, String> declaredExchanges = new ConcurrentHashMap<>();

    @Override
    public void connectAndListen(com.ufma.tap.middleware.model.Consumer consumer, java.util.function.Consumer<Message> messageHandler) {
        if (listenerContainers.containsKey(consumer.getId())) {
            SimpleMessageListenerContainer oldContainer = listenerContainers.get(consumer.getId());
            oldContainer.stop();
            listenerContainers.remove(consumer.getId());
            System.out.println("Stopped existing RabbitMQ listener for consumer: " + consumer.getId());
        }

        validateBrokerConfiguration(consumer);

        String exchangeName = consumer.getExchange();
        String strategy = consumer.getStrategy();
        String queueName = consumer.getQueue();
        String routingKey = consumer.getRoutingKey();
        Map<String, Object> headersMap = gson.fromJson(consumer.getHeaders(), Map.class);

        try {
            declareExchangeOnce(exchangeName, strategy);

            Queue queue = new Queue(queueName, true, false, false);
            amqpAdmin.declareQueue(queue);

            Binding binding;
            switch (strategy) {
                case "direct":
                    routingKey = (routingKey != null && !routingKey.isEmpty()) ? routingKey : queueName;
                    binding = BindingBuilder.bind(queue).to(new DirectExchange(exchangeName)).with(routingKey);
                    break;
                case "topic":
                    if (routingKey == null || routingKey.isEmpty()) {
                        throw new BrokerStrategyIncompatibleException("Routing Key is required for 'topic' strategy.");
                    }
                    binding = BindingBuilder.bind(queue).to(new TopicExchange(exchangeName)).with(routingKey);
                    break;
                case "fanout":
                    binding = BindingBuilder.bind(queue).to(new FanoutExchange(exchangeName));
                    break;
                case "headers":
                    if (headersMap == null || headersMap.isEmpty()) {
                        throw new BrokerStrategyIncompatibleException("Headers are required for 'headers' strategy.");
                    }
                    binding = BindingBuilder.bind(queue).to(new HeadersExchange(exchangeName)).whereAny(headersMap).match();
                    break;
                default:
                    throw new BrokerStrategyIncompatibleException("Strategy '" + strategy + "' not supported by RabbitMQ.");
            }
            amqpAdmin.declareBinding(binding);

            SimpleMessageListenerContainer container = new SimpleMessageListenerContainer();
            container.setConnectionFactory(rabbitConnectionFactory);
            container.setQueueNames(queueName);
            container.setAcknowledgeMode(AcknowledgeMode.AUTO);

            // --- MODIFICAÇÃO AQUI ---
            // Usando MessageListenerAdapter para encapsular o onMessage
            MessageListenerAdapter messageListenerAdapter = new MessageListenerAdapter(new Object() {
                // Método que será invocado quando uma mensagem for recebida
                // O nome 'handleMessage' é o padrão, mas pode ser configurado
                @SuppressWarnings("unused") // Usado pelo Spring AMQP, mas não diretamente no código
                public void handleMessage(org.springframework.amqp.core.Message springAmqpMessage) {
                    try {
                        String messageBody = new String(springAmqpMessage.getBody(), StandardCharsets.UTF_8);
                        Message receivedMessage = gson.fromJson(messageBody, Message.class);

                        receivedMessage.setConsumerId(consumer.getId());
                        receivedMessage.setQueue(queueName);

                        if (consumer.getPersistenceTime() != null && consumer.getPersistenceTime() > 0) {
                            long expireTimeMillis = System.currentTimeMillis() + consumer.getPersistenceTime();
                            if (expireTimeMillis < 0) {
                                expireTimeMillis = Long.MAX_VALUE;
                            }
                            receivedMessage.setExpireAt(new Date(expireTimeMillis));
                        } else {
                            receivedMessage.setExpireAt(null);
                        }

                        messageHandler.accept(receivedMessage);
                    } catch (Exception e) {
                        System.err.println("Error processing RabbitMQ message for consumer " + consumer.getId() + ": " + e.getMessage());
                    }
                }
            });
            container.setMessageListener(messageListenerAdapter); // <<< Atribui o adapter

            container.start();
            listenerContainers.put(consumer.getId(), container);

            System.out.println("RabbitMQ Consumer " + consumer.getId() + " connected and listening on queue: " + queueName);

        } catch (AmqpException e) {
            throw new RuntimeException("Failed to connect RabbitMQ Consumer: " + e.getMessage(), e);
        }
    }

    @Override
    public void close(String consumerId) {
        SimpleMessageListenerContainer container = listenerContainers.remove(consumerId);
        if (container != null) {
            container.stop();
            System.out.println("RabbitMQ Consumer " + consumerId + " listener stopped.");
        }
    }

    private void validateBrokerConfiguration(Consumer consumer) {
        if (consumer.getExchange() == null || consumer.getExchange().isEmpty()) {
            throw new BrokerStrategyIncompatibleException("Exchange name is required for all RabbitMQ strategies.");
        }
        if (consumer.getQueue() == null || consumer.getQueue().isEmpty()) {
            throw new BrokerStrategyIncompatibleException("Queue name is required for all RabbitMQ strategies.");
        }

        switch (consumer.getStrategy()) {
            case "direct":
                break;
            case "topic":
                if (consumer.getRoutingKey() == null || consumer.getRoutingKey().isEmpty()) {
                    throw new BrokerStrategyIncompatibleException("Routing Key is mandatory for 'topic' strategy.");
                }
                break;
            case "fanout":
                break;
            case "headers":
                if (consumer.getHeaders() == null || consumer.getHeaders().isEmpty()) {
                    throw new BrokerStrategyIncompatibleException("Headers are mandatory for 'headers' strategy.");
                }
                try {
                    gson.fromJson(consumer.getHeaders(), Map.class);
                } catch (Exception e) {
                    throw new BrokerStrategyIncompatibleException("Headers must be a valid JSON string for 'headers' strategy.");
                }
                break;
            default:
                throw new BrokerStrategyIncompatibleException("Invalid strategy for RabbitMQ: " + consumer.getStrategy());
        }
    }

    private void declareExchangeOnce(String exchangeName, String strategy) {
        if (declaredExchanges.containsKey(exchangeName)) {
            if (!declaredExchanges.get(exchangeName).equals(strategy)) {
                throw new AmqpException("Exchange '" + exchangeName + "' already exists with a different type: " + declaredExchanges.get(exchangeName));
            }
            return;
        }

        Exchange exchange;
        switch (strategy) {
            case "direct":
                exchange = new DirectExchange(exchangeName);
                break;
            case "topic":
                exchange = new TopicExchange(exchangeName);
                break;
            case "fanout":
                exchange = new FanoutExchange(exchangeName);
                break;
            case "headers":
                exchange = new HeadersExchange(exchangeName);
                break;
            default:
                throw new BrokerStrategyIncompatibleException("Unknown exchange strategy: " + strategy);
        }
        amqpAdmin.declareExchange(exchange);
        declaredExchanges.put(exchangeName, strategy);
    }
}