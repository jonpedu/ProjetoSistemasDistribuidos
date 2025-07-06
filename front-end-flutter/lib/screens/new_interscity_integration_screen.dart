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
  final _sensorNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Valores selecionados
  String _selectedSensorType = 'traffic';
  String _selectedRegion = 'BR';
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  final List<Map<String, dynamic>> _sensorTypes = [
    {
      'value': 'traffic',
      'label': 'Sensor de Trânsito',
      'icon': Icons.traffic,
      'color': Colors.orange,
      'description':
          'Monitora fluxo de veículos, velocidade e congestionamento',
      'fields': ['vehicle_count', 'average_speed', 'congestion_level'],
    },
    {
      'value': 'air_quality',
      'label': 'Sensor de Qualidade do Ar',
      'icon': Icons.air,
      'color': Colors.blue,
      'description': 'Monitora poluentes atmosféricos e qualidade do ar',
      'fields': ['pm25', 'pm10', 'co2', 'air_quality_index'],
    },
    {
      'value': 'lighting',
      'label': 'Sensor de Iluminação',
      'icon': Icons.lightbulb,
      'color': Colors.yellow,
      'description': 'Monitora iluminação pública e consumo de energia',
      'fields': ['brightness', 'energy_consumption', 'status'],
    },
    {
      'value': 'waste',
      'label': 'Sensor de Lixeira',
      'icon': Icons.delete,
      'color': Colors.green,
      'description': 'Monitora nível de lixeiras e otimiza coleta',
      'fields': ['fill_level', 'temperature', 'last_collection'],
    },
    {
      'value': 'parking',
      'label': 'Sensor de Estacionamento',
      'icon': Icons.local_parking,
      'color': Colors.purple,
      'description': 'Monitora vagas disponíveis em estacionamentos',
      'fields': ['available_spots', 'total_spots', 'occupancy_rate'],
    },
  ];

  final List<Map<String, String>> _regions = [
    {'value': 'BR', 'label': 'Brasil'},
    {'value': 'MA', 'label': 'Maranhão'},
    {'value': 'SL', 'label': 'São Luís'},
  ];

  @override
  void dispose() {
    _sensorNameController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createIntegration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final provider = context.read<AppProvider>();
      if (provider.currentProject?.token == null) {
        throw Exception('Token do projeto não encontrado');
      }

      // Criar produtor para a nova integração
      final producer = await _apiService.createProducer(
        provider.currentProject!.token!,
        '${_selectedSensorType}${_sensorNameController.text.toLowerCase().replaceAll(' ', '')}',
        _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : '${_getSelectedSensorType()['label']} - ${_sensorNameController.text}',
      );

      // Preparar dados de exemplo para o tipo de sensor
      final sensorData = _generateSampleData();

      // Enviar dados via middleware para InterSCity
      await _apiService.sendMessage(
        provider.currentProject!.token!,
        producer.id,
        sensorData.toString(),
      );

      setState(() {
        _successMessage = '✅ Integração criada com sucesso!\n\n'
            'Sensor: ${_sensorNameController.text}\n'
            'Tipo: ${_getSelectedSensorType()['label']}\n'
            'Localização: ${_locationController.text}\n\n'
            'Dados enviados para InterSCity via middleware!';
      });

      // Limpar formulário após sucesso
      _formKey.currentState!.reset();
      _sensorNameController.clear();
      _locationController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _descriptionController.clear();
    } catch (e) {
      setState(() {
        _error = '❌ Erro ao criar integração: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getSelectedSensorType() {
    return _sensorTypes
        .firstWhere((type) => type['value'] == _selectedSensorType);
  }

  Map<String, dynamic> _generateSampleData() {
    final sensorType = _getSelectedSensorType();
    final baseData = {
      'sensor_id':
          '${_selectedSensorType}_${DateTime.now().millisecondsSinceEpoch}',
      'sensor_name': _sensorNameController.text,
      'location': _locationController.text,
      'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
      'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
      'sensor_type': _selectedSensorType,
      'region': _selectedRegion,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Adicionar dados específicos do tipo de sensor
    switch (_selectedSensorType) {
      case 'traffic':
        baseData.addAll({
          'vehicle_count': 45,
          'average_speed': 35.5,
          'congestion_level': 'baixo',
        });
        break;
      case 'air_quality':
        baseData.addAll({
          'pm25': 12.3,
          'pm10': 25.7,
          'co2': 420,
          'air_quality_index': 'boa',
        });
        break;
      case 'lighting':
        baseData.addAll({
          'brightness': 0.8,
          'energy_consumption': 2.3,
          'status': 'ligado',
        });
        break;
      case 'waste':
        baseData.addAll({
          'fill_level': 65.0,
          'temperature': 28.5,
          'last_collection': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        });
        break;
      case 'parking':
        baseData.addAll({
          'available_spots': 15,
          'total_spots': 50,
          'occupancy_rate': 70.0,
        });
        break;
    }

    return baseData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Integração InterSCity'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildIntegrationForm(),
            if (_error != null) _buildErrorCard(),
            if (_successMessage != null) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: Colors.teal.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Nova Integração',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                    ),
                    Text(
                      'Configure um novo sensor para integração com InterSCity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal.shade600,
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
                    'Como funciona:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildStep('1. Configure o sensor',
                      'Defina tipo, localização e parâmetros'),
                  _buildStep('2. Middleware processa',
                      'Roteia dados para InterSCity Adapter'),
                  _buildStep('3. InterSCity recebe',
                      'Dados são registrados na plataforma'),
                  _buildStep('4. Integração ativa',
                      'Sensor começa a enviar dados em tempo real'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.teal.shade600, size: 20),
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

  Widget _buildIntegrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuração do Sensor',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Tipo de Sensor
          _buildSensorTypeSelector(),
          const SizedBox(height: 16),

          // Campos básicos
          _buildTextField(
            controller: _sensorNameController,
            label: 'Nome do Sensor',
            hint: 'Ex: Sensor Centro Histórico',
            icon: Icons.sensors,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nome do sensor é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _locationController,
            label: 'Localização',
            hint: 'Ex: Av. Principal, 123 - São Luís/MA',
            icon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Localização é obrigatória';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Coordenadas
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _latitudeController,
                  label: 'Latitude',
                  hint: 'Ex: -2.5297',
                  icon: Icons.gps_fixed,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _longitudeController,
                  label: 'Longitude',
                  hint: 'Ex: -44.3028',
                  icon: Icons.gps_fixed,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Região
          _buildRegionSelector(),
          const SizedBox(height: 16),

          // Descrição
          _buildTextField(
            controller: _descriptionController,
            label: 'Descrição (opcional)',
            hint: 'Descreva o propósito deste sensor...',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Botão de criação
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _createIntegration,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading
                  ? 'Criando Integração...'
                  : 'Criar Integração InterSCity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Sensor *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _sensorTypes.length,
          itemBuilder: (context, index) {
            final sensorType = _sensorTypes[index];
            final isSelected = _selectedSensorType == sensorType['value'];

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSensorType = sensorType['value'];
                });
              },
              child: Card(
                color: isSelected ? sensorType['color'].withOpacity(0.1) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sensorType['icon'],
                        color: isSelected
                            ? sensorType['color']
                            : Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sensorType['label'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? sensorType['color'] : null,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sensorType['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Região *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.public),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _regions.map((region) {
            return DropdownMenuItem(
              value: region['value'],
              child: Text(region['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRegion = value!;
            });
          },
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
                  'Integração Criada!',
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
}
