// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/controller/RegistryController.java
package com.ufma.tap.registration.controller;

import com.ufma.tap.registration.dto.ProjectDto;
import com.ufma.tap.registration.dto.Response;
import com.ufma.tap.registration.model.Project;
import com.ufma.tap.registration.service.IRegistryService;
// REMOVA ESTES IMPORTS:
// import jakarta.servlet.http.HttpServletRequest;
// import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.annotation.Validated;
import jakarta.validation.Valid; // Importar jakarta.validation.Valid para validação automática [cite: 795]

import java.util.List;

@RestController
@RequestMapping("/api/projects")
@Validated // Habilita a validação de campos usando anotações de validação [cite: 794]
public class RegistryController {

    @Autowired
    private IRegistryService iRegistryService; // Injeção de dependência do serviço de registro [cite: 797]

    @PostMapping
    
    public ResponseEntity<Response<ProjectDto>> registerProject(@Valid @RequestBody ProjectDto projectDto) {
        // @Valid ativa a validação das anotações em ProjectDto [cite: 795]
        Project project = iRegistryService.registerProject(projectDto.toModel());
        Response<ProjectDto> apiResponse = new Response<>("Project successfully registered.", HttpStatus.CREATED.value(), ProjectDto.fromModel(project));
        return new ResponseEntity<>(apiResponse, HttpStatus.CREATED);
    }

    @GetMapping("/{projectId}")
   
    public ResponseEntity<Response<ProjectDto>> getProject(@PathVariable String projectId, @RequestHeader("Authorization") String authorizationHeader) {
        // Validação de projectId pode ser feita aqui ou no serviço
       
        Project project = iRegistryService.getProject(projectId, authorizationHeader);
        Response<ProjectDto> apiResponse = new Response<>("Project info successfully retrieved.", HttpStatus.OK.value(), ProjectDto.fromModel(project));
        return new ResponseEntity<>(apiResponse, HttpStatus.OK);
    }

    
}