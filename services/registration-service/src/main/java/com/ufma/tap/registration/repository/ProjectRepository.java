//services/registration-service/src/main/java/com/ufma/tap/registration/repository/ProjectRepository.java
package com.ufma.tap.registration.repository;

import com.ufma.tap.registration.model.Project;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ProjectRepository extends JpaRepository<Project, String> {
    Optional<Project> findByName(String name);
    boolean existsByName(String name);
}
