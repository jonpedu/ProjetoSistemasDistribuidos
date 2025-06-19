// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/dto/ConsumerConnectionEvent.java
package com.ufma.tap.discovery.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConsumerConnectionEvent {
    private String consumerId;
    private String replicaIp; // O IP/Host da instância do middleware-service
    private String projectId;
    private String eventType; // Ex: "CONNECTED", "DISCONNECTED"
}