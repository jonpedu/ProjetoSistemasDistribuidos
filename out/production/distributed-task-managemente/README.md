# Sistema Distribuído de Gerenciamento de Tarefas (Completo)

## Sumário

1.  [Introdução](#1-introdução)
2.  [Status do Projeto](#2-status-do-projeto)
3.  [Arquitetura e Tecnologias](#3-arquitetura-e-tecnologias)
4.  [Pré-requisitos](#4-pré-requisitos)
5.  [Configuração do Ambiente](#5-configuração-do-ambiente)
6.  [Execução do Projeto](#6-execução-do-projeto)
7.  [Fluxo de Uso e API](#7-fluxo-de-uso-e-api)
8.  [Estrutura do Projeto](#8-estrutura-do-projeto)
9.  [Equipe](#9-equipe)

---

## 1. Introdução

Este é um projeto acadêmico desenvolvido para a disciplina de Sistemas Distribuídos do curso de Engenharia da Computação da Universidade Federal do Maranhão (UFMA).

O objetivo foi implementar um sistema distribuído para gerenciamento de tarefas, utilizando uma arquitetura de microsserviços. O foco do projeto esteve na comunicação em tempo real via Publish-Subscribe (Pub/Sub), sincronização de dados entre os nós, e na construção de uma arquitetura segura e tolerante a falhas.

## 2. Status do Projeto

O projeto encontra-se **finalizado**. Toda a infraestrutura base com Docker, a base de dados, o message broker e os serviços (`registration-service`, `middleware-service`, `discovery-service`) estão funcionais e completos conforme o escopo definido.

## 3. Arquitetura e Tecnologias

O sistema é construído sobre uma arquitetura de microsserviços orquestrada com Docker Compose.

* **Linguagem e Framework**: Java 17 e Spring Boot 3
* **Banco de Dados**: PostgreSQL
* **Mensageria (Pub/Sub)**: RabbitMQ
* **Containerização**: Docker e Docker Compose
* **Segurança**: Autenticação baseada em JSON Web Tokens (JWT)
* **Build e Dependências**: Apache Maven
* **Tolerância a Falhas**: Rastreamento de réplicas de serviços para suportar uma arquitetura primária-secundária.
* **Ferramentas de Desenvolvimento**: Git, GitHub, Postman, VS Code/IntelliJ.

O fluxo arquitetural se dá da seguinte forma:
1.  **Registration Service**: Funciona como o ponto de entrada. Os projetos são registrados aqui para obter um `authToken`.
2.  **Middleware Service**: Utiliza o `authToken` para gerenciar produtores (`senders`) e consumidores (`receivers`). Ele atua como uma camada de abstração sobre o RabbitMQ, lidando com o envio e recebimento de mensagens.
3.  **Discovery Service**: Ouve eventos do `middleware-service` para rastrear onde cada consumidor está ativo (qual réplica do middleware), permitindo o roteamento inteligente e a tolerância a falhas.

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
    git clone <URL_DO_REPOSITÓRIO>
    cd ProjetoSistemasDistribuidos-62f50910776682fc32bd3829145ebf6f700ab91e
    ```

2.  **Configurar Variáveis de Ambiente**
    As configurações principais de banco de dados, RabbitMQ e JWT são gerenciadas pelo arquivo `docker-compose.yml`. A chave secreta do JWT (`JWT_SECRET`) é definida neste arquivo e replicada nos arquivos `application.properties` de cada serviço.

    * **Arquivo**: `docker-compose.yml` e `services/*/src/main/resources/application.properties`
    * **Chave**: `JWT_SECRET`
    * **Valor Padrão**: `yourStrongJwtSecretKeyThatIsAtLeast256BitsLongForHS256`

## 6. Execução do Projeto

Com o Docker em execução, utilize o Docker Compose para construir as imagens e iniciar todos os serviços.

1.  **Construir e Iniciar os Serviços**
    Execute o comando a partir da raiz do projeto:
    ```bash
    docker-compose up --build
    ```
    Este comando irá baixar as imagens necessárias, construir as imagens para cada microsserviço e iniciar todos os containers.

2.  **Verificar o Status dos Containers**
    Para verificar se todos os serviços estão em execução, abra um novo terminal e execute:
    ```bash
    docker-compose ps
    ```
    Você deverá ver o status `Up` ou `running` para os containers `dtm-postgres`, `dtm-rabbitmq`, `dtm-registration-service`, `dtm-middleware-service` e `dtm-discovery-service`.

3.  **Acessar Serviços**
    * **Registration Service**: `http://localhost:8080`
    * **Middleware Service**: `http://localhost:8081`
    * **Discovery Service**: `http://localhost:8082`
    * **RabbitMQ Management UI**: `http://localhost:15672` (login: `guest` / `guest`)

4.  **Parar os Serviços**
    Para parar a execução de todos os containers, pressione `Ctrl + C` no terminal onde o `docker-compose up` está rodando ou execute:
    ```bash
    docker-compose down
    ```

## 7. Fluxo de Uso e API

O fluxo de uso completo envolve registrar um projeto, criar produtores e consumidores, e então enviar e receber mensagens.

### Passo 1: Registrar um Projeto (`registration-service`)

Primeiro, registre seu projeto para obter um token de autenticação.

* **Método**: `POST`
* **URL**: `http://localhost:8080/api/projects`
* **Corpo da Requisição**:
    ```json
    {
      "name": "MeuProjetoFinal",
      "region": "BR",
      "supportedBrokers": ["rabbitmq"]
    }
    ```
* **Resposta de Sucesso**:
    ```json
    {
        "message": "Project successfully registered.",
        "appCode": 201,
        "data": {
            "id": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
            "name": "MeuProjetoFinal",
            "region": "BR",
            "supportedBrokers": ["rabbitmq"],
            "location": "meuprojetofinal.multibroker.com",
            "authToken": "eyJhbGciOiJIUzI1NiJ9..."
        },
        "status": "SUCCESS"
    }
    ```
**Guarde o `id` e o `authToken`. Eles serão usados em todas as chamadas seguintes.**

### Passo 2: Registrar um Produtor (`middleware-service`)

Use o `authToken` do projeto para registrar um produtor de mensagens.

* **Método**: `POST`
* **URL**: `http://localhost:8081/api/senders`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Corpo da Requisição**:
    ```json
    {
        "username": "meu-produtor-01",
        "password": "Password123#",
        "broker": "rabbitmq",
        "strategy": "direct",
        "exchange": "exchange.direct.tasks",
        "queue": "queue.tasks.new"
    }
    ```
* **Resposta de Sucesso**: Retorna os detalhes do produtor criado, incluindo seu ID. Guarde o `id` do produtor.

### Passo 3: Registrar um Consumidor (`middleware-service`)

Use o `authToken` para registrar um consumidor que irá ouvir as mensagens.

* **Método**: `POST`
* **URL**: `http://localhost:8081/api/receivers`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Corpo da Requisição**:
    ```json
    {
        "username": "meu-consumidor-01",
        "password": "Password123#",
        "persistenceTime": 60000,
        "broker": "rabbitmq",
        "strategy": "direct",
        "exchange": "exchange.direct.tasks",
        "queue": "queue.tasks.new"
    }
    ```
* **Resposta de Sucesso**: Retorna os detalhes do consumidor criado, incluindo seu ID. Guarde o `id` do consumidor.

### Passo 4: Conectar o Consumidor para Receber Mensagens

Para receber mensagens em tempo real, o cliente deve se conectar a um endpoint de Server-Sent Events (SSE).

* **Método**: `GET`
* **URL**: `http://localhost:8081/api/receivers/{consumerId}/receive`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`

Esta conexão permanecerá aberta, e o servidor enviará eventos de `message` sempre que uma nova mensagem for recebida pelo consumidor no broker.

### Passo 5: Enviar uma Mensagem com o Produtor

Agora, use o produtor para enviar uma mensagem.

* **Método**: `POST`
* **URL**: `http://localhost:8081/api/senders/{producerId}/send`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Corpo da Requisição**:
    ```json
    {
        "data": "{\"task_id\": 123, \"description\": \"Finalizar a documentação do projeto.\"}"
    }
    ```
* **Resposta de Sucesso**: `200 OK` com a mensagem "Message successfully sent.". O cliente conectado no Passo 4 receberá o conteúdo desta mensagem.

### Passo 6: Consultar Réplicas Ativas (`discovery-service`)

O `discovery-service` rastreia automaticamente onde os consumidores estão conectados. Outros serviços podem consultar esta informação.

* **Método**: `GET`
* **URL**: `http://localhost:8082/api/receivers/{consumerId}/replica`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Resposta de Sucesso**:
    ```json
    {
        "message": "Receiver replica info retrieved.",
        "appCode": 200,
        "data": {
            "consumerId": "...",
            "replicaIp": "localhost:8081",
            "projectId": "..."
        },
        "status": "SUCCESS"
    }
    ```

## 8. Equipe

* **FRANCISCO GABRIEL SANTOS** - 2020014544
* **KEVEN GUSTAVO DOS SANTOS GOMES** - 2020034420
* **KAUAN GARCIA PEREIRA MARTINS** - 2021026595
* **JOÃO PEDRO MIRANDA SOUSA** - 2022011087
* **WESLEY DOS SANTOS GATINHO** - 2020051056