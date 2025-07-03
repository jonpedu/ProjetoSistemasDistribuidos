# 🚦 Middleware InterSCity - Frontend Flutter

## 📱 Sobre o App

Este é o frontend Flutter do **Middleware InterSCity**, um sistema que facilita a comunicação entre aplicações e a plataforma **InterSCity** (plataforma brasileira para cidades inteligentes da UFMA).

## 🎯 Funcionalidades Principais

### 1. **Dashboard de Sensores de Trânsito** 🚗
- Visualização de sensores de trânsito em tempo real
- Dados de veículos, velocidade e congestionamento
- Envio direto de dados para InterSCity via middleware
- Interface intuitiva com status coloridos

### 2. **Integração InterSCity** ☁️
- Monitoramento da integração com InterSCity
- Logs de comunicação em tempo real
- Teste de conectividade
- Visualização do fluxo de dados

### 3. **Demonstração Interativa** ▶️
- Demonstração visual do fluxo de dados
- Animações mostrando como o middleware facilita
- Teste prático da integração
- Explicação das vantagens do sistema

### 4. **Nova Integração InterSCity** 🟢
- Criação de novos sensores integrados ao InterSCity
- Formulário para configuração de tipo, localização e parâmetros do sensor
- Envio automático de dados de exemplo para InterSCity via middleware
- Suporte a múltiplos tipos de sensores (trânsito, ar, iluminação, lixeira, estacionamento)
- Demonstração prática de como o middleware facilita a criação de integrações

## 📋 Detalhamento dos Módulos

### **🏠 Tela Inicial (home_screen.dart)**
**O que faz:**
- Ponto de entrada principal da aplicação
- Registro e gerenciamento de projetos
- Menu principal com navegação para todas as funcionalidades
- Exibição do status do projeto atual
- Logout e gerenciamento de sessão

**Funcionalidades específicas:**
- Tela de boas-vindas para novos usuários
- Formulário de registro de projetos
- Grid de cards para navegação
- Informações do projeto ativo
- Dialog de confirmação para logout

### **🟢 Nova Integração InterSCity (new_interscity_integration_screen.dart)**
**O que faz:**
- Permite criar novas integrações/sensores para o InterSCity de forma simples
- Formulário para configurar tipo de sensor, localização, coordenadas, região e descrição
- Suporte a múltiplos tipos de sensores (trânsito, ar, iluminação, lixeira, estacionamento)
- Envia dados de exemplo para o InterSCity via middleware
- Demonstra o fluxo App → Middleware → InterSCity de forma prática

**Funcionalidades específicas:**
- Seleção visual do tipo de sensor com ícones e cores
- Campos para nome, localização, latitude, longitude, região e descrição
- Geração automática de dados de exemplo conforme o tipo de sensor
- Feedback visual de sucesso ou erro na criação da integração
- Explicação visual do fluxo de integração

### **🚦 Dashboard de Sensores de Trânsito (traffic_sensor_dashboard.dart)**
**O que faz:**
- Exibe dados simulados de sensores de trânsito reais
- Permite envio de dados para InterSCity via middleware
- Mostra estatísticas de trânsito em tempo real
- Interface colorida baseada no nível de congestionamento

**Funcionalidades específicas:**
- Lista de sensores com localização, contagem de veículos, velocidade média
- Cards de estatísticas (total de sensores, ativos, congestionados)
- Botão "Enviar para InterSCity" em cada sensor
- Status visual (verde=baixo, laranja=moderado, vermelho=alto congestionamento)
- Atualização de dados em tempo real
- Formatação automática para formato InterSCity

### **☁️ Integração InterSCity (interscity_integration_screen.dart)**
**O que faz:**
- Monitora e exibe o status da integração com InterSCity
- Mostra logs de comunicação em tempo real
- Permite testes de conectividade
- Explica visualmente o fluxo de dados

**Funcionalidades específicas:**
- Fluxo visual de 4 etapas (App → Middleware → Adapter → InterSCity)
- Logs de comunicação com timestamps
- Botão para testar integração em tempo real
- Status de conectividade (conectado/desconectado)
- Contadores de mensagens enviadas
- Explicação das vantagens do middleware

### **▶️ Demonstração Interativa (middleware_demo_screen.dart)**
**O que faz:**
- Demonstra visualmente como o middleware facilita a comunicação
- Executa animações passo a passo do fluxo de dados
- Permite teste prático da integração
- Explica as vantagens do sistema

