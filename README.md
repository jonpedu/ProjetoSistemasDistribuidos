# Middleware Demo App - Frontend Flutter

## Descrição

Este é o frontend Flutter para demonstrar o fluxo de funcionalidades do **Middleware de Mensageria como Serviço com Integração InterSCity**. A aplicação permite visualizar e interagir com todos os aspectos do sistema distribuído através de uma interface moderna e intuitiva.

## Funcionalidades

### 🏠 Tela Principal
- **Dashboard** com visão geral do sistema
- **Navegação** para todas as funcionalidades
- **Status do projeto** ativo
- **Cards de navegação** com ícones intuitivos

### 📝 Registro de Projeto
- **Formulário** para criar novos projetos
- **Validação** de campos obrigatórios
- **Seleção de brokers** suportados
- **Feedback visual** de sucesso/erro

### 🚀 Gerenciamento de Produtores
- **Registro de produtores** (senders)
- **Configuração** de broker, strategy, exchange e queue
- **Lista de produtores** registrados
- **Atualização em tempo real**

### 📨 Envio de Mensagens
- **Seleção de produtor** para envio
- **Editor JSON** para dados da mensagem
- **Histórico de mensagens** enviadas
- **Detalhes** de cada mensagem
- **Status visual** das mensagens

### 📊 Monitoramento do Sistema
- **Status do projeto** ativo
- **Estatísticas** de produtores e mensagens
- **Consumidores ativos** em tempo real
- **Informações** detalhadas do sistema

## Tecnologias Utilizadas

- **Flutter 3.16+** - Framework de desenvolvimento
- **Provider** - Gerenciamento de estado
- **HTTP** - Comunicação com APIs REST
- **Material Design 3** - Interface moderna
- **Responsive Design** - Suporte a múltiplas telas

## Plataformas Suportadas

- ✅ **Android** - APK nativo
- ✅ **iOS** - App nativo
- ✅ **Web** - Aplicação web responsiva

## Pré-requisitos

- **Flutter SDK** 3.16.0 ou superior
- **Dart** 3.2.0 ou superior
- **Android Studio** / **VS Code** com extensões Flutter
- **Backend** do middleware rodando (Docker Compose)

## Instalação e Execução

### 1. Clonar o Projeto
```bash
cd front-end-flutter/middleware_demo_app
```

### 2. Instalar Dependências
```bash
flutter pub get
```

### 3. Configurar Backend
Certifique-se de que o backend está rodando:
```bash
# Na pasta raiz do projeto
docker compose up -d
```

### 4. Executar a Aplicação

#### Para Android:
```bash
flutter run -d android
```

#### Para iOS:
```bash
flutter run -d ios
```

#### Para Web:
```bash
flutter run -d chrome
```

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── models/                   # Modelos de dados
│   ├── project.dart         # Modelo de projeto
│   ├── producer.dart        # Modelo de produtor
│   └── message.dart         # Modelo de mensagem
├── services/                # Serviços de API
│   └── api_service.dart     # Comunicação com backend
├── providers/               # Gerenciamento de estado
│   └── app_provider.dart    # Provider principal
├── screens/                 # Telas da aplicação
│   ├── home_screen.dart     # Tela principal
│   ├── project_registration_screen.dart
│   ├── producer_management_screen.dart
│   ├── message_sending_screen.dart
│   └── system_monitoring_screen.dart
└── widgets/                 # Widgets reutilizáveis
```

## Fluxo de Uso

### 1. Registrar Projeto
1. Acesse a tela "Registrar Projeto"
2. Preencha nome, região e selecione brokers
3. Clique em "Registrar Projeto"
4. O token de autenticação será gerado automaticamente

### 2. Gerenciar Produtores
1. Acesse "Gerenciar Produtores"
2. Preencha os dados do produtor (username, password, etc.)
3. Clique em "Registrar Produtor"
4. O produtor aparecerá na lista

### 3. Enviar Mensagens
1. Acesse "Enviar Mensagens"
2. Selecione um produtor da lista
3. Insira os dados JSON da mensagem
4. Clique em "Enviar Mensagem"
5. A mensagem será processada pelo middleware

### 4. Monitorar Sistema
1. Acesse "Monitoramento"
2. Visualize estatísticas em tempo real
3. Veja consumidores ativos
4. Monitore o status do projeto

## Configuração de URLs

As URLs dos serviços são configuradas em `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost';
static const String registrationUrl = '$baseUrl:8080';
static const String middlewareUrl = '$baseUrl:8081';
static const String discoveryUrl = '$baseUrl:8082';
```

Para desenvolvimento local, mantenha como `localhost`. Para produção, altere para a URL do servidor.

## Build para Produção

### Android APK:
```bash
flutter build apk --release
```

### iOS:
```bash
flutter build ios --release
```

### Web:
```bash
flutter build web --release
```

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## Licença

Este projeto é parte do trabalho acadêmico da disciplina de Sistemas Distribuídos da UFMA.

## Suporte

Para dúvidas ou problemas:
- Verifique se o backend está rodando
- Confirme as URLs de conexão
- Verifique os logs do Flutter (`flutter logs`)
- Consulte a documentação do Flutter

---

**Desenvolvido para a disciplina de Sistemas Distribuídos - UFMA**




