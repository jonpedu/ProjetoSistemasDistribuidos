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

  // Métodos para gerenciar produtores
  Future<Producer> createProducer(
      String token, String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/producers'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'name': name,
          'description': description,
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/producers'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> producersList = data['data'];
        return producersList.map((json) => Producer.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar produtores');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> deleteProducer(String token, String producerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/producers/$producerId'),
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
        Uri.parse('$baseUrl/api/producers/$producerId/messages'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao enviar mensagem');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<List<Message>> getMessages(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages'),
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
        headers: _getHeaders(null),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar status do sistema');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para InterSCity
  Future<Map<String, dynamic>> sendToInterSCity(
      String token, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$interscityUrl/api/interscity'),
        headers: _getHeaders(token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao enviar para InterSCity');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Métodos para Discovery Service
  Future<List<Map<String, dynamic>>> getAvailableReceivers() async {
    try {
      final response = await http.get(
        Uri.parse('$discoveryUrl/api/receivers'),
        headers: _getHeaders(null),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Erro ao buscar receivers disponíveis');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