**Funcionalidades específicas:**
- Animações de fade e slide para cada etapa
- Execução automática do fluxo completo
- Envio real de dados para InterSCity durante demonstração
- Explicação das 4 vantagens principais do middleware
- Interface interativa com cores e ícones
- Feedback visual de sucesso/erro

### **📝 Registro de Projetos (project_registration_screen.dart)**
**O que faz:**
- Permite criar novos projetos para obter tokens de acesso
- Interface de formulário para dados do projeto
- Validação de campos obrigatórios
- Armazenamento local do projeto criado

**Funcionalidades específicas:**
- Formulário com nome, descrição e região do projeto
- Validação de campos obrigatórios
- Integração com Registration Service
- Armazenamento do token de autenticação
- Navegação automática após registro

### **🔧 Serviços de API (api_service.dart)**
**O que faz:**
- Gerencia todas as comunicações com o backend
- Implementa métodos para cada operação necessária
- Trata erros de conexão e validação
- Formata dados para envio ao InterSCity

**Funcionalidades específicas:**
- Registro de projetos via Registration Service
- Criação de produtores via Middleware Service
- Envio de mensagens para InterSCity
- Verificação de status dos serviços
- Tratamento de erros e timeouts
- Formatação de headers de autenticação

### **📊 Modelos de Dados**

#### **TrafficSensor (traffic_sensor.dart)**
**O que faz:**
- Define a estrutura de dados para sensores de trânsito
- Implementa conversão para formato InterSCity
- Fornece métodos de serialização/deserialização

**Campos principais:**
- `id`: Identificador único do sensor
- `name`: Nome amigável do sensor
- `location`: Endereço/localização
- `latitude/longitude`: Coordenadas GPS
- `vehicleCount`: Número de veículos detectados
- `averageSpeed`: Velocidade média em km/h
- `congestionLevel`: Nível de congestionamento
- `status`: Status do sensor (ativo/inativo)
- `lastUpdate`: Timestamp da última atualização

#### **Project (project.dart)**
**O que faz:**
- Representa um projeto registrado no sistema
- Armazena informações de autenticação
- Gerencia dados de configuração

#### **Message (message.dart)**
**O que faz:**
- Define estrutura de mensagens enviadas
- Controla status e metadados
- Gerencia relacionamentos com produtores

#### **Producer (producer.dart)**
**O que faz:**
- Representa produtores de mensagens
- Configura brokers e estratégias
- Gerencia conexões com middleware

### **🔄 Gerenciamento de Estado (app_provider.dart)**
**O que faz:**
- Gerencia o estado global da aplicação
- Controla dados do projeto atual
- Implementa persistência local
- Notifica mudanças de estado

**Funcionalidades específicas:**
- Armazenamento do projeto ativo
- Persistência em SharedPreferences
- Notificação de mudanças via Provider
- Limpeza de dados no logout
- Carregamento automático do projeto salvo

## 🏗️ Arquitetura

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
```

## 🚀 Como Executar

### Pré-requisitos
- Flutter 3.16.0 ou superior
- Dart 3.2.0 ou superior
- Backend rodando (ver docker-compose.yml)

### Instalação
```bash
cd front-end-flutter

# Instalar dependências
flutter pub get

# Executar aplicação
flutter run -d chrome  # Para web
flutter run -d android # Para Android
flutter run -d ios     # Para iOS
```

## 📱 Fluxo de Uso

### 1. **Primeiro Acesso**
1. Abrir o app
2. Clicar em "Registrar Novo Projeto"
3. Preencher dados do projeto
4. Receber token de autenticação

### 2. **Monitoramento de Trânsito**
1. Acessar "Sensores de Trânsito"
2. Visualizar dados em tempo real
3. Clicar "Enviar para InterSCity" em qualquer sensor
4. Observar confirmação de envio

### 3. **Verificar Integração**
1. Acessar "Integração InterSCity"
2. Ver logs de comunicação
3. Clicar "Testar Integração"
4. Observar status de conectividade

### 4. **Demonstração Completa**
1. Acessar "Demonstração"
2. Clicar "Iniciar Demonstração"
3. Observar fluxo visual passo a passo
4. Ver dados sendo enviados para InterSCity

## 🔧 Configuração

### URLs dos Serviços
```dart
// Em lib/services/api_service.dart
static const String baseUrl = 'http://localhost:8081'; // Middleware Service
static const String registrationUrl = 'http://localhost:8080'; // Registration Service
static const String discoveryUrl = 'http://localhost:8082'; // Discovery Service
static const String interscityUrl = 'http://localhost:8083'; // InterSCity Adapter
```

### InterSCity Platform
- **URL**: `https://cidadesinteligentes.lsdi.ufma.br/interscity_lh`
- **Integração**: Via middleware e adapter

