// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/model/Message.java
package com.ufma.tap.middleware.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Entity
@Table(name = "messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Message {
    @Id
    private String messageId; // ID da mensagem original (gerado pelo produtor)
    private String consumerId; // ID do consumidor a quem esta mensagem pertence
    @Lob // Para armazenar String longa (LOB - Large Object)
    @Column(columnDefinition = "TEXT") // Definir o tipo da coluna no banco para TEXT
    private String data; // O conteúdo da mensagem
    private String queue; // Fila/tópico pela qual a mensagem foi recebida
    @Temporal(TemporalType.TIMESTAMP) // Para mapear Date para TIMESTAMP no banco
    private Date expireAt; // Data de expiração para a mensagem persistida
}