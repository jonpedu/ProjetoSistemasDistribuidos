// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/messagebroker/rabbitmq/RabbitMQProducer.java
package com.ufma.tap.middleware.messagebroker.rabbitmq;

import com.google.gson.Gson;
import com.ufma.tap.middleware.model.Broker;
import com.ufma.tap.middleware.model.MessageToSend;
import com.ufma.tap.middleware.messagebroker.IProducerMessaging;
import com.ufma.tap.middleware.exception.BrokerStrategyIncompatibleException; // Exceção personalizada
import com.ufma.tap.middleware.exception.MessageSendException; // Nova exceção para falhas no envio
import org.springframework.amqp.core.*; // Importa todas as classes core do AMQP (Exchange, Queue, Binding etc.)
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.amqp.AmqpException;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Qualifier("rabbitMQProducer") // Qualificador para injeção de dependência no ProducerService
public class RabbitMQProducer implements IProducerMessaging {

    @Autowired
    private AmqpTemplate rabbitTemplate; // Para operações de envio (convertAndSend)

    @Autowired
    private AmqpAdmin amqpAdmin; // Para operações administrativas (declarar exchanges, queues, bindings)

    private final Gson gson = new Gson();

    // Cache para exchanges já declarados (nome -> tipo). Evita redeclarações que podem causar conflitos.
    private final Map<String, String> declaredExchanges = new ConcurrentHashMap<>();

    @Override
    public void connect(Broker broker) {
        // A conexão é gerenciada automaticamente pelo Spring AMQP através das configurações em application.properties.
        // Este método pode ser usado para pré-validar configurações ou estabelecer conexões adicionais se necessário.
        System.out.println("RabbitMQProducer connected/validated for broker: " + broker.getName());
    }

    @Override
    public void send(MessageToSend messageToSend, Broker broker) {
        // 1. Validar a estratégia e os parâmetros do broker
        validateBrokerConfiguration(broker);

        String exchangeName = broker.getExchange();
        String strategy = broker.getStrategy();
        String queueName = broker.getQueue();
        String routingKey = broker.getRoutingKey();
        Map<String, Object> headersMap = gson.fromJson(broker.getHeaders(), Map.class); // Converte JSON String para Map

        try {
            // 2. Declarar o Exchange (se ainda não declarado ou se o tipo mudou)
            declareExchangeOnce(exchangeName, strategy);

            // 3. Declarar a Fila (se ainda não declarada)
            Queue queue = new Queue(queueName, true, false, false); // Nome, durável, não exclusiva, não auto-delete
            amqpAdmin.declareQueue(queue);

            // 4. Declarar o Binding entre Exchange e Fila
            Binding binding;
            switch (strategy) {
                case "direct":
                    routingKey = (routingKey != null && !routingKey.isEmpty()) ? routingKey : queueName; // Default routing key is queue name
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

            // 5. Converter a mensagem para JSON e enviar
            String messageJson = gson.toJson(messageToSend);
            if ("fanout".equals(strategy) || "headers".equals(strategy)) {
                // Fanout e Headers exchanges não usam routing key no convertAndSend diretamente
                rabbitTemplate.convertAndSend(exchangeName, "", messageJson, message -> {
                    // Para headers exchange, os headers precisam ser adicionados ao MessageProperties
                    if ("headers".equals(strategy) && headersMap != null) {
                        message.getMessageProperties().setHeaders(headersMap);
                    }
                    return message;
                });
            } else {
                rabbitTemplate.convertAndSend(exchangeName, routingKey, messageJson);
            }

            System.out.println("Message sent to RabbitMQ: " + messageToSend.getMessageId() + " via exchange: " + exchangeName + ", strategy: " + strategy);

        } catch (AmqpException e) {
            throw new MessageSendException("Failed to send message to RabbitMQ: " + e.getMessage(), e);
        }
    }

    @Override
    public void close(String producerId) {
        // Para RabbitMQ com Spring AMQP, as conexões são gerenciadas pelo container.
        // Uma desconexão explícita geralmente não é necessária para cada produtor individual,
        // a menos que você esteja fechando um canal ou conexão específica de forma manual.
        System.out.println("RabbitMQProducer close operation for producer: " + producerId + " (managed by Spring AMQP)");
    }

    private void validateBrokerConfiguration(Broker broker) {
        // Validações de campos obrigatórios com base na estratégia do RabbitMQ
        if (broker.getExchange() == null || broker.getExchange().isEmpty()) {
            throw new BrokerStrategyIncompatibleException("Exchange name is required for all RabbitMQ strategies.");
        }
        if (broker.getQueue() == null || broker.getQueue().isEmpty()) {
            throw new BrokerStrategyIncompatibleException("Queue name is required for all RabbitMQ strategies.");
        }

        switch (broker.getStrategy()) {
            case "direct":
                // Routing key é opcional (usa nome da fila)
                break;
            case "topic":
                if (broker.getRoutingKey() == null || broker.getRoutingKey().isEmpty()) {
                    throw new BrokerStrategyIncompatibleException("Routing Key is mandatory for 'topic' strategy.");
                }
                break;
            case "fanout":
                // Não usa routing key
                break;
            case "headers":
                if (broker.getHeaders() == null || broker.getHeaders().isEmpty()) {
                    throw new BrokerStrategyIncompatibleException("Headers are mandatory for 'headers' strategy.");
                }
                // Adicionalmente, tentar desserializar headers para garantir que é um JSON válido
                try {
                    gson.fromJson(broker.getHeaders(), Map.class);
                } catch (Exception e) {
                    throw new BrokerStrategyIncompatibleException("Headers must be a valid JSON string for 'headers' strategy.");
                }
                break;
            default:
                throw new BrokerStrategyIncompatibleException("Invalid strategy for RabbitMQ: " + broker.getStrategy());
        }
    }

    // Garante que o exchange seja declarado apenas uma vez e com o tipo correto
    private void declareExchangeOnce(String exchangeName, String strategy) {
        // Verifica se o exchange já foi declarado por esta instância do produtor
        if (declaredExchanges.containsKey(exchangeName)) {
            // Se já foi declarado, verifica se o tipo é consistente
            if (!declaredExchanges.get(exchangeName).equals(strategy)) {
                throw new AmqpException("Exchange '" + exchangeName + "' already exists with a different type: " + declaredExchanges.get(exchangeName));
            }
            return; // Já está declarado e consistente
        }

        // Tenta declarar o exchange. Se já existir com o mesmo tipo, não haverá erro.
        // Se já existir com tipo diferente, o amqpAdmin.declareExchange lançará uma exceção.
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
        declaredExchanges.put(exchangeName, strategy); // Adiciona ao cache local
    }
}