// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/model/Broker.java
package com.ufma.tap.middleware.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// Esta classe representa a configuração do broker que é passada para os adaptadores de mensageria.
// Não é uma entidade JPA.
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Broker {
    private String name; // Ex: "rabbitmq", "kafka"
    private String strategy; // Ex: "direct", "topic", "fanout", "headers"
    private String exchange; // Para RabbitMQ
    private String queue; // Para RabbitMQ/ActiveMQ
    private String routingKey; // Para RabbitMQ topic/direct
    private String headers; // Para RabbitMQ headers exchange (JSON string)
    // Se precisar de credenciais específicas ou host/port, adicione aqui (ou passe como parâmetros adicionais)
    // private String host;
    // private Integer port;
    // private String username;
    // private String password;
}