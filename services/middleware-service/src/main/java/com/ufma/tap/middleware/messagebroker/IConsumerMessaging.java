// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/messagebroker/IConsumerMessaging.java
package com.ufma.tap.middleware.messagebroker;

import com.ufma.tap.middleware.model.Message;

// import java.util.function.Consumer; // Cuidado com conflito de nome, pode ser java.util.function.Consumer ou nosso model.Consumer

public interface IConsumerMessaging {
    /**
     * Conecta o consumidor ao broker e começa a escutar mensagens.
     * @param consumer Objeto Consumer contendo as configurações de conexão e roteamento.
     * @param messageHandler Um callback para processar mensagens recebidas.
     */
    void connectAndListen(com.ufma.tap.middleware.model.Consumer consumer, java.util.function.Consumer<Message> messageHandler);


    /**
     * Desconecta o consumidor do broker de mensagens.
     * @param consumerId O ID do consumidor a ser desconectado.
     */
    void close(String consumerId);
}