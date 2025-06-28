# Caminho: services/interscity-adapter-service/Dockerfile

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
# Este comando vai gerar o JAR em target/interscity-adapter-service-0.0.1-SNAPSHOT.jar
RUN ./mvnw clean package -Dmaven.test.skip=true -Dmaven.compiler.parameters=true

# ALTERADO: Expondo a porta correta para este serviço (8083),
# conforme definido no application.properties do adaptador.
EXPOSE 8083

# ALTERADO: Apontando para o nome do JAR correto gerado pelo Maven.
# O nome do JAR é baseado no <artifactId> do seu pom.xml.
ENTRYPOINT ["java", "-jar", "target/interscity-adapter-service-0.0.1-SNAPSHOT.jar"]