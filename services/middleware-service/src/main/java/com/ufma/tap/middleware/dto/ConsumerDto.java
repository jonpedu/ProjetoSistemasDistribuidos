// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/ConsumerDto.java
package com.ufma.tap.middleware.dto;

import com.ufma.tap.middleware.model.Consumer;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConsumerDto {
    private String id;

    @NotBlank(message = "Username cannot be empty")
    @Size(min = 8, max = 32, message = "Username must be between 8 and 32 characters")
    @Pattern(regexp = "^[a-zA-Z0-9]+$", message = "Username must be alphanumeric")
    private String username;

    @NotBlank(message = "Password cannot be empty")
    @Size(min = 8, max = 64, message = "Password must be between 8 and 64 characters")
    @Pattern(regexp = "^[a-zA-Z0-9./#$|-]+$", message = "Password can only contain alphanumeric characters and ./#$|-")
    private String password;

    @NotNull(message = "Persistence time cannot be null")
    @Min(value = 0, message = "Persistence time must be non-negative")
    private Long persistenceTime; // Em milissegundos

    @NotBlank(message = "Broker name cannot be empty")
    private String broker; // Ex: "rabbitmq", "kafka"

    @NotBlank(message = "Strategy cannot be empty")
    private String strategy; // Ex: "direct", "topic", "fanout", "headers"

    @NotBlank(message = "Queue name cannot be empty") // Queue é obrigatório para consumidor
    private String queue;

    // Estes campos são opcionais para o DTO de entrada (PUT)
    private String exchange;
    private String routingKey;
    private String headers; // JSON String

    // Métodos de conversão
    public Consumer toModel() {
        Consumer consumer = new Consumer();
        consumer.setId(this.id);
        consumer.setUsername(this.username);
        consumer.setPassword(this.password);
        consumer.setPersistenceTime(this.persistenceTime);
        consumer.setBroker(this.broker);
        consumer.setStrategy(this.strategy);
        consumer.setQueue(this.queue);
        consumer.setExchange(this.exchange);
        consumer.setRoutingKey(this.routingKey);
        consumer.setHeaders(this.headers);
        return consumer;
    }

    public static ConsumerDto fromModel(Consumer consumer) {
        ConsumerDto dto = new ConsumerDto();
        dto.setId(consumer.getId());
        dto.setUsername(consumer.getUsername());
        dto.setPassword(null); // Nunca retorne a senha
        dto.setPersistenceTime(consumer.getPersistenceTime());
        dto.setBroker(consumer.getBroker());
        dto.setStrategy(consumer.getStrategy());
        dto.setQueue(consumer.getQueue());
        dto.setExchange(consumer.getExchange());
        dto.setRoutingKey(consumer.getRoutingKey());
        dto.setHeaders(consumer.getHeaders());
        return dto;
    }
}