// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/model/ReceiverInstance.java
package com.ufma.tap.discovery.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "receiver_instances")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReceiverInstance {
    @Id
    private String consumerId; // O ID do consumidor
    private String replicaIp; // O IP/Host da instância do middleware-service onde o consumidor está conectado
    private String projectId; // ID do projeto para validação de acesso
}