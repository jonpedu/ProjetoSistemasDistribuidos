// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/MessageReceived.java
package com.ufma.tap.middleware.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotBlank;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageReceived {
    @NotBlank(message = "Message data cannot be empty")
    private String data; // Conteúdo da mensagem

    // Campos opcionais para sobrescrever a configuração do produtor
    private String strategy;
    private String exchange;
    private String queue;
    private String routingKey;
    private Map<String, Object> headers; // Para headers AMQP/MQTT
    private Long timeToWait; // Para envio com atraso (futuro)
}