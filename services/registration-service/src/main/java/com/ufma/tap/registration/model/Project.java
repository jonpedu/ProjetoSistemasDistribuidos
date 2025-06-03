// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/model/Project.java
package com.ufma.tap.registration.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Table(name = "projects")
@Data // Gerencia getters, setters, toString, equals e hashCode
@NoArgsConstructor // Construtor sem argumentos
@AllArgsConstructor // Construtor com todos os argumentos
public class Project {
    @Id 
    private String id; 
    private String name;
    private String location; 
    private String region;
    @ElementCollection // Para armazenar uma lista simples de strings em uma tabela separada
    @CollectionTable(name = "project_supported_brokers", joinColumns = @JoinColumn(name = "project_id"))
    @Column(name = "broker_name")
    private List<String> supportedBrokers; // Nomes dos brokers suportados por este projeto

    
    @Transient // Indica que este campo não será persistido no banco de dados
    private String authToken; // Este campo será preenchido após o registro para ser retornado ao cliente
}