## 📊 Dados de Exemplo

### Sensor de Trânsito
```json
{
  "sensor_id": "traffic_001",
  "location": "Av. Principal, 123 - São Luís/MA",
  "vehicle_count": 45,
  "average_speed": 35.5,
  "congestion_level": "Baixo",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## 🎨 Design System

### Cores Principais
- **Verde**: InterSCity e sucesso
- **Laranja**: Trânsito e alertas
- **Azul**: Informações gerais
- **Roxo**: Adaptação e tradução

### Ícones
- 🚦 Trânsito
- ☁️ InterSCity
- ▶️ Demonstração

## 🛠️ Desenvolvimento

### Estrutura de Arquivos
```
lib/
├── main.dart                    # Ponto de entrada
├── models/                      # Modelos de dados
│   ├── traffic_sensor.dart      # Sensor de trânsito
│   ├── message.dart             # Mensagens
│   ├── producer.dart            # Produtores
│   └── project.dart             # Projetos
├── screens/                     # Telas da aplicação
│   ├── home_screen.dart         # Tela principal
│   ├── traffic_sensor_dashboard.dart  # Dashboard de trânsito
│   ├── interscity_integration_screen.dart  # Integração InterSCity
│   ├── middleware_demo_screen.dart  # Demonstração
│   └── project_registration_screen.dart  # Registro de projetos
├── services/                    # Serviços
│   └── api_service.dart         # API Service
└── providers/                   # Gerenciamento de estado
    └── app_provider.dart        # App Provider
```

### Dependências Principais
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5          # Gerenciamento de estado
  http: ^1.1.0              # Requisições HTTP
  shared_preferences: ^2.2.0 # Armazenamento local
```

## 🚀 Deploy

### Web
```bash
flutter build web
# Arquivos em build/web/
```

### Android
```bash
flutter build apk
# APK em build/app/outputs/flutter-apk/
```

### iOS
```bash
flutter build ios
# Abrir Xcode para assinatura
```

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique se o backend está rodando
2. Confirme as URLs de conexão
3. Verifique os logs do Flutter
4. Consulte a documentação do projeto

## 🏆 Vantagens do Sistema

### Para Desenvolvedores
- **Interface Única**: Uma API para múltiplos brokers
- **Padronização**: Formato consistente de dados
- **Facilidade**: Integração simples com InterSCity
- **Flexibilidade**: Suporte a diferentes brokers

### Para Cidades Inteligentes
- **Dados Reais**: Sensores de trânsito em tempo real
- **Integração**: Conectividade com InterSCity
- **Monitoramento**: Dashboard completo
- **Escalabilidade**: Arquitetura distribuída

## 📊 Logs HTTP

O aplicativo inclui logs detalhados para todas as chamadas HTTP, facilitando o debug e monitoramento das comunicações com o backend.

### Como Visualizar os Logs

1. **No Terminal/Console**:
   ```bash
   flutter run --verbose
   ```

2. **Filtrar logs HTTP**:
   ```bash
   flutter run | grep "FLUTTER HTTP"
   ```

3. **Logs Disponíveis**:
   - 🌐 **Requisições Enviadas**: Método, URL, Headers e Body
   - 📥 **Respostas Recebidas**: Status Code e Response Body
   - ❌ **Erros**: Detalhes completos de erros de conexão

### Exemplo de Log
```
🌐 [FLUTTER HTTP] ====================================================
📤 [FLUTTER HTTP] REQUISIÇÃO ENVIADA
📋 [FLUTTER HTTP] Método: POST
📋 [FLUTTER HTTP] URL: http://localhost:8080/api/projects
📋 [FLUTTER HTTP] Headers: {"Content-Type":"application/json"}
📋 [FLUTTER HTTP] Body: {"name":"Projeto Teste","region":"BR","supportedBrokers":["rabbitmq"]}
🌐 [FLUTTER HTTP] ====================================================
```

---

**Desenvolvido para a disciplina de Sistemas Distribuídos - UFMA**

*Integração com InterSCity - Plataforma de Cidades Inteligentes*
