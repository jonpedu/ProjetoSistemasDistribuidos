# Middleware Demo App

Aplicação Flutter para demonstrar o fluxo completo de um middleware de mensageria com integração InterSCity.

## Funcionalidades

- **Registro de Projetos**: Criação de projetos com tokens de acesso únicos
- **Gerenciamento de Produtores**: Criação e gerenciamento de produtores de mensagens
- **Envio de Mensagens**: Interface para envio de mensagens através dos produtores
- **Monitoramento do Sistema**: Visualização do status dos serviços e receivers disponíveis
- **Armazenamento Local**: Persistência de dados do projeto localmente

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── models/                   # Modelos de dados
│   ├── message.dart         # Modelo de mensagem
│   ├── producer.dart        # Modelo de produtor
│   └── project.dart         # Modelo de projeto
├── providers/               # Gerenciamento de estado
│   └── app_provider.dart    # Provider principal da aplicação
├── screens/                 # Telas da aplicação
│   ├── home_screen.dart     # Tela principal
│   ├── project_registration_screen.dart  # Registro de projetos
│   ├── producer_management_screen.dart   # Gerenciamento de produtores
│   ├── message_sending_screen.dart       # Envio de mensagens
│   └── system_monitoring_screen.dart     # Monitoramento do sistema
└── services/               # Serviços de API
    └── api_service.dart    # Serviço de comunicação com APIs
```

## Configuração

### Pré-requisitos

- Flutter SDK 3.2.3 ou superior
- Dart SDK 3.2.3 ou superior
- Android Studio / VS Code
- Dispositivo Android, iOS ou navegador web

### Instalação

1. Clone o repositório
2. Navegue até a pasta do projeto Flutter:
   ```bash
   cd front-end-flutter
   ```

3. Instale as dependências:
   ```bash
   flutter pub get
   ```

4. Execute a aplicação:
   ```bash
   flutter run
   ```

## Plataformas Suportadas

- **Android**: API level 21+
- **iOS**: iOS 12.0+
- **Web**: Chrome, Firefox, Safari, Edge

## Dependências Principais

- `provider`: Gerenciamento de estado
- `http`: Comunicação com APIs REST
- `shared_preferences`: Armazenamento local
- `flutter_svg`: Componentes SVG
- `lottie`: Animações
- `flutter_local_notifications`: Notificações locais
- `web_socket_channel`: Comunicação WebSocket
- `form_validator`: Validação de formulários
- `font_awesome_flutter`: Ícones adicionais

## Serviços Integrados

A aplicação se comunica com os seguintes serviços:

- **Middleware Service** (porta 8080): Gerenciamento de produtores e mensagens
- **Registration Service** (porta 8081): Registro de projetos
- **Discovery Service** (porta 8082): Descoberta de receivers
- **InterSCity Adapter Service** (porta 8083): Integração com InterSCity

## Fluxo de Uso

1. **Registrar Projeto**: Crie um novo projeto para obter um token de acesso
2. **Criar Produtores**: Adicione produtores para enviar mensagens
3. **Enviar Mensagens**: Use os produtores para enviar mensagens
4. **Monitorar Sistema**: Acompanhe o status dos serviços e receivers

## Desenvolvimento

### Executar em modo debug:
```bash
flutter run
```

### Executar em modo release:
```bash
flutter run --release
```

### Executar testes:
```bash
flutter test
```

### Analisar código:
```bash
flutter analyze
```

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT.
