import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/error_logger_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final LoggerService _logger = LoggerService();
  List<LogEntry> _logs = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;
  String _filterType = 'all'; // all, today, week, month
  String _selectedScreen = 'all';
  LogType? _selectedLogType; // null = all types

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

      await _logger.loadLogs();
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
    List<LogEntry> filteredLogs = _logger.getLogs();

    // Filtrar por período
    switch (_filterType) {
      case 'today':
        filteredLogs = _logger.getLogsByDate(DateTime.now());
        break;
      case 'week':
        filteredLogs = _logger.getLogsFromLastDays(7);
        break;
      case 'month':
        filteredLogs = _logger.getLogsFromLastDays(30);
        break;
      case 'interscity':
        filteredLogs = _logger.getInterSCityLogs();
        break;
      case 'http':
        filteredLogs = _logger.getHttpLogs();
        break;
      case 'errors':
        filteredLogs = _logger.getErrorLogs();
        break;
    }

    // Filtrar por tipo de log
    if (_selectedLogType != null) {
      filteredLogs =
          filteredLogs.where((log) => log.type == _selectedLogType).toList();
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
      _statistics = _logger.getLogStatistics();
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Logs'),
        content: const Text(
          'Tem certeza que deseja limpar todos os logs?\n\n'
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
      await _logger.clearLogs();
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logs limpos com sucesso!'),
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
        exportData = _logger.exportLogsAsJson();
        filename = 'logs_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        exportData = _logger.exportLogsAsText();
        filename = 'logs_${DateTime.now().millisecondsSinceEpoch}.txt';
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
        title: const Text('Logs'),
        backgroundColor: Colors.blue.shade700,
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
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Limpar'),
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas dos Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total de Logs',
                  _logger.getLogs().length.toString(),
                  Icons.list,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Logs Hoje',
                  _logger.getLogsByDate(DateTime.now()).length.toString(),
                  Icons.today,
                  Colors.green,
                ),
                _buildStatCard(
                  'Logs HTTP',
                  _logger.getHttpLogs().length.toString(),
                  Icons.http,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Erros',
                  _logger.getErrorLogs().length.toString(),
                  Icons.error,
                  Colors.red,
                ),
                _buildStatCard(
                  'InterSCity',
                  _logger.getInterSCityLogs().length.toString(),
                  Icons.cloud,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Última Semana',
                  _logger.getLogsFromLastDays(7).length.toString(),
                  Icons.calendar_view_week,
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
                DropdownMenuItem(
                    value: 'interscity', child: Text('InterSCity')),
                DropdownMenuItem(value: 'http', child: Text('HTTP')),
                DropdownMenuItem(value: 'errors', child: Text('Erros')),
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
    final screens = _logger
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
            Icon(Icons.info_outline, size: 64, color: Colors.blue.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhum log encontrado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.blue.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste os filtros para ver diferentes tipos de logs.',
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
              log.typeIcon,
              color: log.typeColor,
            ),
            title: Text(
              log.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: log.typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: log.typeColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        log.typeDisplayName,
                        style: TextStyle(
                          color: log.typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(log.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (log.screen != null)
                  Text(
                    'Tela: ${log.screen}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
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
                    if (log.additionalData != null) ...[
                      _buildInfoRow(
                        'Dados Adicionais',
                        _formatAdditionalData(log.additionalData!),
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

  String _formatAdditionalData(Map<String, dynamic> data) {
    if (data.isEmpty) return 'Nenhum dado adicional';

    final buffer = StringBuffer();
    data.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}
