// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/dto/ProjectDto.java
package com.ufma.tap.registration.dto;

import com.ufma.tap.registration.model.Project;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProjectDto {

    private String id; // Pode ser nulo na criação, preenchido no retorno

    @NotBlank(message = "Project name cannot be empty")
    @Size(min = 8, max = 32, message = "Project name must be between 8 and 32 characters")
    @Pattern(regexp = "^[a-zA-Z0-9]+$", message = "Project name must be alphanumeric")
    private String name;

    @NotBlank(message = "Region cannot be empty")
    @Size(min = 2, max = 2, message = "Region must be a 2-letter ISO Alpha-2 code")
    @Pattern(regexp = "^[A-Z]{2}$", message = "Region must be uppercase 2-letter ISO Alpha-2 code")
    private String region;

    @NotEmpty(message = "At least one broker must be supported")
    private List<String> supportedBrokers; // Nomes dos brokers (ex: "rabbitmq", "kafka")

    private String location; // Será gerado pelo serviço

    private String authToken; // Token gerado no registro, para ser retornado

    // Métodos de conversão entre DTO e Modelo de Domínio
    public Project toModel() {
        Project project = new Project();
        project.setId(this.id);
        project.setName(this.name);
        project.setRegion(this.region);
        project.setSupportedBrokers(this.supportedBrokers);
        project.setLocation(this.location);
        project.setAuthToken(this.authToken);
        return project;
    }

    public static ProjectDto fromModel(Project project) {
        ProjectDto dto = new ProjectDto();
        dto.setId(project.getId());
        dto.setName(project.getName());
        dto.setRegion(project.getRegion());
        dto.setSupportedBrokers(project.getSupportedBrokers());
        dto.setLocation(project.getLocation());
        dto.setAuthToken(project.getAuthToken());
        return dto;
    }
}