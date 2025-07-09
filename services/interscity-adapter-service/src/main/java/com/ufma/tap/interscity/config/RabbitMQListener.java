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

    private static final String TARGET_QUEUE = "interscity.adapter.queue";
    private static final String TARGET_EXCHANGE = "interscity.adapter.exchange";
    private static final String ROUTING_KEY = "interscity.adapter.key";

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
        System.out.println("🔄 [INTERSCITY ADAPTER] =====================================================");
        System.out.println("📥 [INTERSCITY ADAPTER] MENSAGEM RECEBIDA DO MIDDLEWARE!");
        System.out.println("📋 [INTERSCITY ADAPTER] Fila: " + TARGET_QUEUE);
        System.out.println("📋 [INTERSCITY ADAPTER] Exchange: " + TARGET_EXCHANGE);
        System.out.println("📋 [INTERSCITY ADAPTER] Routing Key: " + ROUTING_KEY);
        System.out.println("📋 [INTERSCITY ADAPTER] Payload recebido: " + messageJson);
        System.out.println("🚀 [INTERSCITY ADAPTER] Iniciando processamento para InterSCity...");

        try {
            // Reativando a chamada para o serviço que se conecta ao InterSCity
            interScityService.registerResource(messageJson);
            System.out.println("✅ [INTERSCITY ADAPTER] Mensagem processada com sucesso!");
        } catch (Exception e) {
            System.err.println("❌ [INTERSCITY ADAPTER] FALHA AO ENVIAR PARA O INTERSCITY!");
            System.err.println("❌ [INTERSCITY ADAPTER] Erro: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("🔄 [INTERSCITY ADAPTER] =====================================================");
    }
}