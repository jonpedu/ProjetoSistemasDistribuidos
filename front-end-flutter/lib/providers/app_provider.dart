import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../models/producer.dart';
import '../models/project.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Project? _currentProject;
  List<Producer> _producers = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Project? get currentProject => _currentProject;
  List<Producer> get producers => _producers;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters
  set currentProject(Project? project) {
    _currentProject = project;
    notifyListeners();
  }

  set isLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  set error(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Métodos para gerenciar o projeto
  Future<bool> registerProject(String name, String description) async {
    try {
      isLoading = true;
      error = null;

      final project = await _apiService.registerProject(name, description);
      _currentProject = project;

      // Salvar token localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('project_token', project.token);
      await prefs.setString('project_id', project.id);

      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      return false;
    }
  }

  Future<bool> loadProjectFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('project_token');
      final projectId = prefs.getString('project_id');

      if (token != null && projectId != null) {
        // Aqui você pode implementar uma chamada para buscar os dados do projeto
        // Por enquanto, vamos apenas carregar o token
        _currentProject = Project(
          id: projectId,
          name: 'Projeto Carregado',
          description: 'Projeto carregado do armazenamento local',
          status: 'ACTIVE',
          createdAt: DateTime.now(),
          token: token,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<void> clearProject() async {
    _currentProject = null;
    _producers.clear();
    _messages.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('project_token');
    await prefs.remove('project_id');

    notifyListeners();
  }

  // Métodos para gerenciar produtores
  Future<bool> createProducer(String name, String description) async {
    if (_currentProject == null) {
      error = 'Nenhum projeto selecionado';
      return false;
    }

    try {
      isLoading = true;
      error = null;

      final producer = await _apiService.createProducer(
        _currentProject!.token,
        name,
        description,
      );

      _producers.add(producer);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      return false;
    }
  }

  Future<bool> loadProducers() async {
    if (_currentProject == null) {
      error = 'Nenhum projeto selecionado';
      return false;
    }

    try {
      isLoading = true;
      error = null;

      final producers = await _apiService.getProducers(_currentProject!.token);
      _producers = producers;

      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      return false;
    }
  }

  Future<bool> deleteProducer(String producerId) async {
    if (_currentProject == null) {
      error = 'Nenhum projeto selecionado';
      return false;
    }

    try {
      isLoading = true;
      error = null;

      await _apiService.deleteProducer(_currentProject!.token, producerId);
      _producers.removeWhere((p) => p.id == producerId);

      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      return false;
    }
  }

  // Métodos para gerenciar mensagens
  Future<bool> sendMessage(String producerId, String content) async {
    if (_currentProject == null) {
      error = 'Nenhum projeto selecionado';
      return false;
    }

    try {
      isLoading = true;
      error = null;

      final message = await _apiService.sendMessage(
        _currentProject!.token,
        producerId,
        content,
      );

      _messages.add(message);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      return false;
    }
  }

  Future<bool> loadMessages() async {
    if (_currentProject == null) {
      error = 'Nenhum projeto selecionado';
      return false;
    }

    try {
      isLoading = true;
      error = null;

      final messages = await _apiService.getMessages(
        _currentProject!.token,
        _currentProject!.id,
      );
      _messages = messages;

      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      return false;
    }
  }

  // Método para limpar erros
  void clearError() {
    error = null;
  }
}
