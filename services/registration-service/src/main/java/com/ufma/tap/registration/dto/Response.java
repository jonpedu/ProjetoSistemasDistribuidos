// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/dto/Response.java
package com.ufma.tap.registration.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Response<T> {
    private String message;
    private Integer appCode; // Equivalente ao "status" que você mencionou (1200 para sucesso, 14xx para erro)
    private T data; // Dados específicos do payload da resposta (ProjectDto, BrokerDto, etc.)
    private String status; // SUCCESS, WARNING, ERROR

    public Response(String message, Integer appCode, T data) {
        this.message = message;
        this.appCode = appCode;
        this.data = data;
        this.status = (appCode >= 1200 && appCode < 1300) ? "SUCCESS" : "ERROR"; // Lógica simples para status
    }
}