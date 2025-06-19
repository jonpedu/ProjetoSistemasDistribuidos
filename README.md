# Sistema Distribuído de Gerenciamento de Tarefas

## Sumário

1.  [Introdução](#1-introdução)
2.  [Status do Projeto](#2-status-do-projeto)
3.  [Arquitetura e Tecnologias](#3-arquitetura-e-tecnologias)
4.  [Pré-requisitos](#4-pré-requisitos)
5.  [Configuração do Ambiente](#5-configuração-do-ambiente)
6.  [Execução do Projeto](#6-execução-do-projeto)
7.  [Uso da API](#7-uso-da-api)
8.  [Estrutura do Projeto](#8-estrutura-do-projeto)
9.  [Equipe](#9-equipe)

---

## 1. Introdução

Este é um projeto acadêmico desenvolvido para a disciplina de Sistemas Distribuídos do curso de Engenharia da Computação da Universidade Federal do Maranhão (UFMA).

O objetivo é implementar um sistema distribuído para gerenciamento de tarefas, utilizando uma arquitetura de microsserviços. O foco do projeto está na comunicação em tempo real via Publish-Subscribe (Pub/Sub), sincronização de dados entre os nós (utilizando REST/RPC) e na construção de uma arquitetura segura e tolerante a falhas.

## 2. Status do Projeto

O projeto encontra-se **em fase de execução**. A infraestrutura base com Docker, a base de dados, o message broker e o serviço de registro (`registration-service`) estão funcionais. Os demais serviços (`middleware-service` e `discovery-service`) estão em fase inicial de desenvolvimento.

## 3. Arquitetura e Tecnologias

O sistema é construído sobre uma arquitetura de microsserviços orquestrada com Docker Compose.

* **Linguagem e Framework**: Java 17 e Spring Boot 3
* **Banco de Dados**: PostgreSQL
* **Mensageria (Pub/Sub)**: RabbitMQ
* **Containerização**: Docker e Docker Compose
* **Segurança**: Autenticação baseada em JSON Web Tokens (JWT)
* **Build e Dependências**: Apache Maven
* **Ferramentas de Desenvolvimento**: Git, GitHub, Postman, VS Code/IntelliJ

## 4. Pré-requisitos

Antes de começar, garanta que você tenha as seguintes ferramentas instaladas em seu ambiente de desenvolvimento:

* **Sistema Operacional**: Linux (recomendado), macOS ou Windows com WSL2.
* **Java Development Kit (JDK)**: Versão 17 ou superior.
* **Apache Maven**: Para gerenciamento de dependências e build.
* **Docker e Docker Compose**: Para orquestração dos containers.
* **Git**: Para controle de versão.
* **IDE**: IntelliJ IDEA ou VS Code.
* **Cliente HTTP**: Postman ou similar para testar a API.

## 5. Configuração do Ambiente

Siga os passos abaixo para configurar o projeto localmente.

1.  **Clonar o Repositório**
    ```bash
    git clone <URL_DO_SEU_REPOSITÓRIO>
    cd ProjetoSistemasDistribuidos-3691d235488c2ea9ba1a5fcd08d81fc18d180dcd
    ```

2.  **Configurar Variáveis de Ambiente**
    As configurações principais de banco de dados, RabbitMQ e JWT são gerenciadas pelo arquivo `docker-compose.yml`. No entanto, a chave secreta do JWT (`JWT_SECRET`) é definida neste arquivo e nos arquivos `application.properties` de cada serviço. Para um ambiente de produção, é fundamental que esta chave seja segura e gerenciada através de *secrets*.

    * **Arquivo**: `docker-compose.yml` e `services/*/src/main/resources/application.properties`
    * **Chave**: `JWT_SECRET`
    * **Valor Padrão**: `yourStrongJwtSecretKeyThatIsAtLeast256BitsLongForHS256`

## 6. Execução do Projeto

Com o Docker em execução, utilize o Docker Compose para construir as imagens e iniciar todos os serviços.

1.  **Construir e Iniciar os Serviços**
    Execute o comando a partir da raiz do projeto (onde o `docker-compose.yml` está localizado):
    ```bash
    docker-compose up --build
    ```
    Este comando irá baixar as imagens do PostgreSQL e RabbitMQ, construir as imagens para cada microsserviço e iniciar todos os containers.

2.  **Verificar o Status dos Containers**
    Para verificar se todos os serviços estão em execução, abra um novo terminal e execute:
    ```bash
    docker-compose ps
    ```
    Você deverá ver o status `Up` ou `running` para os containers `dtm-postgres`, `dtm-rabbitmq`, `dtm-registration-service`, entre outros.

3.  **Acessar Serviços**
    * **API (registration-service)**: `http://localhost:8080`
    * **RabbitMQ Management UI**: `http://localhost:15672` (login: `guest` / `guest`)

4.  **Parar os Serviços**
    Para parar a execução de todos os containers, pressione `Ctrl + C` no terminal onde o `docker-compose up` está rodando ou execute o seguinte comando no diretório raiz:
    ```bash
    docker-compose down
    ```

## 7. Uso da API

O `registration-service` é o ponto de entrada para registrar projetos no sistema.

#### **Endpoint: Registrar um Novo Projeto**

* **Método**: `POST`
* **URL**: `http://localhost:8080/api/projects`
* **Headers**:
    * `Content-Type: application/json`
* **Corpo da Requisição (Body)**:
    ```json
    {
      "name": "MeuProjetoAlfa",
      "region": "BR",
      "supportedBrokers": ["rabbitmq", "kafka"]
    }
    ```
* **Resposta de Sucesso (201 CREATED)**:
    ```json
    {
        "message": "Project successfully registered.",
        "appCode": 201,
        "data": {
            "id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
            "name": "MeuProjetoAlfa",
            "region": "BR",
            "supportedBrokers": ["rabbitmq", "kafka"],
            "location": "meuprojetoalfa.multibroker.com",
            "authToken": "eyJhbGciOiJIUzI1NiJ9..."
        },
        "status": "SUCCESS"
    }
    ```
    **IMPORTANTE**: Guarde o `id` e o `authToken` retornados. Eles serão necessários para autenticar as próximas requisições.

#### **Endpoint: Consultar um Projeto**

* **Método**: `GET`
* **URL**: `http://localhost:8080/api/projects/{projectId}`
* **Exemplo de URL**: `http://localhost:8080/api/projects/a1b2c3d4-e5f6-7890-1234-567890abcdef`
* **Headers**:
    * `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Resposta de Sucesso (200 OK)**:
    ```json
    {
        "message": "Project info successfully retrieved.",
        "appCode": 200,
        "data": {
            "id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
            "name": "MeuProjetoAlfa",
            "region": "BR",
            "supportedBrokers": ["rabbitmq", "kafka"],
            "location": "meuprojetoalfa.multibroker.com",
            "authToken": null
        },
        "status": "SUCCESS"
    }
    ```

## 8. Estrutura do Projeto

O repositório está organizado da seguinte forma:
