import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producer.dart';
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

  /// Gera um nome de produtor válido (8-32 caracteres alfanuméricos)
  String _generateValidProducerName(int attempt) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final basePrefix = 'testinter';

    // Usar diferentes estratégias baseadas na tentativa
    String suffix;
    switch (attempt) {
      case 0:
        // Primeira tentativa: usar últimos 6 dígitos do timestamp
        suffix = timestamp.toString().substring(7);
        break;
      case 1:
        // Segunda tentativa: usar últimos 4 dígitos + random
        final random = (timestamp % 100).toString().padLeft(2, '0');
        suffix = '${timestamp.toString().substring(9)}$random';
        break;
      case 2:
        // Terceira tentativa: usar hash mais complexo
        final hash = timestamp.hashCode.abs().toString();
        suffix = hash.substring(0, 6.clamp(0, hash.length));
        break;
      default:
        // Fallback
        suffix = (timestamp % 1000000).toString();
    }

    String proposedName = basePrefix + suffix;

    // Garantir que está dentro do limite de 32 caracteres
    if (proposedName.length > 32) {
      proposedName = proposedName.substring(0, 32);
    }

    // Garantir que tem pelo menos 8 caracteres
    if (proposedName.length < 8) {
      proposedName = proposedName.padRight(8, '0');
    }

    // Garantir que é alfanumérico (remover caracteres especiais)
    proposedName = proposedName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Se ficou muito curto após limpeza, completar com números
    if (proposedName.length < 8) {
      proposedName = proposedName.padRight(8, '0');
    }

    // Log para debug (desabilitado para não sobrecarregar o console)
    // developer.log(
    //   'Generated producer name: "$proposedName" (length: ${proposedName.length}, attempt: $attempt)',
    //   name: 'InterSCityIntegration',
    // );

    return proposedName;
  }

  Future<Producer> _createUniqueProducer(String token) async {
    const maxAttempts = 3;
    int attempt = 0;

    while (attempt < maxAttempts) {
      try {
        final testProducerName = _generateValidProducerName(attempt);

        final producer = await _apiService.createProducer(
          token,
          testProducerName,
          'Produtor de Teste InterSCity - ${DateTime.now().toIso8601String()} (Tentativa ${attempt + 1})',
        );

        return producer;
      } catch (e) {
        attempt++;

        if (attempt >= maxAttempts) {
          // Se todas as tentativas falharam, relançar o erro
          rethrow;
        }

        // Se foi erro de conflito ou validação, tentar novamente
        if (e.toString().contains('Producer with username') ||
            e.toString().contains('Validation failed')) {
          // Esperar um pouco antes de tentar novamente
          await Future.delayed(Duration(milliseconds: 200 * attempt));
          continue;
        } else {
          // Se não foi erro de conflito/validação, relançar imediatamente
          rethrow;
        }
      }
    }

    // Nunca deveria chegar aqui, mas garantir que sempre retorna algo
    throw Exception('Falha ao criar produtor após $maxAttempts tentativas');
  }

  Future<void> _testInterSCityIntegration() async {
    try {
      final provider = context.read<AppProvider>();
      if (provider.currentProject?.token == null) {
        throw Exception('Token do projeto não encontrado');
      }

      // Criar produtor único de teste para InterSCity
      final producer =
          await _createUniqueProducer(provider.currentProject!.token!);

      // Debug: verificar dados do producer
      print('🔍 [InterSCity Test] Producer criado:');
      print('  - ID: "${producer.id}"');
      print('  - Name: "${producer.name}"');
      print('  - Description: "${producer.description}"');
      print('  - Status: "${producer.status}"');
      print('  - CreatedAt: "${producer.createdAt}"');

      // Dados de teste no formato InterSCity
      final testData = {
        'sensor_id': 'test_traffic_001',
        'location': 'Av. Teste, 123 - São Luís/MA',
        'vehicle_count': 67,
        'average_speed': 28.5,
        'congestion_level': 'moderado',
        'timestamp': DateTime.now().toIso8601String(),
        'lat': -2.5297,
        'lon': -44.3028,
        'status': 'active',
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
          'details': 'Dados enviados para InterSCity via middleware\n'
              'Producer ID: ${producer.id}\n'
              'Producer Name: ${producer.name.isNotEmpty ? producer.name : "N/A"}\n'
              'Status: ${producer.status}\n'
              'Description: ${producer.description}',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Teste realizado com sucesso!\nProducer: ${producer.name.isNotEmpty ? producer.name : producer.id}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver Logs',
            onPressed: () {
              // Rolar para o primeiro log
              if (_integrationLogs.isNotEmpty) {
                // Focar no primeiro log
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('🚨 [InterSCity Test] Erro: $e');

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
          content: Text('❌ Erro no teste: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Tentar Novamente',
            onPressed: () => _testInterSCityIntegration(),
          ),
        ),
      );
    }
  }

  Future<void> _showDeleteProducerDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Produtores de Teste'),
        content: const Text(
          'Esta ação irá remover todos os produtores de teste criados. '
          'Isso pode ajudar a resolver problemas de conflito de nomes.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('⚠️ Funcionalidade de limpeza não implementada no backend'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Integração InterSCity'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Como funciona a integração:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. O app Flutter envia dados via API REST\n'
                '2. O Middleware Service processa e roteia\n'
                '3. O InterSCity Adapter traduz e envia\n'
                '4. A plataforma InterSCity recebe os dados',
              ),
              const SizedBox(height: 16),
              const Text(
                'Problemas comuns:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Erro "Producer already registered": O sistema agora gera nomes únicos automaticamente\n'
                '• Erro "Validation failed": Nomes devem ter 8-32 caracteres alfanuméricos\n'
                '• Conexão recusada: Verifique se todos os serviços estão rodando\n'
                '• Token inválido: Registre um novo projeto',
              ),
              const SizedBox(height: 16),
              const Text(
                'Regras de validação:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Username: 8-32 caracteres alfanuméricos\n'
                '• Não são permitidos caracteres especiais\n'
                '• Sistema gera nomes automaticamente (ex: testinter8163223)',
              ),
              const SizedBox(height: 16),
              const Text(
                'Dicas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Use o botão laranja para limpar produtores antigos\n'
                '• Cada teste cria um produtor único e válido\n'
                '• Verifique os logs para detalhes dos testes\n'
                '• O sistema tenta até 3 vezes em caso de erro',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _testNameGeneration() {
    for (int i = 0; i < 5; i++) {
      final name = _generateValidProducerName(i);
      print(
          'Teste $i: "$name" (${name.length} caracteres, alfanumérico: ${RegExp(r'^[a-zA-Z0-9]+$').hasMatch(name)})');
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
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Ajuda',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIntegrationInfo,
            tooltip: 'Atualizar',
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "test_integration",
            onPressed: _testInterSCityIntegration,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Testar Integração'),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ],
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
              Icon(Icons.cloud_sync, color: Colors.green.shade700, size: 28),
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
