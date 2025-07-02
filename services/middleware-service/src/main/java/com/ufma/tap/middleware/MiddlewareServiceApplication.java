package com.ufma.tap.middleware;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration; // <-- Adicione esta importação
// import org.springframework.boot.autoconfigure.EnableAutoConfiguration; // Se estiver usando esta, remova e use apenas @SpringBootApplication

@SpringBootApplication(exclude = {RabbitAutoConfiguration.class}) // <-- Adicione 'exclude = {RabbitAutoConfiguration.class}' aqui
public class MiddlewareServiceApplication {

	public static void main(String[] args) {
		System.out.println("🚀 [MIDDLEWARE] Iniciando Middleware Service...");
		System.out.println("📋 [MIDDLEWARE] Porta: 8081");
		System.out.println("📋 [MIDDLEWARE] RabbitMQ: Configurado");
		System.out.println("📋 [MIDDLEWARE] InterSCity Adapter: Configurado");
		System.out.println("📋 [MIDDLEWARE] Estratégias suportadas: rabbitmq, kafka, activemq5, interscity-adapter");
		
		SpringApplication.run(MiddlewareServiceApplication.class, args);
		
		System.out.println("✅ [MIDDLEWARE] Middleware Service iniciado com sucesso!");
		System.out.println("👂 [MIDDLEWARE] Aguardando requisições de produtores e consumidores...");
	}

}