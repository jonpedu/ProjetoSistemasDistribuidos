// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/StrategyUpdate.java
package com.ufma.tap.middleware.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StrategyUpdate {
    @NotBlank(message = "Strategy cannot be empty")
    private String strategy;
    private String exchange;
    private String queue;
    private String routingKey;
    private String headers; // JSON String
}