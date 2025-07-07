import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogType { error, httpRequest, httpResponse, info, warning }

class LogEntry {
  final DateTime timestamp;
  final LogType type;
  final String title;
  final String message;
  final String? screen;
  final String? action;
  final Map<String, dynamic>? additionalData;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.message,
    this.screen,
    this.action,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'title': title,
      'message': message,
      'screen': screen,
      'action': action,
      'additionalData': additionalData,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      type: LogType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LogType.info,
      ),
      title: json['title'],
      message: json['message'],
      screen: json['screen'],
      action: json['action'],
      additionalData: json['additionalData'] != null
          ? Map<String, dynamic>.from(json['additionalData'])
          : null,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case LogType.error:
        return 'Erro';
      case LogType.httpRequest:
        return 'Requisição HTTP';
      case LogType.httpResponse:
        return 'Resposta HTTP';
      case LogType.info:
        return 'Informação';
      case LogType.warning:
        return 'Aviso';
    }
  }

  Color get typeColor {
    switch (type) {
      case LogType.error:
        return Colors.red;
      case LogType.httpRequest:
        return Colors.blue;
      case LogType.httpResponse:
        return Colors.green;
      case LogType.info:
        return Colors.grey;
      case LogType.warning:
        return Colors.orange;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case LogType.error:
        return Icons.error;
      case LogType.httpRequest:
        return Icons.arrow_upward;
      case LogType.httpResponse:
        return Icons.arrow_downward;
      case LogType.info:
        return Icons.info;
      case LogType.warning:
        return Icons.warning;
    }
  }
}

class LoggerService {
  static const String _storageKey = 'app_logs';
  static const int _maxLogEntries = 200; // Aumentado para incluir HTTP logs

  // Singleton pattern
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  List<LogEntry> _logs = [];

