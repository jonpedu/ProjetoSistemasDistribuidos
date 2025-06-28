# Middleware de Mensageria como Serviço com Integração InterSCity

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

O objetivo foi implementar um Middleware de Mensageria como Serviço (PaaS), utilizando uma arquitetura de microsserviços. O sistema permite que diferentes aplicações e dispositivos (produtores) enviem mensagens para uma plataforma central, que as roteia de forma confiável para outras aplicações (consumidores) através do padrão Publish-Subscribe.

Como caso de uso prático, o projeto inclui um serviço adaptador que integra o middleware com a plataforma de Cidades Inteligentes InterSCity.

## 2. Status do Projeto

O projeto encontra-se **finalizado**. Toda a infraestrutura base com Docker, a base de dados, o message broker e os serviços (`registration-service`, `middleware-service`, `discovery-service`) estão funcionais e completos conforme o escopo definido.

O projeto encontra-se **finalizado** e **funcional**. Toda a infraestrutura base com Docker, o banco de dados (`PostgreSQL`), o message broker (`RabbitMQ`) e os microsserviços estão completos. O fluxo, desde o envio de uma mensagem até seu registro na plataforma `InterSCity`, foi testado e validado.

## 3. Arquitetura e Tecnologias

O sistema é construído sobre uma arquitetura de microsserviços orquestrada com Docker Compose.

* **Linguagem e Framework**: Java 17 e Spring Boot 3
* **Banco de Dados**: PostgreSQL
* **Mensageria (Pub/Sub)**: RabbitMQ
* **Containerização**: Docker e Docker Compose
* **Segurança**: Autenticação baseada em JSON Web Tokens (JWT)
* **Build e Dependências**: Apache Maven
* **Ferramentas de Desenvolvimento**: Git, GitHub, Postman, VS Code/IntelliJ.

O fluxo arquitetural se dá da seguinte forma:
1.  **Registration Service**: FPonto de entrada para registrar um projeto (ex: "Monitoramento UFMA") e obter um `authToken` de acesso.
2.  **Middleware Service**: Usa o `authToken` para gerenciar "Senders" (produtores) e "Receivers" (consumidores). Atua como uma camada de abstração sobre o RabbitMQ, lidando com o envio e recebimento de mensagens.
3.  **Discovery Service**: Ouve eventos do `middleware-service` para rastrear onde cada consumidor está ativo (qual réplica do middleware), permitindo o roteamento inteligente.
4. **InterSCity Adapter Service**: Atua como um consumidor especializado. Ele ouve mensagens de uma fila específica no RabbitMQ, as traduz e as envia como novos recursos para a API da plataforma InterSCity.

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
    As configurações são gerenciadas pelo arquivo `docker-compose.yml`. A variável mais importante é a `INTERSCITY_API_URL` dentro da definição do `interscity-adapter-service`, que deve apontar para a URL correta da plataforma InterSCity.

## 6. Execução do Projeto

Com o Docker em execução, utilize o Docker Compose para construir as imagens e iniciar todos os serviços.

1.  **Construir e Iniciar os Serviços**

    Execute o comando a partir da raiz do projeto. Use a sintaxe moderna do Docker Compose (com espaço, sem hífen):
    ```bash
    docker compose up --build -d
    ```
    Este comando irá baixar as imagens necessárias, construir as imagens para cada microsserviço e iniciar todos os containers.

    O `-d` executa os containers em segundo plano (detached mode).

2.  **Verificar o Status dos Containers**

    Para verificar se todos os serviços estão em execução, abra um novo terminal e execute:
    ```bash
    docker compose ps
    ```
    Você deverá ver o status `Up` ou `running` para os containers `dtm-postgres`, `dtm-rabbitmq`, `dtm-registration-service`, `dtm-middleware-service` e `dtm-discovery-service`.

3.  **Acessar Serviços**
    * **Registration Service**: `http://localhost:8080`
    * **Middleware Service**: `http://localhost:8081`
    * **Discovery Service**: `http://localhost:8082`
    * **RabbitMQ Management UI**: `http://localhost:15672` (login: `guest` / `guest`)

