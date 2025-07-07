import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/api_service.dart';

class NewInterSCityIntegrationScreen extends StatefulWidget {
  const NewInterSCityIntegrationScreen({super.key});

  @override
  State<NewInterSCityIntegrationScreen> createState() =>
      _NewInterSCityIntegrationScreenState();
}

class _NewInterSCityIntegrationScreenState
    extends State<NewInterSCityIntegrationScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos do formulário
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dataKeysController = TextEditingController();
  final _intervalController = TextEditingController();

  // Estado da aplicação
  String _selectedDataType = 'json';
  bool _isLoading = false;
  bool _isTestRunning = false;
  String? _error;
  String? _successMessage;
  String? _currentProducerId;
  List<String> _testLogs = [];
  Map<String, dynamic> _lastTestResult = {};

  final List<Map<String, dynamic>> _dataTypes = [
    {
      'value': 'json',
      'label': 'JSON',
      'icon': Icons.code,
      'description': 'Dados estruturados em formato JSON',
    },
    {
      'value': 'csv',
      'label': 'CSV',
      'icon': Icons.table_chart,
      'description': 'Dados tabulares separados por vírgula',
    },
    {
      'value': 'xml',
      'label': 'XML',
      'icon': Icons.description,
      'description': 'Dados estruturados em XML',
    },
    {
      'value': 'text',
      'label': 'Texto',
      'icon': Icons.text_fields,
      'description': 'Dados em texto simples',
    },
  ];

  @override
  void initState() {
    super.initState();
    _intervalController.text = '5'; // Default 5 seconds
    _dataKeysController.text = 'temperature,humidity,pressure';
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _dataKeysController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _createTestService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
      _testLogs.clear();
    });

    try {
      final provider = context.read<AppProvider>();
      if (provider.currentProject?.token == null) {
        throw Exception('Token do projeto não encontrado');
      }

      _addLog('🔄 Criando serviço de teste...');

      // Criar produtor para o serviço de teste
      final cleanServiceName = _serviceNameController.text
          .toLowerCase()
          .replaceAll(
              RegExp(r'[^a-zA-Z0-9]'), '') // Remove caracteres especiais
          .replaceAll(' ', ''); // Remove espaços

      final finalServiceName = 'testservice$cleanServiceName';
      _addLog('📝 Nome do serviço: $finalServiceName');

      final producer = await _apiService.createProducer(
        provider.currentProject!.token!,
        finalServiceName,
        _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'Serviço de teste: ${_serviceNameController.text}',
      );

      _currentProducerId = producer.id;
      _addLog('✅ Serviço criado com ID: ${producer.id}');

      setState(() {
        _successMessage = '✅ Serviço de teste criado com sucesso!\n\n'
            'Nome: ${_serviceNameController.text}\n'
            'ID: ${producer.id}\n'
            'Tipo de dados: ${_getSelectedDataType()['label']}\n\n'
            'Agora você pode testar a conectividade e envio de dados.';
      });

      _addLog('🎯 Serviço pronto para testes');
    } catch (e) {
      setState(() {
        _error = '❌ Erro ao criar serviço de teste: $e';
      });
      _addLog('❌ Erro: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (_currentProducerId == null) {
      _addLog('⚠️ Crie um serviço primeiro');
      return;
    }

    setState(() {
      _isTestRunning = true;
      _error = null;
    });

    try {
      final provider = context.read<AppProvider>();
      _addLog('🔄 Testando conectividade...');

      // Gerar dados de teste
      final testData = _generateTestData();
      _addLog('📊 Dados de teste gerados');

      // Enviar dados via middleware
      await _apiService.sendMessage(
        provider.currentProject!.token!,
        _currentProducerId!,
        jsonEncode(testData),
      );

      _addLog('✅ Teste de conectividade bem-sucedido');
      _addLog('📤 Dados enviados para InterSCity');

      setState(() {
        _lastTestResult = {
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'success',
          'data': testData,
          'producer_id': _currentProducerId,
        };
      });
    } catch (e) {
      _addLog('❌ Falha no teste de conectividade: $e');
      setState(() {
        _error = '❌ Erro no teste: $e';
        _lastTestResult = {
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'error',
          'error': e.toString(),
        };
      });
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  Future<void> _runStressTest() async {
    if (_currentProducerId == null) {
      _addLog('⚠️ Crie um serviço primeiro');
      return;
    }

    setState(() {
      _isTestRunning = true;
      _error = null;
    });

    try {
      final provider = context.read<AppProvider>();
      final interval = int.parse(_intervalController.text);
      _addLog('🚀 Iniciando teste de stress (${interval}s de intervalo)...');

      for (int i = 1; i <= 10; i++) {
        if (!_isTestRunning) break; // Para o teste se o usuário parar

        final testData = _generateTestData();
        testData['batch_number'] = i;
        testData['batch_total'] = 10;

        await _apiService.sendMessage(
          provider.currentProject!.token!,
          _currentProducerId!,
          jsonEncode(testData),
        );

        _addLog('📤 Lote $i/10 enviado');

        if (i < 10) {
          await Future.delayed(Duration(seconds: interval));
        }
      }

      _addLog('🎉 Teste de stress concluído com sucesso!');

      setState(() {
        _lastTestResult = {
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'stress_test_complete',
          'batches_sent': 10,
          'interval': interval,
        };
      });
    } catch (e) {
      _addLog('❌ Falha no teste de stress: $e');
      setState(() {
        _error = '❌ Erro no teste de stress: $e';
      });
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  void _stopTest() {
    setState(() {
      _isTestRunning = false;
    });
    _addLog('⏹️ Teste interrompido pelo usuário');
  }

  void _addLog(String message) {
    setState(() {
      _testLogs.add(
          '${DateTime.now().toLocal().toString().substring(11, 19)} - $message');
    });
  }

  Map<String, dynamic> _generateTestData() {
    final random = Random();
    final keys =
        _dataKeysController.text.split(',').map((k) => k.trim()).toList();

    final data = <String, dynamic>{
      'service_name': _serviceNameController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'data_type': _selectedDataType,
      'test_id': 'test_${DateTime.now().millisecondsSinceEpoch}',
    };

    // Gerar dados baseados nas chaves especificadas
    for (String key in keys) {
      if (key.toLowerCase().contains('temp')) {
        data[key] = 20.0 + random.nextDouble() * 15.0; // 20-35°C
      } else if (key.toLowerCase().contains('humidity')) {
        data[key] = 30.0 + random.nextDouble() * 50.0; // 30-80%
      } else if (key.toLowerCase().contains('pressure')) {
        data[key] = 1000.0 + random.nextDouble() * 50.0; // 1000-1050 hPa
      } else if (key.toLowerCase().contains('speed')) {
        data[key] = random.nextDouble() * 100.0; // 0-100 km/h
      } else if (key.toLowerCase().contains('count')) {
        data[key] = random.nextInt(100);
      } else {
        data[key] = random.nextDouble() * 100.0; // Valor genérico
      }
    }

    return data;
  }

  Map<String, dynamic> _getSelectedDataType() {
    return _dataTypes.firstWhere((type) => type['value'] == _selectedDataType);
  }

  void _clearLogs() {
    setState(() {
      _testLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratório de Testes InterSCity'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildServiceConfigForm(),
            const SizedBox(height: 24),
            _buildTestControls(),
            const SizedBox(height: 24),
            _buildTestLogs(),
            if (_error != null) _buildErrorCard(),
            if (_successMessage != null) _buildSuccessCard(),
            if (_lastTestResult.isNotEmpty) _buildTestResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.deepPurple.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laboratório de Testes',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade800,
                              ),
                    ),
                    Text(
                      'Crie e teste serviços personalizados para conectar com InterSCity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.deepPurple.shade600,
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
                    'Funcionalidades do Laboratório:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeature('🔧 Criação de serviços personalizados',
                      'Configure nome, tipo de dados e parâmetros'),
                  _buildFeature('🔄 Teste de conectividade',
                      'Valide a comunicação com InterSCity'),
                  _buildFeature('💪 Teste de stress',
                      'Simule cargas de trabalho intensas'),
                  _buildFeature('📊 Monitoramento em tempo real',
                      'Visualize logs e resultados dos testes'),
                  _buildFeature('🚀 Dados customizáveis',
                      'Defina suas próprias chaves e valores'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildServiceConfigForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚙️ Configuração do Serviço',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Nome do serviço
              _buildTextField(
                controller: _serviceNameController,
                label: 'Nome do Serviço',
                hint: 'Ex: Sensor Meteorológico Central',
                icon: Icons.label,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome do serviço é obrigatório';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '💡 Dica: Caracteres especiais e espaços serão removidos automaticamente',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de dados
              _buildDataTypeSelector(),
              const SizedBox(height: 16),

              // Chaves de dados
              _buildTextField(
                controller: _dataKeysController,
                label: 'Chaves de Dados',
                hint: 'Ex: temperature,humidity,pressure',
                icon: Icons.key,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Defina pelo menos uma chave de dados';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Intervalo de teste
              _buildTextField(
                controller: _intervalController,
                label: 'Intervalo de Teste (segundos)',
                hint: '5',
                icon: Icons.timer,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Intervalo é obrigatório';
                  }
                  final interval = int.tryParse(value);
                  if (interval == null || interval < 1) {
                    return 'Intervalo deve ser maior que 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              _buildTextField(
                controller: _descriptionController,
                label: 'Descrição (opcional)',
                hint: 'Descreva o propósito deste serviço de teste...',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botão de criação
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestService,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading
                      ? 'Criando Serviço...'
                      : 'Criar Serviço de Teste'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Controles de Teste',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_currentProducerId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Serviço pronto: ID ${_currentProducerId}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentProducerId == null || _isTestRunning
                        ? null
                        : _testConnection,
                    icon: _isTestRunning && _currentProducerId != null
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: const Text('Testar Conexão'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentProducerId == null || _isTestRunning
                        ? null
                        : _runStressTest,
                    icon: const Icon(Icons.speed),
                    label: const Text('Teste de Stress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isTestRunning) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _stopTest,
                  icon: const Icon(Icons.stop),
                  label: const Text('Parar Teste'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestLogs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '📋 Logs de Teste',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _testLogs.isNotEmpty ? _clearLogs : null,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar logs',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade600),
              ),
              child: _testLogs.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum log ainda...\nCrie um serviço e execute testes para ver os logs aqui.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testLogs.length,
                      itemBuilder: (context, index) {
                        final log = _testLogs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: _getLogColor(log),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('✅') || log.contains('🎉')) {
      return Colors.green.shade400;
    } else if (log.contains('❌')) {
      return Colors.red.shade400;
    } else if (log.contains('⚠️')) {
      return Colors.orange.shade400;
    } else if (log.contains('🔄')) {
      return Colors.blue.shade400;
    } else {
      return Colors.grey.shade300;
    }
  }

  Widget _buildDataTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Dados *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _dataTypes.map((dataType) {
            final isSelected = _selectedDataType == dataType['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDataType = dataType['value'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.shade50
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple.shade300
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          dataType['icon'],
                          color: isSelected
                              ? Colors.deepPurple.shade600
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dataType['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.deepPurple.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Text(
                  'Serviço Criado!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _successMessage!,
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(
                  'Último Resultado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                const JsonEncoder.withIndent('  ').convert(_lastTestResult),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
