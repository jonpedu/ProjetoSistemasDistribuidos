// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/PersistenceUpdate.java
package com.ufma.tap.middleware.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PersistenceUpdate {
    @NotNull(message = "Persistence time cannot be null")
    @Min(value = 0, message = "Persistence time must be non-negative")
    private Long persistenceTime; // Novo tempo de persistência em milissegundos
}