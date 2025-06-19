// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/repository/ProducerRepository.java
package com.ufma.tap.middleware.repository;

import com.ufma.tap.middleware.model.Producer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ProducerRepository extends JpaRepository<Producer, String> {
    Optional<Producer> findByUsername(String username);
    boolean existsByUsername(String username);
}