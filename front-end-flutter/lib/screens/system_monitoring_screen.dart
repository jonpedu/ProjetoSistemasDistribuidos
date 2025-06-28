import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/api_service.dart';

class SystemMonitoringScreen extends StatefulWidget {
  const SystemMonitoringScreen({super.key});

  @override
  State<SystemMonitoringScreen> createState() => _SystemMonitoringScreenState();
}

class _SystemMonitoringScreenState extends State<SystemMonitoringScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _systemStatus;
  List<Map<String, dynamic>>? _availableReceivers;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await _apiService.getSystemStatus();
      final receivers = await _apiService.getAvailableReceivers();

      setState(() {
        _systemStatus = status;
        _availableReceivers = receivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento do Sistema'),
        actions: [
          IconButton(
            onPressed: _loadSystemData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildMonitoringContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Erro desconhecido',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadSystemData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatusCard(),
          const SizedBox(height: 16),
          _buildReceiversCard(),
          const SizedBox(height: 16),
          _buildProjectInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status do Sistema',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_systemStatus != null) ...[
              _buildStatusItem(
                'Middleware Service',
                _systemStatus!['middleware']?['status'] ?? 'Desconhecido',
                _systemStatus!['middleware']?['url'] ?? '',
              ),
              _buildStatusItem(
                'Registration Service',
                _systemStatus!['registration']?['status'] ?? 'Desconhecido',
                _systemStatus!['registration']?['url'] ?? '',
              ),
              _buildStatusItem(
                'Discovery Service',
                _systemStatus!['discovery']?['status'] ?? 'Desconhecido',
                _systemStatus!['discovery']?['url'] ?? '',
              ),
              _buildStatusItem(
                'InterSCity Adapter',
                _systemStatus!['interscity']?['status'] ?? 'Desconhecido',
                _systemStatus!['interscity']?['url'] ?? '',
              ),
            ] else ...[
              const Center(
                child: Text('Dados de status não disponíveis'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String service, String status, String url) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
      case 'running':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'offline':
      case 'inactive':
      case 'stopped':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'warning':
      case 'degraded':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (url.isNotEmpty)
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiversCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Receivers Disponíveis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_availableReceivers != null &&
                _availableReceivers!.isNotEmpty) ...[
              ..._availableReceivers!
                  .map((receiver) => _buildReceiverItem(receiver)),
            ] else ...[
              const Center(
                child: Text('Nenhum receiver disponível'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverItem(Map<String, dynamic> receiver) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiver['name'] ?? 'Nome não disponível',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  receiver['description'] ?? 'Descrição não disponível',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (receiver['url'] != null)
                  Text(
                    receiver['url'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(
              receiver['status'] ?? 'Desconhecido',
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor:
                _getStatusColor(receiver['status']).withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'online':
        return Colors.green;
      case 'inactive':
      case 'offline':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProjectInfoCard() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.currentProject == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Informações do Projeto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProjectStatItem(
                  'Nome do Projeto',
                  provider.currentProject!.name,
                ),
                _buildProjectStatItem(
                  'Status',
                  provider.currentProject!.status,
                ),
                _buildProjectStatItem(
                  'Produtores Ativos',
                  provider.producers.length.toString(),
                ),
                _buildProjectStatItem(
                  'Mensagens Enviadas',
                  provider.messages.length.toString(),
                ),
                _buildProjectStatItem(
                  'Data de Criação',
                  _formatDate(provider.currentProject!.createdAt),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Token de Acesso:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        provider.currentProject!.token,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