  // Logar requisição HTTP
  Future<void> logHttpRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    String? body,
    String? screen,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: LogType.httpRequest,
      title: '$method Request',
      message: url,
      screen: screen,
      action: 'HTTP Request',
      additionalData: {
        'method': method,
        'url': url,
        'headers': headers,
        'body': body,
      },
    );

    _addLogEntry(entry);

    // Log no console para debug
    developer.log(
      '📤 [HTTP REQUEST] $method $url',
      name: 'LoggerService',
    );
  }

  // Logar resposta HTTP
  Future<void> logHttpResponse(
    String method,
    String url,
    int statusCode,
    String responseBody, {
    String? screen,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: LogType.httpResponse,
      title: '$method Response ($statusCode)',
      message: url,
      screen: screen,
      action: 'HTTP Response',
      additionalData: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'responseBody': responseBody,
        'isSuccess': statusCode >= 200 && statusCode < 300,
      },
    );

    _addLogEntry(entry);

    // Log no console para debug
    developer.log(
      '📥 [HTTP RESPONSE] $method $url - $statusCode',
      name: 'LoggerService',
    );
  }

  // Logar informação geral
  Future<void> logInfo(
    String title,
    String message, {
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: LogType.info,
      title: title,
      message: message,
      screen: screen,
      action: action,
      additionalData: additionalData,
    );

    _addLogEntry(entry);
  }

  // Logar aviso
  Future<void> logWarning(
    String title,
    String message, {
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: LogType.warning,
      title: title,
      message: message,
      screen: screen,
      action: action,
      additionalData: additionalData,
    );

    _addLogEntry(entry);
  }

  // Método auxiliar para adicionar entrada e salvar
  Future<void> _addLogEntry(LogEntry entry) async {
    // Adicionar ao log em memória
    _logs.insert(0, entry); // Inserir no início da lista

    // Limitar o número de entradas em memória
    if (_logs.length > _maxLogEntries) {
      _logs = _logs.take(_maxLogEntries).toList();
    }

    // Salvar no armazenamento local
    await _saveLogs();
  }

  // Logar erro com informações detalhadas
  Future<void> logError(
    String error, {
    String? stackTrace,
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: LogType.error,
      title: 'Erro',
      message: error,
      screen: screen,
      action: action,
      additionalData: additionalData,
    );

    await _addLogEntry(entry);

    // Log no console para debug
    developer.log(
      '🚨 [APP ERROR] ====================================================',
      name: 'LoggerService',
    );
    developer.log(
      '📋 [APP ERROR] Timestamp: ${entry.timestamp.toIso8601String()}',
      name: 'LoggerService',
    );
    developer.log(
      '📋 [APP ERROR] Screen: ${entry.screen ?? 'N/A'}',
      name: 'LoggerService',
    );
    developer.log(
      '📋 [APP ERROR] Action: ${entry.action ?? 'N/A'}',
      name: 'LoggerService',
    );
    developer.log(
      '❌ [APP ERROR] Error: ${entry.message}',
      name: 'LoggerService',
    );
    if (stackTrace != null) {
      developer.log(
        '📋 [APP ERROR] Stack Trace: $stackTrace',
        name: 'LoggerService',
      );
    }
    if (additionalData != null) {
      developer.log(
        '📋 [APP ERROR] Additional Data: ${jsonEncode(additionalData)}',
        name: 'LoggerService',
      );
    }
    developer.log(
      '🚨 [APP ERROR] ====================================================',
      name: 'LoggerService',
    );
  }

  // Logar erro simples
  Future<void> logSimpleError(String error) async {
    await logError(error);
  }

  // Logar erro de API
  Future<void> logApiError(
    String method,
    String url,
    String error, {
    String? responseBody,
    int? statusCode,
  }) async {
    await logError(
      'API Error: $error',
      action: 'API Request',
      additionalData: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'responseBody': responseBody,
      },
    );
  }

  // Logar erro de validação
  Future<void> logValidationError(
    String field,
    String error, {
    String? screen,
    Map<String, dynamic>? formData,
  }) async {
    await logError(
      'Validation Error: $error',
      screen: screen,
      action: 'Form Validation',
      additionalData: {
        'field': field,
        'formData': formData,
      },
    );
  }

  // Obter todos os logs
  List<LogEntry> getLogs() {
    return List.unmodifiable(_logs);
  }

  // Obter logs filtrados por data
  List<LogEntry> getLogsByDate(DateTime date) {
    return _logs.where((log) {
      return log.timestamp.year == date.year &&
          log.timestamp.month == date.month &&
          log.timestamp.day == date.day;
    }).toList();
  }

  // Obter logs filtrados por tela
  List<LogEntry> getLogsByScreen(String screen) {
    return _logs.where((log) => log.screen == screen).toList();
  }

  // Obter logs dos últimos N dias
  List<LogEntry> getLogsFromLastDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _logs.where((log) => log.timestamp.isAfter(cutoffDate)).toList();
  }

  // Limpar todos os logs
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  // Exportar logs como JSON
  String exportLogsAsJson() {
    return jsonEncode(_logs.map((log) => log.toJson()).toList());
  }

  // Exportar logs como texto
  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== LOG DE ERROS DO APLICATIVO ===');
    buffer.writeln('Gerado em: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total de erros: ${_logs.length}');
    buffer.writeln();

    for (final log in _logs) {
      buffer.writeln('Data/Hora: ${log.timestamp.toIso8601String()}');
      buffer.writeln('Tela: ${log.screen ?? 'N/A'}');
      buffer.writeln('Ação: ${log.action ?? 'N/A'}');
      buffer.writeln('Erro: ${log.message}');
      if (log.additionalData != null) {
        buffer.writeln('Dados Adicionais: ${jsonEncode(log.additionalData)}');
      }
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  // Carregar logs do armazenamento
  Future<void> loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_storageKey);

      if (logsJson != null) {
        final List<dynamic> logsList = jsonDecode(logsJson);
        _logs = logsList.map((json) => LogEntry.fromJson(json)).toList();
      }
    } catch (e) {
      developer.log(
        'Erro ao carregar logs: $e',
        name: 'ErrorLogger',
      );
    }
  }

  // Salvar logs no armazenamento
  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = jsonEncode(_logs.map((log) => log.toJson()).toList());
      await prefs.setString(_storageKey, logsJson);
    } catch (e) {
      developer.log(
        'Erro ao salvar logs: $e',
        name: 'ErrorLogger',
      );
    }
  }

  // Estatísticas dos logs
  Map<String, dynamic> getLogStatistics() {
    if (_logs.isEmpty) {
      return {
        'totalErrors': 0,
        'errorsByScreen': {},
        'errorsByDay': {},
        'mostCommonErrors': {},
      };
    }

    final errorsByScreen = <String, int>{};
    final errorsByDay = <String, int>{};
    final errorMessages = <String, int>{};

    for (final log in _logs) {
      // Contar por tela
      final screen = log.screen ?? 'Unknown';
      errorsByScreen[screen] = (errorsByScreen[screen] ?? 0) + 1;

      // Contar por dia
      final day =
          '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
      errorsByDay[day] = (errorsByDay[day] ?? 0) + 1;

      // Contar mensagens de erro
      errorMessages[log.message] = (errorMessages[log.message] ?? 0) + 1;
    }

    // Ordenar erros mais comuns
    final sortedErrors = errorMessages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalErrors': _logs.length,
      'errorsByScreen': errorsByScreen,
      'errorsByDay': errorsByDay,
      'mostCommonErrors': Map.fromEntries(sortedErrors.take(5)),
      'lastError':
          _logs.isNotEmpty ? _logs.first.timestamp.toIso8601String() : null,
    };
  }

  // Métodos de filtro por tipo
  List<LogEntry> getLogsByType(LogType type) {
    return _logs.where((log) => log.type == type).toList();
  }

  List<LogEntry> getHttpLogs() {
    return _logs
        .where((log) =>
            log.type == LogType.httpRequest || log.type == LogType.httpResponse)
        .toList();
  }

  List<LogEntry> getInterSCityLogs() {
    return _logs
        .where((log) =>
            (log.type == LogType.httpRequest ||
                log.type == LogType.httpResponse) &&
            (log.message.contains('interscity') ||
                log.message.contains('localhost:8083') ||
                log.additionalData?['url']?.toString().contains('8083') ==
                    true))
        .toList();
  }

  List<LogEntry> getErrorLogs() {
    return _logs.where((log) => log.type == LogType.error).toList();
  }
}

// Alias para compatibilidade com código existente
typedef ErrorLoggerService = LoggerService;
typedef ErrorLogEntry = LogEntry;
