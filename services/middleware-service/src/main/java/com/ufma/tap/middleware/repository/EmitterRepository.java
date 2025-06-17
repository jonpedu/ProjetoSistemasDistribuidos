// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/repository/EmitterRepository.java
package com.ufma.tap.middleware.repository;

import org.springframework.stereotype.Repository;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import java.util.Optional;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class EmitterRepository {
    // Mantém um mapeamento de consumerId para SseEmitter
    private final Map<String, SseEmitter> emitters = new ConcurrentHashMap<>();

    public void add(String consumerId, SseEmitter sseEmitter) {
        emitters.put(consumerId, sseEmitter);
    }

    public void remove(String consumerId) {
        emitters.remove(consumerId);
    }

    public Optional<SseEmitter> get(String consumerId) {
        return Optional.ofNullable(emitters.get(consumerId));
    }
}