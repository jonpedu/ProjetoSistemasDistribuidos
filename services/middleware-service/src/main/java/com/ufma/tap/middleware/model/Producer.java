// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/model/Producer.java
package com.ufma.tap.middleware.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "producers")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Producer {
    @Id
    private String id; // UUID
    private String username;
    private String password; // Em um cenário real, use criptografia (ex: BCrypt)
    private String description; // Descrição do produtor
    private String status; // Status do produtor (active, inactive, etc.)
    private String projectId; // ID do projeto a que este produtor pertence (do registration-service)
    private String broker;    // Ex: "rabbitmq", "kafka", "activemq5"
    private String strategy;  // Ex: "direct", "topic", "fanout", "headers"
    private String exchange;  // Nome do exchange para RabbitMQ
    private String queue;     // Nome da fila ou tópico
    private String routingKey; // Chave de roteamento para RabbitMQ topic/direct
    private String headers;   // JSON String para headers personalizados (para RabbitMQ headers exchange)
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) {
            status = "active";
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}