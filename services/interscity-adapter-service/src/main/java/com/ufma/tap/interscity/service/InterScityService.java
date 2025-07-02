package com.ufma.tap.interscity.service;

import com.google.gson.Gson;
import com.ufma.tap.interscity.model.MessageToSend;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class InterScityService {

    @Value("${interscity.api.url}")
    private String interscityApiUrl; // Será injetado: "https://cidadesinteligentes.lsdi.ufma.br/interscity_lh"

    private final RestTemplate restTemplate = new RestTemplate();
    private final Gson gson = new Gson();

    public void registerResource(String messageJson) {
        System.out.println("🌐 [INTERSCITY SERVICE] Iniciando comunicação com InterSCity...");
        
        // Desserializa a mensagem do RabbitMQ
        MessageToSend receivedMessage = gson.fromJson(messageJson, MessageToSend.class);
        String innerData = receivedMessage.getData();

        System.out.println("📋 [INTERSCITY SERVICE] Message ID: " + receivedMessage.getMessageId());
        System.out.println("📋 [INTERSCITY SERVICE] Data extraída: " + innerData);
        System.out.println("📋 [INTERSCITY SERVICE] Headers: " + receivedMessage.getCustomHeaders());

        // Monta o corpo da requisição para o InterSCity
        String interscityPayload = String.format("{\"data\": %s}", innerData);

        // Configura os headers
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        // Cria a entidade da requisição
        HttpEntity<String> request = new HttpEntity<>(interscityPayload, headers);

        // **A URL final para o endpoint de criação de recursos**
        String resourceUrl = interscityApiUrl + "/catalog/resources"; // Usa o link do "adaptor"

        System.out.println("🌐 [INTERSCITY SERVICE] URL da API InterSCity: " + interscityApiUrl);
        System.out.println("🌐 [INTERSCITY SERVICE] Endpoint completo: " + resourceUrl);
        System.out.println("📤 [INTERSCITY SERVICE] Método: POST");
        System.out.println("📤 [INTERSCITY SERVICE] Headers: " + headers);
        System.out.println("📤 [INTERSCITY SERVICE] Payload para InterSCity: " + interscityPayload);

        try {
            System.out.println("🔄 [INTERSCITY SERVICE] Enviando requisição para InterSCity...");
            // Envia a requisição
            String response = restTemplate.postForObject(resourceUrl, request, String.class);
            System.out.println("✅ [INTERSCITY SERVICE] Resposta recebida do InterSCity!");
            System.out.println("📥 [INTERSCITY SERVICE] Status: 200 OK");
            System.out.println("📥 [INTERSCITY SERVICE] Response: " + response);
        } catch (Exception e) {
            System.err.println("❌ [INTERSCITY SERVICE] ERRO na comunicação com InterSCity!");
            System.err.println("❌ [INTERSCITY SERVICE] Tipo de erro: " + e.getClass().getSimpleName());
            System.err.println("❌ [INTERSCITY SERVICE] Mensagem: " + e.getMessage());
            System.err.println("❌ [INTERSCITY SERVICE] URL tentada: " + resourceUrl);
            // É importante tratar possíveis erros de conexão ou de resposta da API
            throw e;
        }
    }
}