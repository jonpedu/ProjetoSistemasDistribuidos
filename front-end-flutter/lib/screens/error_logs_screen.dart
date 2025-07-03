import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/error_logger_service.dart';

class ErrorLogsScreen extends StatefulWidget {
  const ErrorLogsScreen({super.key});

  @override
  State<ErrorLogsScreen> createState() => _ErrorLogsScreenState();
}

class _ErrorLogsScreenState extends State<ErrorLogsScreen> {
  final ErrorLoggerService _errorLogger = ErrorLoggerService();
  List<ErrorLogEntry> _logs = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;
  String _filterType = 'all'; // all, today, week, month
  String _selectedScreen = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _errorLogger.loadLogs();
      _applyFilters();
      _loadStatistics();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilters() {
    List<ErrorLogEntry> filteredLogs = _errorLogger.getLogs();

    // Filtrar por período
    switch (_filterType) {
      case 'today':
        filteredLogs = _errorLogger.getLogsByDate(DateTime.now());
        break;
      case 'week':
        filteredLogs = _errorLogger.getLogsFromLastDays(7);
        break;
      case 'month':
        filteredLogs = _errorLogger.getLogsFromLastDays(30);
        break;
    }

    // Filtrar por tela
    if (_selectedScreen != 'all') {
      filteredLogs =
          filteredLogs.where((log) => log.screen == _selectedScreen).toList();
    }

    setState(() {
      _logs = filteredLogs;
    });
  }

  void _loadStatistics() {
    setState(() {
      _statistics = _errorLogger.getLogStatistics();
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Logs'),
        content: const Text(
          'Tem certeza que deseja limpar todos os logs de erro?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _errorLogger.clearLogs();
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logs de erro limpos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _exportLogs() async {
    final exportType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Logs'),
        content: const Text('Escolha o formato de exportação:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'json'),
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'text'),
            child: const Text('Texto'),
          ),
        ],
      ),
    );

    if (exportType != null) {
      String exportData;
      String filename;

      if (exportType == 'json') {
        exportData = _errorLogger.exportLogsAsJson();
        filename = 'error_logs_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        exportData = _errorLogger.exportLogsAsText();
        filename = 'error_logs_${DateTime.now().millisecondsSinceEpoch}.txt';
      }

      await Clipboard.setData(ClipboardData(text: exportData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Logs exportados para a área de transferência!\nArquivo: $filename'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs de Erro'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportLogs();
                  break;
                case 'clear':
                  _clearLogs();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Exportar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpar Todos', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLogs,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStatistics(),
                    _buildFilters(),
                    Expanded(
                      child: _buildLogsList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Estatísticas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Total de Erros',
                _statistics['totalErrors']?.toString() ?? '0',
                Icons.error,
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Último Erro',
                _statistics['lastError'] != null
                    ? _formatDate(DateTime.parse(_statistics['lastError']))
                    : 'N/A',
                Icons.schedule,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Erros Hoje',
                _errorLogger.getLogsByDate(DateTime.now()).length.toString(),
                Icons.today,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'today', child: Text('Hoje')),
                DropdownMenuItem(value: 'week', child: Text('Última Semana')),
                DropdownMenuItem(value: 'month', child: Text('Último Mês')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterType = value!;
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedScreen,
              decoration: const InputDecoration(
                labelText: 'Tela',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Todas')),
                ..._getUniqueScreens().map((screen) => DropdownMenuItem(
                      value: screen,
                      child: Text(screen),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedScreen = value!;
                });
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueScreens() {
    final screens = _errorLogger
        .getLogs()
        .map((log) => log.screen)
        .where((screen) => screen != null)
        .cast<String>()
        .toSet()
        .toList();
    screens.sort();
    return screens;
  }

  Widget _buildLogsList() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhum erro encontrado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'O aplicativo está funcionando perfeitamente!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              Icons.error,
              color: Colors.red.shade600,
            ),
            title: Text(
              log.error,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(log.timestamp),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (log.screen != null)
                  Text(
                    'Tela: ${log.screen}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.action != null) ...[
                      _buildInfoRow('Ação', log.action!),
                      const SizedBox(height: 8),
                    ],
                    if (log.stackTrace != null) ...[
                      _buildInfoRow('Stack Trace', log.stackTrace!),
                      const SizedBox(height: 8),
                    ],
                    if (log.additionalData != null) ...[
                      _buildInfoRow(
                        'Dados Adicionais',
                        log.additionalData.toString(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
