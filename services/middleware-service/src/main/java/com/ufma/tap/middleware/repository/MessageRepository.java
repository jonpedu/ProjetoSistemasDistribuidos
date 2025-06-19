// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/repository/MessageRepository.java
package com.ufma.tap.middleware.repository;

import com.ufma.tap.middleware.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, String> {
    List<Message> findByConsumerId(String consumerId);
    Optional<Message> findByMessageIdAndConsumerId(String messageId, String consumerId);
    void deleteAllByConsumerId(String consumerId);

    void deleteByMessageIdAndConsumerId(String messageId, String consumerId);
}