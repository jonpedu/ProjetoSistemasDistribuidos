// Caminho: services/interscity-adapter-service/src/main/java/com/ufma/tap/interscity/config/RabbitMQListener.java

package com.ufma.tap.interscity.config;

import com.ufma.tap.interscity.service.InterScityService;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;

@Component
public class RabbitMQListener {

    @Autowired
    private InterScityService interScityService; // <-- Reativando a injeção

    private static final String TARGET_QUEUE = "queue.tasks.new";
    private static final String TARGET_EXCHANGE = "exchange.direct.tasks";
    private static final String ROUTING_KEY = "queue.tasks.new";

    @Bean
    public Queue targetQueue() {
        return new Queue(TARGET_QUEUE, true);
    }

    @Bean
    public DirectExchange targetExchange() {
        return new DirectExchange(TARGET_EXCHANGE);
    }

    @Bean
    public Binding binding(Queue targetQueue, DirectExchange targetExchange) {
        return BindingBuilder.bind(targetQueue).to(targetExchange).with(ROUTING_KEY);
    }

    @RabbitListener(queues = TARGET_QUEUE)
    public void receiveMessage(String messageJson) {
        // Bloco de código final e completo
        System.out.println("=====================================================");
        System.out.println("MENSAGEM RECEBIDA PELO ADAPTADOR! Payload: " + messageJson);
        System.out.println("-> Tentando enviar para o InterSCity...");

        try {
            // Reativando a chamada para o serviço que se conecta ao InterSCity
            interScityService.registerResource(messageJson);
        } catch (Exception e) {
            System.err.println("### FALHA AO ENVIAR PARA O INTERSCITY ### -> " + e.getMessage());
        }
    }
}