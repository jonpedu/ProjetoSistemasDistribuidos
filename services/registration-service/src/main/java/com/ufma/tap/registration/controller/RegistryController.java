// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/controller/RegistryController.java
package com.ufma.tap.registration.controller;

import com.ufma.tap.registration.dto.ProjectDto;
import com.ufma.tap.registration.dto.Response;
import com.ufma.tap.registration.model.Project;
import com.ufma.tap.registration.service.IRegistryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.annotation.Validated;
import jakarta.validation.Valid;

import java.util.List;

@RestController
@RequestMapping("/api/projects")
@Validated
public class RegistryController {

    @Autowired
    private IRegistryService iRegistryService;

    @PostMapping
    public ResponseEntity<Response<ProjectDto>> registerProject(@Valid @RequestBody ProjectDto projectDto) {
        Project project = iRegistryService.registerProject(projectDto.toModel());
        Response<ProjectDto> apiResponse = new Response<>("Project successfully registered.", HttpStatus.CREATED.value(), ProjectDto.fromModel(project));
        return new ResponseEntity<>(apiResponse, HttpStatus.CREATED);
    }

    @GetMapping("/{projectId}")
    public ResponseEntity<Response<ProjectDto>> getProject(@PathVariable String projectId, @RequestHeader("Authorization") String authorizationHeader) {
        Project project = iRegistryService.getProject(projectId, authorizationHeader);
        Response<ProjectDto> apiResponse = new Response<>("Project info successfully retrieved.", HttpStatus.OK.value(), ProjectDto.fromModel(project));
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @PutMapping("/{projectId}") // Adicionado para Atualizar
    public ResponseEntity<Response<ProjectDto>> updateProject(
            @PathVariable String projectId,
            @Valid @RequestBody ProjectDto projectDto, // O DTO de entrada pode ter apenas os campos a serem atualizados
            @RequestHeader("Authorization") String authorizationHeader) {

        // Crie um objeto Project com os dados do DTO para passar ao serviço
        Project updatedProjectModel = projectDto.toModel();
        // O ID do projeto deve vir do path, não do DTO no body para PUT
        updatedProjectModel.setId(projectId);

        Project updatedProject = iRegistryService.updateProject(projectId, updatedProjectModel, authorizationHeader);
        Response<ProjectDto> apiResponse = new Response<>("Project successfully updated.", HttpStatus.OK.value(), ProjectDto.fromModel(updatedProject));
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    @DeleteMapping("/{projectId}") // Adicionado para Deletar
    public ResponseEntity<Response<Void>> deleteProject(
            @PathVariable String projectId,
            @RequestHeader("Authorization") String authorizationHeader) {
        iRegistryService.deleteProject(projectId, authorizationHeader);
        Response<Void> apiResponse = new Response<>("Project successfully deleted.", HttpStatus.OK.value(), null);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    // Se houver um metodo para listar brokers suportados (GET /api/brokers)
    // Ele não precisa de autenticação de projeto
    /*
    @GetMapping("/brokers")
    public ResponseEntity<Response<List<String>>> getSupportedBrokers() {
        List<String> brokers = iRegistryService.getSupportedBrokers(); // Você precisaria implementar este método no serviço
        Response<List<String>> apiResponse = new Response<>("Supported brokers retrieved.", HttpStatus.OK.value(), brokers);
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }
    */
}