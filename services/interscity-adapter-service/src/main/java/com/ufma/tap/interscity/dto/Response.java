// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/Response.java
package com.ufma.tap.interscity.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Response<T> {
    private String message;
    private Integer appCode; // Ex: 200, 201 para sucesso; 4xx para erros de cliente; 5xx para erros de servidor
    private T data; // Dados específicos do payload da resposta (ProducerDto, ConsumerDto, etc.)
    private String status; // Ex: "SUCCESS", "WARNING", "ERROR"

    // Construtor auxiliar para respostas de sucesso/erro com base no appCode
    public Response(String message, Integer appCode, T data) {
        this.message = message;
        this.appCode = appCode;
        this.data = data;
        // Define o status com base no appCode
        this.status = (appCode >= 200 && appCode < 300) ? "SUCCESS" : "ERROR";
        // Você pode refinar a lógica de status para incluir "WARNING" se tiver appCodes específicos para isso
    }
}