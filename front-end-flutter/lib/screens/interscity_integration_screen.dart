import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/api_service.dart';

class InterSCityIntegrationScreen extends StatefulWidget {
  const InterSCityIntegrationScreen({super.key});

  @override
  State<InterSCityIntegrationScreen> createState() =>
      _InterSCityIntegrationScreenState();
}

class _InterSCityIntegrationScreenState
    extends State<InterSCityIntegrationScreen> {
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _integrationLogs = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIntegrationInfo();
  }

  Future<void> _loadIntegrationInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simular logs de integração
      _integrationLogs.clear();
      _integrationLogs.addAll([
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'type': 'success',
          'message': 'Conexão estabelecida com InterSCity via middleware',
          'details':
              'Middleware Service → InterSCity Adapter → InterSCity Platform',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
          'type': 'info',
          'message': 'Sensor traffic_001 registrado no InterSCity',
          'details': 'Dados enviados: vehicle_count=45, average_speed=35.5',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
          'type': 'success',
          'message': 'Dados de trânsito processados com sucesso',
          'details': 'InterSCity retornou status 200 OK',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
          'type': 'warning',
          'message': 'Sensor traffic_002 detectou congestionamento',
          'details': 'vehicle_count=89, average_speed=18.2 (ALTO)',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
          'type': 'success',
          'message': 'Alertas de trânsito enviados para InterSCity',
          'details': 'Sistema de notificação ativado',
        },
      ]);
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar informações: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testInterSCityIntegration() async {
    try {
      final provider = context.read<AppProvider>();
      if (provider.currentProject?.token == null) {
        throw Exception('Token do projeto não encontrado');
      }

      // Criar produtor de teste para InterSCity
      final producer = await _apiService.createProducer(
        provider.currentProject!.token!,
        'testinterscityproducer',
        'Produtor de Teste InterSCity',
      );

      // Dados de teste no formato InterSCity
      final testData = {
        'sensor_id': 'test_traffic_001',
        'location': 'Av. Teste, 123 - São Luís/MA',
        'vehicle_count': 67,
        'average_speed': 28.5,
        'congestion_level': 'moderado',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Enviar via middleware
      await _apiService.sendMessage(
        provider.currentProject!.token!,
        producer.id,
        testData.toString(),
      );

      // Adicionar log de sucesso
      setState(() {
        _integrationLogs.insert(0, {
          'timestamp': DateTime.now(),
          'type': 'success',
          'message': 'Teste de integração realizado com sucesso',
          'details': 'Dados enviados para InterSCity via middleware',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Teste de integração realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Adicionar log de erro
      setState(() {
        _integrationLogs.insert(0, {
          'timestamp': DateTime.now(),
          'type': 'error',
          'message': 'Erro no teste de integração',
          'details': e.toString(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro no teste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração InterSCity'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIntegrationInfo,
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
                        onPressed: _loadIntegrationInfo,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(),
                    _buildIntegrationStatus(),
                    Expanded(
                      child: _buildLogsList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testInterSCityIntegration,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Testar Integração'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_sync, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integração InterSCity',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                    ),
                    Text(
                      'Middleware facilitando a comunicação com InterSCity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como funciona a integração:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildIntegrationStep(
                    '1. App Flutter',
                    'Envia dados via API REST',
                    Icons.phone_android,
                    Colors.blue,
                  ),
                  _buildIntegrationStep(
                    '2. Middleware Service',
                    'Processa e roteia mensagens',
                    Icons.swap_horiz,
                    Colors.orange,
                  ),
                  _buildIntegrationStep(
                    '3. InterSCity Adapter',
                    'Traduz formato e envia',
                    Icons.translate,
                    Colors.purple,
                  ),
                  _buildIntegrationStep(
                    '4. InterSCity Platform',
                    'Recebe e processa dados',
                    Icons.cloud,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationStep(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Status InterSCity',
              'Conectado',
              Icons.cloud_done,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Mensagens Enviadas',
              '${_integrationLogs.where((log) => log['type'] == 'success').length}',
              Icons.send,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Última Sincronização',
              _formatTime(_integrationLogs.isNotEmpty
                  ? _integrationLogs.first['timestamp']
                  : DateTime.now()),
              Icons.schedule,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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
    );
  }

  Widget _buildLogsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _integrationLogs.length,
      itemBuilder: (context, index) {
        final log = _integrationLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _getLogIcon(log['type']),
            title: Text(
              log['message'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['details']),
                const SizedBox(height: 4),
                Text(
                  _formatTime(log['timestamp']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _getLogIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'error':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'info':
        icon = Icons.info;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}
