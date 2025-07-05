import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sensor.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class TrafficSensorDashboard extends StatefulWidget {
  const TrafficSensorDashboard({super.key});

  @override
  State<TrafficSensorDashboard> createState() => _TrafficSensorDashboardState();
}

class _TrafficSensorDashboardState extends State<TrafficSensorDashboard> {
  final ApiService _apiService = ApiService();
  List<TrafficSensor> _sensors = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simular delay de API
      await Future.delayed(const Duration(seconds: 2));

      // Simular dados de sensores de trânsito
      _sensors = [
        TrafficSensor(
          id: 'traffic_001',
          name: 'Sensor Av. Principal',
          location: 'Av. Principal, 123 - São Luís/MA',
          latitude: -2.5297,
          longitude: -44.3028,
          vehicleCount: 45,
          averageSpeed: 35.5,
          congestionLevel: 'Baixo',
          status: 'Ativo',
          lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        TrafficSensor(
          id: 'traffic_002',
          name: 'Sensor Shopping',
          location: 'Shopping da Ilha - São Luís/MA',
          latitude: -2.5310,
          longitude: -44.3040,
          vehicleCount: 89,
          averageSpeed: 18.2,
          congestionLevel: 'Alto',
          status: 'Ativo',
          lastUpdate: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        TrafficSensor(
          id: 'traffic_003',
          name: 'Sensor Centro Histórico',
          location: 'Centro Histórico - São Luís/MA',
          latitude: -2.5280,
          longitude: -44.3000,
          vehicleCount: 32,
          averageSpeed: 42.1,
          congestionLevel: 'Baixo',
          status: 'Ativo',
          lastUpdate: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ];
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar sensores: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSensors() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Simular delay de API
      await Future.delayed(const Duration(seconds: 2));

      // Simular dados de sensores de trânsito com valores atualizados
      _sensors = [
        TrafficSensor(
          id: 'traffic_001',
          name: 'Sensor Av. Principal',
          location: 'Av. Principal, 123 - São Luís/MA',
          latitude: -2.5297,
          longitude: -44.3028,
          vehicleCount: 52, // Valor atualizado
          averageSpeed: 38.2, // Valor atualizado
          congestionLevel: 'Baixo',
          status: 'Ativo',
          lastUpdate: DateTime.now(),
        ),
        TrafficSensor(
          id: 'traffic_002',
          name: 'Sensor Shopping',
          location: 'Shopping da Ilha - São Luís/MA',
          latitude: -2.5310,
          longitude: -44.3040,
          vehicleCount: 76, // Valor atualizado
          averageSpeed: 22.1, // Valor atualizado
          congestionLevel: 'Moderado', // Valor atualizado
          status: 'Ativo',
          lastUpdate: DateTime.now(),
        ),
        TrafficSensor(
          id: 'traffic_003',
          name: 'Sensor Centro Histórico',
          location: 'Centro Histórico - São Luís/MA',
          latitude: -2.5280,
          longitude: -44.3000,
          vehicleCount: 28, // Valor atualizado
          averageSpeed: 45.3, // Valor atualizado
          congestionLevel: 'Baixo',
          status: 'Ativo',
          lastUpdate: DateTime.now(),
        ),
      ];
    } catch (e) {
      setState(() {
        _error = 'Erro ao atualizar sensores: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _sendSensorDataToInterSCity(TrafficSensor sensor) async {
    try {
      final provider = context.read<AppProvider>();
      if (provider.currentProject?.token == null) {
        throw Exception('Token do projeto não encontrado');
      }

      // Criar produtor para InterSCity se não existir
      final producer = await _apiService.createProducer(
        provider.currentProject!.token!,
        'sensor${sensor.id}',
        'Sensor de Trânsito ${sensor.name}',
      );

      // Preparar dados no formato InterSCity
      final sensorData = sensor.toInterSCityFormat();

      // Enviar dados via middleware para InterSCity
      await _apiService.sendMessage(
        provider.currentProject!.token!,
        producer.id,
        sensorData.toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Dados do sensor ${sensor.name} enviados para InterSCity!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao enviar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Sensores de Trânsito'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSensors,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando sensores...'),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error,
                              size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadSensors,
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshSensors,
                      child: Column(
                        children: [
                          _buildHeader(),
                          Expanded(
                            child: _buildSensorsList(),
                          ),
                        ],
                      ),
                    ),
          // Loading overlay durante o refresh
          if (_isRefreshing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Atualizando sensores...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.traffic, color: Colors.orange.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensores de Trânsito',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                    ),
                    Text(
                      'Integração com InterSCity via Middleware',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Total de Sensores',
                _sensors.length.toString(),
                Icons.sensors,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Ativos',
                _sensors.where((s) => s.status == 'Ativo').length.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Congestionados',
                _sensors
                    .where((s) => s.congestionLevel == 'Alto')
                    .length
                    .toString(),
                Icons.warning,
                Colors.orange,
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
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildSensorsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sensors.length,
      itemBuilder: (context, index) {
        final sensor = _sensors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.traffic,
                      color: _getCongestionColor(sensor.congestionLevel),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            sensor.location,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(sensor.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildDataItem('Veículos', '${sensor.vehicleCount}',
                        Icons.directions_car),
                    const SizedBox(width: 16),
                    _buildDataItem('Velocidade', '${sensor.averageSpeed} km/h',
                        Icons.speed),
                    const SizedBox(width: 16),
                    _buildDataItem(
                        'Congestão', sensor.congestionLevel, Icons.traffic),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Última atualização: ${_formatTime(sensor.lastUpdate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'ativo':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inativo':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.warning;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Color _getCongestionColor(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return Colors.green;
      case 'moderado':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
