// Caminho: services/registration-service/src/main/java/com/ufma/tap/registration/dto/Response.java
package com.ufma.tap.registration.dto;

import lombok.AllArgsConstructor; // Import AllArgsConstructor
import lombok.Data;
import lombok.NoArgsConstructor;

@Data // Esta anotação do Lombok gera getters e setters, incluindo para 'status'
@NoArgsConstructor
@AllArgsConstructor // Este construtor vai incluir o 'status' se definido como campo
public class Response<T> {
    private String message;
    private Integer appCode;
    private T data;
    private String status; // <<< GARANTA QUE ESTA LINHA EXISTE

    // Construtor auxiliar (agora atribui o status ao campo)
    public Response(String message, Integer appCode, T data) {
        this.message = message;
        this.appCode = appCode;
        this.data = data;
        // Define o status com base no appCode
        this.status = (appCode >= 200 && appCode < 300) ? "SUCCESS" : "ERROR";
        // Para outros appCodes específicos (como 14xx), você pode refinar a lógica aqui
    }
}