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
        // Desserializa a mensagem do RabbitMQ
        MessageToSend receivedMessage = gson.fromJson(messageJson, MessageToSend.class);
        String innerData = receivedMessage.getData();

        // Monta o corpo da requisição para o InterSCity
        String interscityPayload = String.format("{\"data\": %s}", innerData);

        // Configura os headers
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        // Cria a entidade da requisição
        HttpEntity<String> request = new HttpEntity<>(interscityPayload, headers);

        // **A URL final para o endpoint de criação de recursos**
        String resourceUrl = interscityApiUrl + "/catalog/resources"; // Usa o link do "adaptor"

        System.out.println("Sending to InterSCity: POST " + resourceUrl);
        System.out.println("Payload: " + interscityPayload);

        try {
            // Envia a requisição
            String response = restTemplate.postForObject(resourceUrl, request, String.class);
            System.out.println("Response from InterSCity: " + response);
        } catch (Exception e) {
            System.err.println("Error while calling InterSCity API: " + e.getMessage());
            // É importante tratar possíveis erros de conexão ou de resposta da API
            throw e;
        }
    }
}