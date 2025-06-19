// Caminho: services/discovery-service/src/main/java/com/ufma/tap/discovery/dto/Response.java
package com.ufma.tap.discovery.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Response<T> {
    private String message;
    private Integer appCode;
    private T data;
    private String status;

    public Response(String message, Integer appCode, T data) {
        this.message = message;
        this.appCode = appCode;
        this.data = data;
        this.status = (appCode >= 200 && appCode < 300) ? "SUCCESS" : "ERROR";
    }
}