# Caminho: services/middleware-service/Dockerfile (e similar para outros serviços)


# Usar uma imagem base oficial do OpenJDK para Java 17
FROM openjdk:17-jdk-slim

# Definir o diretório de trabalho dentro do container
WORKDIR /app

# Copiar o Maven Wrapper e a pasta .mvn que ele usa
# É importante copiar antes do pom.xml e do src para que o Docker possa cachear as camadas
COPY .mvn .mvn
COPY mvnw .
COPY mvnw.cmd .
RUN chmod +x mvnw # Garante que o script seja executável no Linux

# Copiar o arquivo pom.xml para que as dependências possam ser baixadas
COPY pom.xml .

# Copiar o restante do código-fonte do projeto
COPY src ./src

# Build do projeto Maven usando o Maven Wrapper
RUN ./mvnw clean package -Dmaven.test.skip=true

# Expor a porta que a aplicação Spring Boot irá rodar
# Substitua 8080 pela porta específica de cada serviço (8081, 8082)
EXPOSE 8081

# Comando para executar a aplicação Spring Boot
ENTRYPOINT ["java", "-jar", "target/middleware-service-0.0.1-SNAPSHOT.jar"]