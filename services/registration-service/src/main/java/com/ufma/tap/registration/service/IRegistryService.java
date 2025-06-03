// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/service/IRegistryService.java

package com.ufma.tap.registration.service;

import com.ufma.tap.registration.model.Project;

import java.util.List;

public interface IRegistryService {
    Project registerProject(Project project);
    Project getProject(String projectId, String authToken);
    
}