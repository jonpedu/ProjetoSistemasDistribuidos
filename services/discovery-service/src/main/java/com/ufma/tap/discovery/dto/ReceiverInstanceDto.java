// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/dto/ReceiverInstanceDto.java
package com.ufma.tap.discovery.dto;

import com.ufma.tap.discovery.model.ReceiverInstance;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReceiverInstanceDto {
    private String consumerId;
    private String replicaIp; // O IP/Host da instância do middleware-service
    private String projectId; // ID do projeto

    public ReceiverInstance toModel() {
        ReceiverInstance model = new ReceiverInstance();
        model.setConsumerId(this.consumerId);
        model.setReplicaIp(this.replicaIp);
        model.setProjectId(this.projectId);
        return model;
    }

    public static ReceiverInstanceDto fromModel(ReceiverInstance model) {
        ReceiverInstanceDto dto = new ReceiverInstanceDto();
        dto.setConsumerId(model.getConsumerId());
        dto.setReplicaIp(model.getReplicaIp());
        dto.setProjectId(model.getProjectId());
        return dto;
    }
}