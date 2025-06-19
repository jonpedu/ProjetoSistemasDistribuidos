// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/model/Consumer.java
package com.ufma.tap.middleware.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "consumers")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Consumer {
    @Id
    private String id; // UUID
    private String username;
    private String password; // Em um cenário real, use criptografia (ex: BCrypt)
    private String projectId; // ID do projeto a que este consumidor pertence
    private Long persistenceTime; // Tempo em milissegundos para manter mensagens persistidas
    private String broker;    // Ex: "rabbitmq", "kafka", "activemq5"
    private String strategy;  // Ex: "direct", "topic", "fanout", "headers"
    private String exchange;  // Nome do exchange para RabbitMQ
    private String queue;     // Nome da fila ou tópico
    private String routingKey; // Chave de roteamento para RabbitMQ topic/direct
    private String headers;   // JSON String para headers personalizados (para RabbitMQ headers exchange)
}