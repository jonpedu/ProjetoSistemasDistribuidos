package com.ufma.tap.middleware;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration; // <-- Adicione esta importação
// import org.springframework.boot.autoconfigure.EnableAutoConfiguration; // Se estiver usando esta, remova e use apenas @SpringBootApplication

@SpringBootApplication(exclude = {RabbitAutoConfiguration.class}) // <-- Adicione 'exclude = {RabbitAutoConfiguration.class}' aqui
public class MiddlewareServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(MiddlewareServiceApplication.class, args);
	}

}