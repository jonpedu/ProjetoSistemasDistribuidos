// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/repository/ConsumerRepository.java
package com.ufma.tap.middleware.repository;

import com.ufma.tap.middleware.model.Consumer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ConsumerRepository extends JpaRepository<Consumer, String> {
    Optional<Consumer> findByUsername(String username);
    boolean existsByUsername(String username);
}