// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/model/MessageToSend.java
// Mudei para 'model' pois é uma representação interna que não é diretamente mapeada para a API REST de entrada/saída de dados brutos
package com.ufma.tap.interscity.model; // OU dto, dependendo de como você quer categorizar, mantive em 'model' por ser mais 'processado'

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageToSend {
    private String messageId; // UUID da mensagem
    private String data; // Conteúdo principal da mensagem
    // Se o broker precisar de headers ou propriedades adicionais que não são parte do 'data' principal
    private Map<String, Object> customHeaders;
}