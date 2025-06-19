// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/service/RegistryService.java
package com.ufma.tap.registration.service;

import com.ufma.tap.registration.model.Project;
import com.ufma.tap.registration.repository.ProjectRepository;
import com.ufma.tap.registration.security.JWTUtil;
import com.ufma.tap.registration.exception.ProjectConflictException;
import com.ufma.tap.registration.exception.ProjectNotFoundException;
import com.ufma.tap.registration.exception.InvalidTokenException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Service
public class RegistryService implements IRegistryService {

    @Autowired
    private ProjectRepository projectRepository;

    @Autowired
    private JWTUtil jwtUtil;

    private final Set<String> GLOBAL_SUPPORTED_BROKERS = Set.of("rabbitmq", "kafka", "activemq5");

    @Override
    public Project registerProject(Project project) {
        if (projectRepository.existsByName(project.getName())) {
            throw new ProjectConflictException("Project with name '" + project.getName() + "' already registered.");
        }

        for (String broker : project.getSupportedBrokers()) {
            if (!GLOBAL_SUPPORTED_BROKERS.contains(broker.toLowerCase())) {
                throw new IllegalArgumentException("Broker '" + broker + "' is not globally supported.");
            }
        }

        project.setId(UUID.randomUUID().toString());
        project.setLocation(project.getName().toLowerCase().replace(" ", "-") + ".multibroker.com");

        Project savedProject = projectRepository.save(project);

        String generatedToken = jwtUtil.generateToken(savedProject.getId(), savedProject.getId());
        savedProject.setAuthToken(generatedToken);

        return savedProject;
    }

    @Override
    public Project getProject(String projectId, String authorizationHeader) {
        String token = extractToken(authorizationHeader);
        if (!jwtUtil.validateToken(token, projectId)) {
            throw new InvalidTokenException("Invalid or unauthorized token for project '" + projectId + "'.");
        }
        return projectRepository.findById(projectId)
                .orElseThrow(() -> new ProjectNotFoundException("Project with ID '" + projectId + "' not found."));
    }

    @Override
    public Project updateProject(String projectId, Project updatedProject, String authorizationHeader) {
        String token = extractToken(authorizationHeader);
        if (!jwtUtil.validateToken(token, projectId)) {
            throw new InvalidTokenException("Invalid or unauthorized token for project '" + projectId + "'.");
        }

        // Encontra o projeto existente pelo ID
        Project existingProject = projectRepository.findById(projectId)
                .orElseThrow(() -> new ProjectNotFoundException("Project with ID '" + projectId + "' not found."));

        // Atualiza apenas os campos permitidos ou necessários
        // Neste exemplo, vamos permitir a atualização da região e dos brokers suportados.
        // O nome não deve ser alterado se for usado para gerar a URL (location).
        if (updatedProject.getRegion() != null) {
            existingProject.setRegion(updatedProject.getRegion());
        }
        if (updatedProject.getSupportedBrokers() != null && !updatedProject.getSupportedBrokers().isEmpty()) {
            // Valida os novos brokers suportados
            for (String broker : updatedProject.getSupportedBrokers()) {
                if (!GLOBAL_SUPPORTED_BROKERS.contains(broker.toLowerCase())) {
                    throw new IllegalArgumentException("Broker '" + broker + "' in updated list is not globally supported.");
                }
            }
            existingProject.setSupportedBrokers(updatedProject.getSupportedBrokers());
        }

        // Salva as alterações no banco de dados
        return projectRepository.save(existingProject);
    }

    @Override
    public void deleteProject(String projectId, String authorizationHeader) {
        String token = extractToken(authorizationHeader);
        if (!jwtUtil.validateToken(token, projectId)) {
            throw new InvalidTokenException("Invalid or unauthorized token for project '" + projectId + "'.");
        }

        // Verifica se o projeto existe antes de tentar deletar
        if (!projectRepository.existsById(projectId)) {
            throw new ProjectNotFoundException("Project with ID '" + projectId + "' not found.");
        }

        projectRepository.deleteById(projectId);
    }

    // Método auxiliar para extrair o token do cabeçalho de autorização
    private String extractToken(String authorizationHeader) {
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            return authorizationHeader.substring(7); // Remove "Bearer "
        }
        throw new InvalidTokenException("Authorization header missing or invalid format.");
    }
}