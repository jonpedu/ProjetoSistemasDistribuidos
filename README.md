# Sistema Distribuído de Gerenciamento de Tarefas

Este projeto implementa um sistema distribuído de gerenciamento de tarefas, utilizando uma arquitetura de microsserviços baseada em Java com Spring Boot, PostgreSQL como banco de dados e RabbitMQ para comunicação assíncrona. O objetivo é desenvolver um sistema que permita o gerenciamento de tarefas em ambientes distribuídos, com foco em comunicação em tempo real via Publish-Subscribe (Pub/Sub), sincronização de dados entre nós usando REST/RPC e uma arquitetura tolerante a falhas e segura[cite: 1].

## Sumário

1.  [Pré-requisitos](#1-pré-requisitos)
    * [Sistema Operacional](#sistema-operacional)
    * [Java Development Kit (JDK) 17](#java-development-kit-jdk-17)
    * [Apache Maven](#apache-maven)
    * [Git](#git)
    * [Docker e Docker Compose](#docker-e-docker-compose)
    * [IDE (IntelliJ IDEA Community Edition)](#ide-intellij-idea-community-edition)
    * [Postman](#postman)
2.  [Configuração do Ambiente](#2-configuração-do-ambiente)
    * [Clonar o Repositório](#clonar-o-repositório)
    * [Configurar o Projeto na IDE](#configurar-o-projeto-na-ide)
    * [Configurar docker-compose.yml](#configurar-docker-composeyml)
    * [Configurar `Dockerfile`s](#configurar-dockerfiles)
    * [Configurar application.properties](#configurar-applicationproperties)
3.  [Execução do Projeto](#3-execução-do-projeto)
    * [Construir e Iniciar os Serviços](#construir-e-iniciar-os-serviços)
    * [Verificar o Status dos Containers](#verificar-o-status-dos-containers)
    * [Verificar os Logs](#verificar-os-logs)
4.  [Testando o registration-service](#4-testando-o-registration-service)
    * [Endpoint de Registro de Projeto (POST)](#endpoint-de-registro-de-projeto-post)
    * [Endpoint de Consulta de Projeto (GET)](#endpoint-de-consulta-de-projeto-get)
5.  [Desligar os Serviços](#5-desligar-os-serviços)
6.  [Estrutura do Projeto](#6-estrutura-do-projeto)
7.  [Próximos Passos (Desenvolvimento)](#7-próximos-passos-desenvolvimento)

---

## 1. Pré-requisitos

Este guia assume que você está usando uma distribuição Linux baseada em Debian/Ubuntu (como o Ubuntu 24.04 LTS). Para outras distribuições ou sistemas operacionais (macOS, Windows), algumas etapas de instalação podem variar.

### Sistema Operacional

* *Ubuntu 24.04 LTS* (ou similar).

### Java Development Kit (JDK) 17

O JDK 17 é necessário para compilar e executar as aplicações Spring Boot.

bash
sudo apt update
sudo apt install openjdk-17-jdk
java -version
javac -version

### 