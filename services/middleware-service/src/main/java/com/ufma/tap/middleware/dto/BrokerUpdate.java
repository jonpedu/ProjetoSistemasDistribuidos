// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/BrokerUpdate.java
package com.ufma.tap.middleware.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BrokerUpdate {
    @NotBlank(message = "Broker name cannot be empty")
    private String broker; // Novo nome do broker
    // Estes campos são opcionais, sem @NotBlank para permitir atualização parcial
    private String strategy;
    private String exchange;
    private String queue;
    private String routingKey;
    private String headers; // JSON String
}