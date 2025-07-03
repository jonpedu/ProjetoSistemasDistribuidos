import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../models/message.dart';
import '../models/producer.dart';
import '../models/project.dart';
import 'error_logger_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081'; // Middleware Service
  static const String registrationUrl =
      'http://localhost:8080'; // Registration Service
  static const String discoveryUrl =
      'http://localhost:8082'; // Discovery Service
  static const String interscityUrl =
      'http://localhost:8083'; // InterSCity Adapter Service

  final ErrorLoggerService _errorLogger = ErrorLoggerService();

  // Headers padrão
  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Método para logar requisições HTTP
  void _logHttpRequest(
      String method, String url, Map<String, String> headers, String? body) {
    developer.log(
      '🌐 [FLUTTER HTTP] ====================================================',
      name: 'ApiService',
    );
    developer.log(
      '📤 [FLUTTER HTTP] REQUISIÇÃO ENVIADA',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] Método: $method',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] URL: $url',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] Headers: ${jsonEncode(headers)}',
      name: 'ApiService',
    );
    if (body != null) {
      developer.log(
        '📋 [FLUTTER HTTP] Body: $body',
        name: 'ApiService',
      );
    }
    developer.log(
      '🌐 [FLUTTER HTTP] ====================================================',
      name: 'ApiService',
    );
  }

  // Método para logar respostas HTTP
  void _logHttpResponse(
      String method, String url, int statusCode, String body) {
    developer.log(
      '🌐 [FLUTTER HTTP] ====================================================',
      name: 'ApiService',
    );
    developer.log(
      '📥 [FLUTTER HTTP] RESPOSTA RECEBIDA',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] Método: $method',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] URL: $url',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] Status Code: $statusCode',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] Response Body: $body',
      name: 'ApiService',
    );
    developer.log(
      '🌐 [FLUTTER HTTP] ====================================================',
      name: 'ApiService',
    );
  }

  // Método para logar erros HTTP
  void _logHttpError(String method, String url, String error) {
    developer.log(
      '🌐 [FLUTTER HTTP] ====================================================',
      name: 'ApiService',
    );
    developer.log(
      '❌ [FLUTTER HTTP] ERRO NA REQUISIÇÃO',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] Método: $method',
      name: 'ApiService',
    );
    developer.log(
      '📋 [FLUTTER HTTP] URL: $url',
      name: 'ApiService',
    );
    developer.log(
      '❌ [FLUTTER HTTP] Erro: $error',
      name: 'ApiService',
    );
    developer.log(
      '🌐 [FLUTTER HTTP] ====================================================',
      name: 'ApiService',
    );

    // Logar erro no sistema de logging
    _errorLogger.logApiError(method, url, error);
  }

  // Métodos para gerenciar projetos
  Future<Project> registerProject(String name, String description) async {
    const method = 'POST';
    final url = '$registrationUrl/api/projects';
    final headers = _getHeaders(null);
    final body = jsonEncode({
      'name': name,
      'region': 'BR',
      'supportedBrokers': ['rabbitmq'],
    });

    _logHttpRequest(method, url, headers, body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao registrar projeto');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      _errorLogger.logError(
        'Erro de conexão: $e',
        action: 'API Request',
        additionalData: {
          'method': method,
          'url': url,
        },
      );
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para gerenciar produtores (senders)
  Future<Producer> createProducer(
      String token, String name, String description) async {
    const method = 'POST';
    final url = '$baseUrl/api/senders';
    final headers = _getHeaders(token);
    final body = jsonEncode({
      'username': name,
      'password': 'password123',
      'broker': 'rabbitmq',
      'strategy': 'direct',
      'exchange': 'default.exchange',
      'queue': 'default.queue',
      'routingKey': 'default.key',
    });

    _logHttpRequest(method, url, headers, body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Producer.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar produtor');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<List<Producer>> getProducers(String token) async {
    const method = 'GET';
    final url = '$baseUrl/api/senders';
    final headers = _getHeaders(token);

    _logHttpRequest(method, url, headers, null);

    try {
      // Nota: O middleware não tem endpoint para listar todos os produtores
      throw Exception(
          'Endpoint para listar produtores não implementado no backend');
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> deleteProducer(String token, String producerId) async {
    const method = 'DELETE';
    final url = '$baseUrl/api/senders/$producerId';
    final headers = _getHeaders(token);

    _logHttpRequest(method, url, headers, null);

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao deletar produtor');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para gerenciar mensagens
  Future<Message> sendMessage(
      String token, String producerId, String content) async {
    const method = 'POST';
    final url = '$baseUrl/api/senders/$producerId/send';
    final headers = _getHeaders(token);
    final body = jsonEncode({
      'data': content,
    });

    _logHttpRequest(method, url, headers, body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          timestamp: DateTime.now(),
          producerId: producerId,
          producerName: 'Producer $producerId',
          status: 'sent',
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao enviar mensagem');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<List<Message>> getMessages(String token, String consumerId) async {
    const method = 'GET';
    final url = '$baseUrl/api/receivers/$consumerId/messages';
    final headers = _getHeaders(token);

    _logHttpRequest(method, url, headers, null);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesList = data['data'];
        return messagesList.map((json) => Message.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar mensagens');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para monitoramento do sistema
  Future<Map<String, dynamic>> getSystemStatus() async {
    const method = 'GET';
    final url = '$baseUrl/api/status';
    final headers = {'Content-Type': 'application/json'};

    _logHttpRequest(method, url, headers, null);

    try {
      final status = {
        'registration_service':
            await _checkServiceHealth('$registrationUrl/api/projects', 'POST'),
        'middleware_service':
            await _checkServiceHealth('$baseUrl/api/senders', 'POST'),
        'discovery_service':
            await _checkServiceHealth('$discoveryUrl/api/receivers', 'GET'),
        'interscity_service':
            await _checkServiceHealth('$interscityUrl', 'GET'),
      };

      return {
        'status': 'operational',
        'services': status,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro ao verificar status do sistema: $e');
    }
  }

  Future<bool> _checkServiceHealth(String url, String method) async {
    final headers = {'Content-Type': 'application/json'};

    _logHttpRequest('GET', url, headers, null);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      _logHttpResponse('GET', url, response.statusCode, response.body);

      return response.statusCode < 500;
    } catch (e) {
      _logHttpError('GET', url, e.toString());
      return false;
    }
  }

  // Métodos para InterSCity
  Future<Map<String, dynamic>> sendToInterSCity(
      String token, Map<String, dynamic> data) async {
    const method = 'POST';
    final url = '$interscityUrl/api/send';
    final headers = _getHeaders(token);
    final body = jsonEncode(data);

    _logHttpRequest(method, url, headers, body);

    try {
      throw Exception(
          'InterSCity Adapter funciona via RabbitMQ, não via REST direto');
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para Discovery Service
  Future<List<Map<String, dynamic>>> getAvailableReceivers() async {
    const method = 'GET';
    final url = '$discoveryUrl/api/receivers';
    final headers = {'Content-Type': 'application/json'};

    _logHttpRequest(method, url, headers, null);

    try {
      throw Exception(
          'Endpoint para listar receivers não implementado no backend');
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  // Método para conectar um produtor
  Future<void> connectProducer(String token, String producerId) async {
    const method = 'POST';
    final url = '$baseUrl/api/senders/$producerId/connect';
    final headers = _getHeaders(token);

    _logHttpRequest(method, url, headers, null);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao conectar produtor');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }

  // Método para desconectar um produtor
  Future<void> disconnectProducer(String token, String producerId) async {
    const method = 'POST';
    final url = '$baseUrl/api/senders/$producerId/close';
    final headers = _getHeaders(token);

    _logHttpRequest(method, url, headers, null);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      _logHttpResponse(method, url, response.statusCode, response.body);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao desconectar produtor');
      }
    } catch (e) {
      _logHttpError(method, url, e.toString());
      throw Exception('Erro de conexão: $e');
    }
  }
}
