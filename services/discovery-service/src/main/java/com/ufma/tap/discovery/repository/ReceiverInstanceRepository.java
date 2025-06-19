// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/repository/ReceiverInstanceRepository.java
package com.ufma.tap.discovery.repository;

import com.ufma.tap.discovery.model.ReceiverInstance;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReceiverInstanceRepository extends JpaRepository<ReceiverInstance, String> {
    // Métodos CRUD básicos fornecidos pelo JpaRepository
}