// Caminho: services/interscity-adapter-service/src/main/java/com/ufma/tap/interscity/InterscityAdapterServiceApplication.java
package com.ufma.tap.interscity;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class InterscityAdapterServiceApplication {

    public static void main(String[] args) {
        System.out.println("🚀 [INTERSCITY ADAPTER] Iniciando InterSCity Adapter Service...");
        System.out.println("📋 [INTERSCITY ADAPTER] Porta: 8083");
        System.out.println("📋 [INTERSCITY ADAPTER] RabbitMQ: Configurado");
        System.out.println("📋 [INTERSCITY ADAPTER] InterSCity API: Configurado");
        
        SpringApplication.run(InterscityAdapterServiceApplication.class, args);
        
        System.out.println("✅ [INTERSCITY ADAPTER] InterSCity Adapter Service iniciado com sucesso!");
        System.out.println("👂 [INTERSCITY ADAPTER] Aguardando mensagens do Middleware...");
    }

}