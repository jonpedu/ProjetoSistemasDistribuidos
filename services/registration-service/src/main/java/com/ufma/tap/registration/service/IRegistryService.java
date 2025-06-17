// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/service/IRegistryService.java

package com.ufma.tap.registration.service;

import com.ufma.tap.registration.model.Project;

import java.util.List; // Import necessário se você for adicionar métodos que retornam listas

public interface IRegistryService {
    Project registerProject(Project project);
    Project getProject(String projectId, String authToken);
    Project updateProject(String projectId, Project updatedProject, String authToken); // Adicionado
    void deleteProject(String projectId, String authToken); // Adicionado
    // List<String> getSupportedBrokers(); // Este seria para o endpoint GET /api/brokers
    // Project registerBroker(Broker broker, String authToken); // Este seria para o endpoint POST /api/brokers
    // Project updateBroker(String brokerId, Broker updatedBroker, String authToken); // Este seria para o endpoint PUT /api/brokers/{brokerId}
}