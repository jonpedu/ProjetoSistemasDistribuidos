# Middleware de Mensageria como Serviço (MaaS) com Integração InterSCity

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [O que é o Projeto](#o-que-é-o-projeto)
3. [Arquitetura do Sistema](#arquitetura-do-sistema)
4. [Componentes Principais](#componentes-principais)
5. [Casos de Uso Reais](#casos-de-uso-reais)
6. [Tecnologias Utilizadas](#tecnologias-utilizadas)
7. [Instalação e Configuração](#instalação-e-configuração)
8. [Guia de Uso](#guia-de-uso)
9. [API Reference](#api-reference)
10. [Monitoramento e Logs](#monitoramento-e-logs)
11. [Troubleshooting](#troubleshooting)
12. [Contribuição](#contribuição)

---

## 🎯 Visão Geral

Este projeto é um **Middleware de Mensageria como Serviço (MaaS - Messaging as a Service)** desenvolvido para a disciplina de Sistemas Distribuídos da UFMA. O sistema funciona como uma **ponte inteligente** entre aplicações e plataformas de cidades inteligentes, especificamente integrando com a plataforma **InterSCity**.

### 🏆 Objetivos Principais

- **Simplificar** o desenvolvimento de aplicações IoT
- **Padronizar** a comunicação entre diferentes sistemas
- **Integrar** facilmente com plataformas de cidades inteligentes
- **Fornecer** uma infraestrutura escalável e confiável
- **Suportar** múltiplos protocolos de mensageria

---

## 🔍 O que é o Projeto

### Definição Técnica

O sistema é uma **infraestrutura de comunicação distribuída** que:

1. **Gerencia mensagens** entre produtores e consumidores
2. **Roteia dados** para diferentes brokers de mensageria
3. **Traduz formatos** para integração com plataformas externas
4. **Fornece interface** amigável para desenvolvedores

### Integração InterSCity

- **InterSCity** é uma plataforma brasileira para cidades inteligentes
- Desenvolvida pela UFMA (Universidade Federal do Maranhão)
- API disponível em: `https://cidadesinteligentes.lsdi.ufma.br/interscity_lh`
- O sistema traduz mensagens internas para o formato InterSCity

---

## 🏗️ Arquitetura do Sistema

### Diagrama de Arquitetura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Middleware      │    │   InterSCity    │
│   (Frontend)    │◄──►│  Service         │◄──►│   Adapter       │
│                 │    │  (Orquestrador)  │    │   (Tradutor)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │     RabbitMQ     │    │   InterSCity    │
                       │   (Mensageria)   │    │   Platform      │
                       └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │    PostgreSQL    │
                       │   (Database)     │
                       └──────────────────┘
```

### Fluxo de Dados

1. **Frontend Flutter** envia requisições para o Middleware
2. **Middleware Service** processa e roteia mensagens
3. **RabbitMQ** gerencia filas e exchanges
4. **InterSCity Adapter** traduz e envia para a plataforma
5. **InterSCity Platform** recebe e processa dados

---

## 🧩 Componentes Principais

### 1. Frontend Flutter (`front-end-flutter/`)

**Tecnologia**: Flutter 3.16+
**Porta**: Configurável (Android, iOS, Web)

**Funcionalidades**:
- Dashboard com visão geral do sistema
- Registro e gerenciamento de projetos
- Criação e configuração de produtores
- Envio de mensagens em tempo real
- Monitoramento do sistema

**Estrutura**:
```
lib/
├── main.dart                 # Ponto de entrada
├── models/                   # Modelos de dados
├── services/                 # Serviços de API
├── providers/               # Gerenciamento de estado
├── screens/                 # Telas da aplicação
└── widgets/                 # Widgets reutilizáveis
```

### 2. Registration Service (`services/registration-service/`)

**Tecnologia**: Spring Boot
**Porta**: 8080
**Função**: Gerenciar projetos e autenticação

**Endpoints**:
- `POST /api/projects` - Registrar novo projeto
- `GET /api/projects/{id}` - Buscar projeto
- `DELETE /api/projects/{id}` - Remover projeto

### 3. Middleware Service (`services/middleware-service/`)

**Tecnologia**: Spring Boot
**Porta**: 8081
**Função**: Orquestrar mensagens e produtores/consumidores

**Funcionalidades**:
- Gerenciamento de produtores (senders)
- Gerenciamento de consumidores (receivers)
- Roteamento de mensagens
- Integração com múltiplos brokers

**Brokers Suportados**:
- RabbitMQ
- Kafka
- ActiveMQ5
- InterSCity Adapter

### 4. Discovery Service (`services/discovery-service/`)

**Tecnologia**: Spring Boot
**Porta**: 8082
**Função**: Descoberta e registro de consumidores

**Endpoints**:
- `POST /api/receivers` - Registrar consumidor
- `GET /api/receivers` - Listar consumidores
- `DELETE /api/receivers/{id}` - Remover consumidor

### 5. InterSCity Adapter Service (`services/interscity-adapter-service/`)

**Tecnologia**: Spring Boot
**Porta**: 8083
**Função**: Adaptar mensagens para o formato InterSCity

**Funcionalidades**:
- Receber mensagens via RabbitMQ
- Traduzir formato interno para InterSCity
- Enviar dados para API InterSCity
- Tratar erros de comunicação

### 6. Infraestrutura

**Banco de Dados**: PostgreSQL 13
- **Porta**: 5432
- **Database**: dtm_db
- **Usuário**: user
- **Senha**: password

**Message Broker**: RabbitMQ 3
- **Porta AMQP**: 5672
- **Porta Management**: 15672
- **Usuário**: guest
- **Senha**: guest

---

## 🌍 Casos de Uso Reais

### 🏙️ Cidades Inteligentes

#### Sensores de Trânsito
```json
{
  "sensor_id": "traffic_001",
  "location": "Av. Principal, 123",
  "vehicle_count": 45,
  "average_speed": 35.5,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Sensores de Qualidade do Ar
```json
{
  "sensor_id": "air_quality_001",
  "location": "Parque Central",
  "pm25": 12.3,
  "pm10": 25.7,
  "co2": 420,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Sensores de Iluminação
```json
{
  "sensor_id": "lighting_001",
  "location": "Rua das Flores",
  "brightness": 0.8,
  "energy_consumption": 2.3,
  "status": "on",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 🏭 Indústria 4.0

#### Sensores Industriais
```json
{
  "machine_id": "press_001",
  "temperature": 85.2,
  "pressure": 150.5,
  "vibration": 0.02,
  "status": "operational",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Sistemas de Controle
```json
{
  "controller_id": "valve_001",
  "position": 75.0,
  "flow_rate": 120.5,
  "command": "open",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 🏠 Smart Home

#### Dispositivos Domésticos
```json
{
  "device_id": "thermostat_001",
  "temperature": 22.5,
  "humidity": 45.2,
  "mode": "cooling",
  "energy_consumption": 1.8,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Sensores de Segurança
```json
{
  "sensor_id": "motion_001",
  "location": "Sala de Estar",
  "motion_detected": true,
  "confidence": 0.95,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

## 🛠️ Tecnologias Utilizadas

### Backend
- **Java 17** - Linguagem principal
- **Spring Boot 3.2.5** - Framework de desenvolvimento
- **Spring AMQP** - Integração com RabbitMQ
- **Spring Data JPA** - Persistência de dados
- **PostgreSQL** - Banco de dados relacional
- **RabbitMQ** - Message broker
- **JWT** - Autenticação e autorização

### Frontend
- **Flutter 3.16+** - Framework multiplataforma
- **Dart 3.2.0+** - Linguagem de programação
- **Provider** - Gerenciamento de estado
- **HTTP** - Comunicação com APIs
- **Material Design 3** - Interface de usuário

### Infraestrutura
- **Docker** - Containerização
- **Docker Compose** - Orquestração de containers
- **Maven** - Gerenciamento de dependências
- **Gradle** - Build system (Android)

### Plataformas Suportadas
- ✅ **Android** - APK nativo
- ✅ **iOS** - App nativo
- ✅ **Web** - Aplicação web responsiva

---

## 🚀 Instalação e Configuração

### Pré-requisitos

- **Docker** e **Docker Compose** instalados
- **Flutter SDK** 3.16.0 ou superior
- **Java 17** (para desenvolvimento local)
- **Maven** (para desenvolvimento local)

### 1. Clone o Repositório

```bash
git clone <url-do-repositorio>
cd ProjetoSistemasDistribuidos
```

### 2. Configurar Backend

```bash
# Iniciar todos os serviços
docker compose up -d

# Verificar status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f
```

### 3. Configurar Frontend

```bash
cd front-end-flutter

# Instalar dependências
flutter pub get

# Executar aplicação
flutter run -d chrome  # Para web
flutter run -d android # Para Android
flutter run -d ios     # Para iOS
```

### 4. Verificar Conectividade

```bash
# Verificar se todos os serviços estão rodando
curl http://localhost:8080/api/projects  # Registration Service
curl http://localhost:8081/api/senders   # Middleware Service
curl http://localhost:8082/api/receivers # Discovery Service
curl http://localhost:8083               # InterSCity Adapter
```

---

## 📖 Guia de Uso

### 1. Registrando um Projeto

1. **Acesse** a tela "Registrar Projeto" no app Flutter
2. **Preencha** os campos obrigatórios:
   - Nome do projeto
   - Descrição
   - Região (ex: BR)
   - Brokers suportados
3. **Clique** em "Registrar Projeto"
4. **Guarde** o token de autenticação gerado

### 2. Criando Produtores

1. **Acesse** "Gerenciar Produtores"
2. **Preencha** os dados:
   - Nome do produtor
   - Descrição
   - Broker (rabbitmq, kafka, activemq5, interscity-adapter)
   - Estratégia (direct, topic, fanout, headers)
   - Exchange e Queue
3. **Clique** em "Registrar Produtor"

### 3. Enviando Mensagens

1. **Acesse** "Enviar Mensagens"
2. **Selecione** um produtor da lista
3. **Insira** os dados JSON da mensagem
4. **Clique** em "Enviar Mensagem"
5. **Monitore** o status da mensagem

### 4. Monitorando o Sistema

1. **Acesse** "Monitoramento"
2. **Visualize** estatísticas em tempo real:
   - Status dos serviços
   - Número de produtores ativos
   - Mensagens enviadas
   - Consumidores conectados

---

## 🔌 API Reference

### Registration Service (Porta 8080)

#### Registrar Projeto
```http
POST /api/projects
Content-Type: application/json

{
  "name": "Meu Projeto IoT",
  "region": "BR",
  "supportedBrokers": ["rabbitmq", "interscity-adapter"]
}
```

#### Buscar Projeto
```http
GET /api/projects/{projectId}
Authorization: Bearer {token}
```

### Middleware Service (Porta 8081)

#### Criar Produtor
```http
POST /api/senders
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Sensor de Temperatura",
  "description": "Sensor IoT para monitoramento",
  "broker": "interscity-adapter",
  "strategy": "interscity-adapter-strategy",
  "exchange": "sensors.exchange",
  "queue": "temperature.queue"
}
```

#### Enviar Mensagem
```http
POST /api/senders/{senderId}/send
Authorization: Bearer {token}
Content-Type: application/json

{
  "data": {
    "sensor_id": "temp_001",
    "temperature": 25.5,
    "humidity": 60.2,
    "timestamp": "2024-01-15T10:30:00Z"
  },
  "headers": {
    "priority": "high",
    "location": "sala_principal"
  }
}
```

### Discovery Service (Porta 8082)

#### Registrar Consumidor
```http
POST /api/receivers
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Dashboard Monitor",
  "description": "Dashboard para visualização de dados",
  "broker": "rabbitmq",
  "strategy": "topic",
  "exchange": "sensors.exchange",
  "queue": "dashboard.queue"
}
```

---

## 📊 Monitoramento e Logs

### Script de Monitoramento

O projeto inclui um script para monitorar logs em tempo real:

```bash
# Executar script de monitoramento
./monitor-intercity-logs.sh
```

**Opções disponíveis**:
1. Monitorar logs do Middleware Service
2. Monitorar logs do InterSCity Adapter Service
3. Monitorar logs do RabbitMQ
4. Monitorar todos os logs simultaneamente
5. Verificar status dos containers

### Logs Importantes

#### Middleware Service
```
🚀 [MIDDLEWARE] Iniciando Middleware Service...
📋 [MIDDLEWARE] Porta: 8081
✅ [MIDDLEWARE] Middleware Service iniciado com sucesso!
```

#### InterSCity Adapter
```
🚀 [INTERSCITY ADAPTER] Iniciando InterSCity Adapter Service...
📋 [INTERSCITY ADAPTER] Porta: 8083
✅ [INTERSCITY ADAPTER] InterSCity Adapter Service iniciado com sucesso!
```

#### Comunicação InterSCity
```
🌐 [INTERSCITY SERVICE] Iniciando comunicação com InterSCity...
📤 [INTERSCITY SERVICE] Enviando requisição para InterSCity...
✅ [INTERSCITY SERVICE] Resposta recebida do InterSCity!
```

### Métricas de Monitoramento

- **Status dos serviços** (UP/DOWN)
- **Número de mensagens processadas**
- **Tempo de resposta das APIs**
- **Erros de comunicação**
- **Uso de recursos (CPU, memória)**

---

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Serviços não iniciam
```bash
# Verificar logs dos containers
docker compose logs

# Verificar se as portas estão disponíveis
netstat -tulpn | grep :8080
netstat -tulpn | grep :8081
netstat -tulpn | grep :8082
netstat -tulpn | grep :8083
```

#### 2. Erro de conexão com banco
```bash
# Verificar se PostgreSQL está rodando
docker compose ps postgres

# Verificar logs do PostgreSQL
docker compose logs postgres
```

#### 3. Erro de comunicação com RabbitMQ
```bash
# Verificar se RabbitMQ está rodando
docker compose ps rabbitmq

# Acessar interface web do RabbitMQ
# http://localhost:15672
# Usuário: guest, Senha: guest
```

#### 4. Erro de integração com InterSCity
```bash
# Verificar conectividade com InterSCity
curl -I https://cidadesinteligentes.lsdi.ufma.br/interscity_lh

# Verificar logs do InterSCity Adapter
docker compose logs interscity-adapter-service
```

### Comandos Úteis

```bash
# Reiniciar todos os serviços
docker compose restart

# Parar todos os serviços
docker compose down

# Reconstruir imagens
docker compose build --no-cache

# Limpar volumes (cuidado: apaga dados)
docker compose down -v
```

---

## 🤝 Contribuição

### Como Contribuir

1. **Fork** o repositório
2. **Crie** uma branch para sua feature
   ```bash
   git checkout -b feature/nova-funcionalidade
   ```
3. **Faça** suas alterações
4. **Teste** localmente
   ```bash
   docker compose up -d
   flutter test
   ```
5. **Commit** suas mudanças
   ```bash
   git commit -m "Adiciona nova funcionalidade"
   ```
6. **Push** para a branch
   ```bash
   git push origin feature/nova-funcionalidade
   ```
7. **Abra** um Pull Request

### Padrões de Código

- **Java**: Seguir convenções do Spring Boot
- **Dart/Flutter**: Seguir Dart Style Guide
- **Commits**: Usar mensagens descritivas
- **Documentação**: Manter README atualizado

### Estrutura de Branches

- `main` - Código estável
- `develop` - Desenvolvimento
- `feature/*` - Novas funcionalidades
- `bugfix/*` - Correções de bugs
- `hotfix/*` - Correções urgentes

---

## 📄 Licença

Este projeto é parte do trabalho acadêmico da disciplina de **Sistemas Distribuídos** da **Universidade Federal do Maranhão (UFMA)**.

### Autores

- Desenvolvido para fins educacionais
- Integração com plataforma InterSCity da UFMA
- Suporte a aplicações de cidades inteligentes

### Agradecimentos

- **UFMA** - Universidade Federal do Maranhão
- **InterSCity** - Plataforma de cidades inteligentes
- **Spring Boot** - Framework de desenvolvimento
- **Flutter** - Framework multiplataforma

---

## 📞 Suporte

### Para Dúvidas ou Problemas

1. **Verifique** se o backend está rodando
2. **Confirme** as URLs de conexão
3. **Verifique** os logs do Flutter (`flutter logs`)
4. **Consulte** a documentação do Flutter
5. **Abra** uma issue no repositório

### Recursos Adicionais

- [Documentação Flutter](https://docs.flutter.dev/)
- [Documentação Spring Boot](https://spring.io/projects/spring-boot)
- [Documentação RabbitMQ](https://www.rabbitmq.com/documentation.html)
- [Plataforma InterSCity](https://cidadesinteligentes.lsdi.ufma.br/)

---

**Desenvolvido para a disciplina de Sistemas Distribuídos - UFMA**

*Última atualização: Janeiro 2024* 