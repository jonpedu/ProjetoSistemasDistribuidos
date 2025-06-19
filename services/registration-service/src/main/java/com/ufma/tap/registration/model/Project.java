// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/model/Project.java
package com.ufma.tap.registration.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.persistence.FetchType;
import java.util.List;

@Entity
@Table(name = "projects")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Project {
    @Id
    private String id;
    private String name;
    private String location;
    private String region;
    @ElementCollection(fetch = FetchType.EAGER) // <<< ADICIONE ISSO AQUI
    @CollectionTable(name = "project_supported_brokers", joinColumns = @JoinColumn(name = "project_id"))
    @Column(name = "broker_name")
    private List<String> supportedBrokers;

    @Transient
    private String authToken;
}