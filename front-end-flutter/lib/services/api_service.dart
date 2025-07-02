import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/message.dart';
import '../models/producer.dart';
import '../models/project.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081'; // Middleware Service
  static const String registrationUrl =
      'http://localhost:8080'; // Registration Service
  static const String discoveryUrl =
      'http://localhost:8082'; // Discovery Service
  static const String interscityUrl =
      'http://localhost:8083'; // InterSCity Adapter Service

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

  // Métodos para gerenciar projetos
  Future<Project> registerProject(String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$registrationUrl/api/projects'),
        headers: _getHeaders(null),
        body: jsonEncode({
          'name': name,
          'region': 'BR',
          'supportedBrokers': ['rabbitmq'],
          // 'description': description, // Removido pois não existe no DTO
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao registrar projeto');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para gerenciar produtores (senders)
  Future<Producer> createProducer(
      String token, String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/senders'), // Corrigido: /api/senders
        headers: _getHeaders(token),
        body: jsonEncode({
          'username': name, // Corrigido: campo 'username' em vez de 'name'
          'password': 'password123', // Campo obrigatório
          'broker': 'rabbitmq', // Campo obrigatório
          'strategy': 'direct', // Campo obrigatório
          'exchange': 'default.exchange', // Campo opcional
          'queue': 'default.queue', // Campo opcional
          'routingKey': 'default.key', // Campo opcional
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Producer.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar produtor');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<List<Producer>> getProducers(String token) async {
    try {
      // Nota: O middleware não tem endpoint para listar todos os produtores
      // Você precisará implementar isso no backend ou usar uma abordagem diferente
      throw Exception(
          'Endpoint para listar produtores não implementado no backend');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> deleteProducer(String token, String producerId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$baseUrl/api/senders/$producerId'), // Corrigido: /api/senders
        headers: _getHeaders(token),
      );

      if (response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao deletar produtor');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para gerenciar mensagens
  Future<Message> sendMessage(
      String token, String producerId, String content) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/api/senders/$producerId/send'), // Corrigido: /api/senders/{id}/send
        headers: _getHeaders(token),
        body: jsonEncode({
          'data': content, // Corrigido: campo 'data' em vez de 'content'
        }),
      );

      if (response.statusCode == 200) {
        // O endpoint retorna void, então criamos uma mensagem local
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
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<List<Message>> getMessages(String token, String consumerId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/receivers/$consumerId/messages'), // Corrigido: precisa do consumerId
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesList = data['data'];
        return messagesList.map((json) => Message.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar mensagens');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para monitoramento do sistema
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      // Nota: O middleware não tem endpoint de status
      // Retornando informações básicas de conectividade
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
      throw Exception('Erro ao verificar status do sistema: $e');
    }
  }

  Future<bool> _checkServiceHealth(String url, String method) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode <
          500; // Considera 4xx como "saudável" (serviço responde)
    } catch (e) {
      return false;
    }
  }

  // Métodos para InterSCity
  Future<Map<String, dynamic>> sendToInterSCity(
      String token, Map<String, dynamic> data) async {
    try {
      // Nota: O InterSCity Adapter não tem endpoint REST direto
      // Ele funciona via RabbitMQ. Para testar, você pode enviar uma mensagem
      // através do middleware service que será roteada para o InterSCity
      throw Exception(
          'InterSCity Adapter funciona via RabbitMQ, não via REST direto');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para Discovery Service
  Future<List<Map<String, dynamic>>> getAvailableReceivers() async {
    try {
      // Nota: O discovery service não tem endpoint para listar todos os receivers
      // Ele funciona via eventos RabbitMQ e tem endpoints específicos por consumerId
      throw Exception(
          'Endpoint para listar receivers não implementado no backend');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Método para conectar um produtor
  Future<void> connectProducer(String token, String producerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/senders/$producerId/connect'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao conectar produtor');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Método para desconectar um produtor
  Future<void> disconnectProducer(String token, String producerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/senders/$producerId/close'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao desconectar produtor');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
