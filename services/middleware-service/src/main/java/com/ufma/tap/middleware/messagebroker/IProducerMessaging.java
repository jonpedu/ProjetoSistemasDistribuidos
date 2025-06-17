// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/messagebroker/IProducerMessaging.java
package com.ufma.tap.middleware.messagebroker;

import com.ufma.tap.middleware.model.Broker; // Representa a configuração do broker (nome, estratégia, etc.)
import com.ufma.tap.middleware.model.MessageToSend; // O objeto a ser enviado

public interface IProducerMessaging {
    /**
     * Conecta o produtor ao broker de mensagens.
     * @param broker Objeto Broker contendo as configurações de conexão.
     */
    void connect(Broker broker);

    /**
     * Envia uma mensagem para o broker de acordo com as configurações do broker.
     * @param messageToSend A mensagem a ser enviada.
     * @param broker Objeto Broker contendo as configurações de roteamento (exchange, queue, strategy, etc.).
     */
    void send(MessageToSend messageToSend, Broker broker);

    /**
     * Desconecta o produtor do broker de mensagens.
     * @param producerId O ID do produtor a ser desconectado.
     */
    void close(String producerId);
}