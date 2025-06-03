// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/service/RegistryService.java
package com.ufma.tap.registration.service;

import com.ufma.tap.registration.model.Project;
import com.ufma.tap.registration.repository.ProjectRepository;
import com.ufma.tap.registration.security.JWTUtil;
import com.ufma.tap.registration.exception.ProjectConflictException; // Nova exceção
import com.ufma.tap.registration.exception.ProjectNotFoundException; // Nova exceção
import com.ufma.tap.registration.exception.InvalidTokenException; // Nova exceção
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class RegistryService implements IRegistryService {

    @Autowired
    private ProjectRepository projectRepository;

    @Autowired
    private JWTUtil jwtUtil;

    // Brokers suportados globalmente pelo sistema (pode vir de um banco de dados ou arquivo de configuração)
    private final Set<String> GLOBAL_SUPPORTED_BROKERS = Set.of("rabbitmq", "kafka", "activemq5");

    @Override
    public Project registerProject(Project project) {
        if (projectRepository.existsByName(project.getName())) {
            throw new ProjectConflictException("Project with name '" + project.getName() + "' already registered.");
        }

        // Valida se os brokers informados são suportados globalmente
        for (String broker : project.getSupportedBrokers()) {
            if (!GLOBAL_SUPPORTED_BROKERS.contains(broker.toLowerCase())) {
                throw new IllegalArgumentException("Broker '" + broker + "' is not globally supported."); // Implementar BrokerNotSupportedException
            }
        }

        project.setId(UUID.randomUUID().toString());
        // Lógica simples para gerar location (DNS). Em produção, isso seria um serviço externo.
        project.setLocation(project.getName().toLowerCase().replace(" ", "-") + ".multibroker.com");

        // Gerar o token JWT para o projeto. Este token será o "master token" do projeto.
        // O assunto do token (subject) pode ser o ID do projeto ou um ID de "usuário admin" padrão.
        String generatedToken = jwtUtil.generateToken(project.getId(), project.getId());
        project.setAuthToken(generatedToken); // Temporariamente, para retornar ao cliente

        return projectRepository.save(project);
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

    // Métodos auxiliares para extrair o token do cabeçalho
    private String extractToken(String authorizationHeader) {
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            return authorizationHeader.substring(7); // Remove "Bearer "
        }
        throw new InvalidTokenException("Authorization header missing or invalid format.");
    }

    // --- Outros métodos do IRegistryService (ex: updateProject, deleteProject) iriam aqui ---
    // Você precisaria implementar a lógica para cada um deles.
}