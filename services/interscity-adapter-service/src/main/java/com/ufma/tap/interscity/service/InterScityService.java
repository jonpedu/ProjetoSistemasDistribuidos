package com.ufma.tap.interscity.service;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.ufma.tap.interscity.model.MessageToSend;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class InterScityService {

    @Value("${interscity.api.url}")
    private String interscityApiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final Gson gson = new Gson();

    public void registerResource(String messageJson) {
        System.out.println("🌐 [INTERSCITY SERVICE] Iniciando comunicação com InterSCity...");

        MessageToSend receivedMessage = gson.fromJson(messageJson, MessageToSend.class);
        String innerDataJson = receivedMessage.getData();

        // Desserializa o JSON interno para um Mapa
        Type type = new TypeToken<Map<String, Object>>() {}.getType();
        Map<String, Object> sensorData = gson.fromJson(innerDataJson, type);

        // Extrai os dados para o formato da InterSCity
        String description = (String) sensorData.getOrDefault("description", "No description");
        double lat = (Double) sensorData.getOrDefault("lat", 0.0);
        double lon = (Double) sensorData.getOrDefault("lon", 0.0);
        String status = (String) sensorData.getOrDefault("status", "disabled");

        // Extrai as 'capabilities' (todas as chaves exceto as que já usamos)
        List<String> capabilities = sensorData.keySet().stream()
                .filter(key -> !key.equals("service_name") && !key.equals("description") && !key.equals("timestamp") &&
                        !key.equals("data_type") && !key.equals("test_id") && !key.equals("lat") &&
                        !key.equals("lon") && !key.equals("status"))
                .collect(Collectors.toList());

        // Cria o mapa para o novo payload da InterSCity
        Map<String, Object> interscityPayloadMap = Map.of(
                "description", description,
                "lat", lat,
                "lon", lon,
                "status", status,
                "capabilities", capabilities
        );

        // Converte o mapa para a string JSON final
        String interscityPayload = gson.toJson(Map.of("data", interscityPayloadMap));
        
        System.out.println("📤 [INTERSCITY SERVICE] Payload para InterSCity: " + interscityPayload);
        
        // Configura os headers
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        
        HttpEntity<String> request = new HttpEntity<>(interscityPayload, headers);
        String resourceUrl = interscityApiUrl + "/catalog/resources";

        try {
            System.out.println("🔄 [INTERSCITY SERVICE] Enviando requisição para InterSCity...");
            String response = restTemplate.postForObject(resourceUrl, request, String.class);
            System.out.println("✅ [INTERSCITY SERVICE] Resposta recebida do InterSCity!");
            System.out.println("📥 [INTERSCITY SERVICE] Response: " + response);
        } catch (Exception e) {
            System.err.println("❌ [INTERSCITY SERVICE] ERRO na comunicação com InterSCity!");
            System.err.println("❌ [INTERSCITY SERVICE] Mensagem: " + e.getMessage());
            throw e;
        }
    }
}