4.  **Parar os Serviços**

    Para parar a execução de todos os containers, pressione `Ctrl + C` no terminal onde o `docker compose up` está rodando ou execute:
    ```bash
    docker compose down
    ```

## 7. Fluxo de Uso e API

Este é o fluxo completo para enviar um dado de um "sensor" até a plataforma InterSCity.

### Pré-requisito: Criar a "Capacidade" no InterSCity

Antes de registrar um sensor, a plataforma precisa saber que "tipo" de dado ele mede. Execute esta requisição uma vez para criar a capacidade.

* **Método**: `POST`
* **URL**: `https://cidadesinteligentes.lsdi.ufma.br/interscity_lh/catalog/capabilities/`
* **Corpo da Requisição**:
    ```json
    {
      "name": "room_occupancy",
      "description": "Numero de ocupantes em uma sala",
      "capability_type": "sensor"
    }
    ```

### Passo 1: Registrar um Projeto no Middleware

* **Método**: `POST`
* **URL**: `http://localhost:8080/api/projects`
* **Corpo da Requisição**:
    ```json
    {
      "name": "MonitoramentoSalasUFMA",
      "region": "BR",
      "supportedBrokers": ["rabbitmq"]
    }
    ```
* **Ação**: Guarde o `authToken` retornado na resposta.

### Passo 2: Registrar o "Sensor" como um Produtor (Sender)

* **Método**: `POST`
* **URL**: `http://localhost:8081/api/senders`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Corpo da Requisição**:
    ```json
    {
        "username": "sensorocupacaosala01",
        "password": "Password123#",
        "broker": "rabbitmq",
        "strategy": "direct",
        "exchange": "exchange.direct.tasks",
        "queue": "queue.tasks.new"
    }
    ```
* **Ação**: Guarde o `id` do produtor retornado na resposta.

### Passo 3: Enviar os Dados do Sensor

Esta é a ação que dispara todo o fluxo.

* **Método**: `POST`
* **URL**: `http://localhost:8081/api/senders/{ID_DO_PRODUTOR_AQUI}/send`
* **Headers**: `Authorization: Bearer <SEU_AUTH_TOKEN_AQUI>`
* **Corpo da Requisição**:
    ```json
    {
        "data": "{\"description\": \"Sensor de Ocupacao - Sala 1 CCET\", \"capabilities\": [\"room_occupancy\"], \"status\": \"active\", \"lat\": -2.55, \"lon\": -44.30}"
    }
    ```
* **Resultado**: O `middleware-service` retornará `200 OK`. O `interscity-adapter-service` receberá a mensagem e a registrará na plataforma InterSCity. Você pode confirmar o sucesso olhando os logs do adaptador (`docker-compose logs -f interscity-adapter-service`) e verificando o recurso criado na plataforma.

---

## 8. Estrutura do Projeto 

```
├── Documents/
│   └── PLANEJAMENTO SISTEMAS.pdf
├── services/
│   ├── discovery-service/
│   │   └── src/main/java/com/ufma/tap/
│   │       └── discovery/
│   │           └── pom.xml
│   ├── interscity-adapter-service/
│   │   └── src/main/java/com/ufma/tap/
│   │       └── interscity/
│   │           └── pom.xml  
|   ├── middleware-service/
│   │   └── src/main/java/com/ufma/tap/
│   │       └── middleware/
│   │           └── pom.xml
|   └── registration-service/
│       └── src/main/java/com/ufma/tap/
│           └── registration/
│               └── pom.xml
├── .gitignore
├── docker-compose.yml
└── README.md
```

Cada pasta de serviço contém uma aplicação Spring Boot completa e independente, com seu próprio `pom.xml` e `Dockerfile`.

## 9. Equipe

* **FRANCISCO GABRIEL SANTOS** - 2020014544
* **KEVEN GUSTAVO DOS SANTOS GOMES** - 2020034420
* **KAUAN GARCIA PEREIRA MARTINS** - 2021026595
* **JOÃO PEDRO MIRANDA SOUSA** - 2022011087
* **WESLEY DOS SANTOS GATINHO** - 2020051056

**Professor Orientador**: Dr. LUIZ HENRIQUE NEVES RODRIGUES




