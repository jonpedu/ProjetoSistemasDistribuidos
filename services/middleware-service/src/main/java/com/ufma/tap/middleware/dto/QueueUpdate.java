// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/QueueUpdate.java
package com.ufma.tap.middleware.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QueueUpdate {
    @NotBlank(message = "Queue name cannot be empty")
    private String queue; // Novo nome da fila
    // Estes campos são opcionais, sem @NotBlank para permitir atualização parcial
    private String exchange;
    private String routingKey;
    private String headers; // JSON String
}