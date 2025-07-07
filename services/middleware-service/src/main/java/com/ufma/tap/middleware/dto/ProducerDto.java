// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/ProducerDto.java
package com.ufma.tap.middleware.dto;

import com.ufma.tap.middleware.model.Producer;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProducerDto {
    private String id;

    @NotBlank(message = "Username cannot be empty")
    @Size(min = 8, max = 32, message = "Username must be between 8 and 32 characters")
    @Pattern(regexp = "^[a-zA-Z0-9]+$", message = "Username must be alphanumeric")
    private String username;

    @NotBlank(message = "Password cannot be empty")
    @Size(min = 8, max = 64, message = "Password must be between 8 and 64 characters")
    @Pattern(regexp = "^[a-zA-Z0-9./#$|-]+$", message = "Password can only contain alphanumeric characters and ./#$|-")
    private String password;

    private String description; // Descrição do produtor
    private String status; // Status do produtor

    @NotBlank(message = "Broker name cannot be empty")
    private String broker; // Ex: "rabbitmq", "kafka"

    @NotBlank(message = "Strategy cannot be empty")
    private String strategy; // Ex: "direct", "topic", "fanout", "headers"

    // Estes campos são opcionais, portanto, sem @NotBlank/@NotEmpty aqui
    private String exchange;
    private String queue;
    private String routingKey;
    private String headers; // JSON String

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Métodos de conversão
    public Producer toModel() {
        Producer producer = new Producer();
        producer.setId(this.id);
        producer.setUsername(this.username);
        producer.setPassword(this.password);
        producer.setDescription(this.description);
        producer.setStatus(this.status);
        producer.setBroker(this.broker);
        producer.setStrategy(this.strategy);
        producer.setExchange(this.exchange);
        producer.setQueue(this.queue);
        producer.setRoutingKey(this.routingKey);
        producer.setHeaders(this.headers);
        producer.setCreatedAt(this.createdAt);
        producer.setUpdatedAt(this.updatedAt);
        // projectId será adicionado no serviço, com base no token
        return producer;
    }

    public static ProducerDto fromModel(Producer producer) {
        ProducerDto dto = new ProducerDto();
        dto.setId(producer.getId());
        dto.setUsername(producer.getUsername());
        dto.setPassword(null); // Nunca retorne a senha
        dto.setDescription(producer.getDescription());
        dto.setStatus(producer.getStatus());
        dto.setBroker(producer.getBroker());
        dto.setStrategy(producer.getStrategy());
        dto.setExchange(producer.getExchange());
        dto.setQueue(producer.getQueue());
        dto.setRoutingKey(producer.getRoutingKey());
        dto.setHeaders(producer.getHeaders());
        dto.setCreatedAt(producer.getCreatedAt());
        dto.setUpdatedAt(producer.getUpdatedAt());
        return dto;
    }
}