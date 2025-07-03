import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class ErrorLogEntry {
  final DateTime timestamp;
  final String error;
  final String? stackTrace;
  final String? screen;
  final String? action;
  final Map<String, dynamic>? additionalData;

  ErrorLogEntry({
    required this.timestamp,
    required this.error,
    this.stackTrace,
    this.screen,
    this.action,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'stackTrace': stackTrace,
      'screen': screen,
      'action': action,
      'additionalData': additionalData,
    };
  }

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) {
    return ErrorLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      error: json['error'],
      stackTrace: json['stackTrace'],
      screen: json['screen'],
      action: json['action'],
      additionalData: json['additionalData'] != null
          ? Map<String, dynamic>.from(json['additionalData'])
          : null,
    );
  }
}

class ErrorLoggerService {
  static const String _storageKey = 'app_error_logs';
  static const int _maxLogEntries = 100; // Limite de entradas no log

  // Singleton pattern
  static final ErrorLoggerService _instance = ErrorLoggerService._internal();
  factory ErrorLoggerService() => _instance;
  ErrorLoggerService._internal();

  List<ErrorLogEntry> _logs = [];

  // Logar erro com informações detalhadas
  Future<void> logError(
    String error, {
    String? stackTrace,
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    final entry = ErrorLogEntry(
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      screen: screen,
      action: action,
      additionalData: additionalData,
    );

    // Adicionar ao log em memória
    _logs.insert(0, entry); // Inserir no início da lista

    // Limitar o número de entradas em memória
    if (_logs.length > _maxLogEntries) {
      _logs = _logs.take(_maxLogEntries).toList();
    }

    // Log no console para debug
    developer.log(
      '🚨 [APP ERROR] ====================================================',
      name: 'ErrorLogger',
    );
    developer.log(
      '📋 [APP ERROR] Timestamp: ${entry.timestamp.toIso8601String()}',
      name: 'ErrorLogger',
    );
    developer.log(
      '📋 [APP ERROR] Screen: ${entry.screen ?? 'N/A'}',
      name: 'ErrorLogger',
    );
    developer.log(
      '📋 [APP ERROR] Action: ${entry.action ?? 'N/A'}',
      name: 'ErrorLogger',
    );
    developer.log(
      '❌ [APP ERROR] Error: ${entry.error}',
      name: 'ErrorLogger',
    );
    if (entry.stackTrace != null) {
      developer.log(
        '📋 [APP ERROR] Stack Trace: ${entry.stackTrace}',
        name: 'ErrorLogger',
      );
    }
    if (entry.additionalData != null) {
      developer.log(
        '📋 [APP ERROR] Additional Data: ${jsonEncode(entry.additionalData)}',
        name: 'ErrorLogger',
      );
    }
    developer.log(
      '🚨 [APP ERROR] ====================================================',
      name: 'ErrorLogger',
    );

    // Salvar no armazenamento local
    await _saveLogs();
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
  List<ErrorLogEntry> getLogs() {
    return List.unmodifiable(_logs);
  }

  // Obter logs filtrados por data
  List<ErrorLogEntry> getLogsByDate(DateTime date) {
    return _logs.where((log) {
      return log.timestamp.year == date.year &&
          log.timestamp.month == date.month &&
          log.timestamp.day == date.day;
    }).toList();
  }

  // Obter logs filtrados por tela
  List<ErrorLogEntry> getLogsByScreen(String screen) {
    return _logs.where((log) => log.screen == screen).toList();
  }

  // Obter logs dos últimos N dias
  List<ErrorLogEntry> getLogsFromLastDays(int days) {
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
      buffer.writeln('Erro: ${log.error}');
      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace: ${log.stackTrace}');
      }
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
        _logs = logsList.map((json) => ErrorLogEntry.fromJson(json)).toList();
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
      errorMessages[log.error] = (errorMessages[log.error] ?? 0) + 1;
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
}
