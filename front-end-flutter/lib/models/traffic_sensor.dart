class TrafficSensor {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final int vehicleCount;
  final double averageSpeed;
  final String congestionLevel;
  final String status;
  final DateTime lastUpdate;

  TrafficSensor({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.vehicleCount,
    required this.averageSpeed,
    required this.congestionLevel,
    required this.status,
    required this.lastUpdate,
  });

  factory TrafficSensor.fromJson(Map<String, dynamic> json) {
    return TrafficSensor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      vehicleCount: json['vehicleCount'] ?? 0,
      averageSpeed: (json['averageSpeed'] ?? 0.0).toDouble(),
      congestionLevel: json['congestionLevel'] ?? 'Desconhecido',
      status: json['status'] ?? 'Inativo',
      lastUpdate: DateTime.parse(
          json['lastUpdate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'vehicleCount': vehicleCount,
      'averageSpeed': averageSpeed,
      'congestionLevel': congestionLevel,
      'status': status,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  // Método para converter para formato InterSCity
  Map<String, dynamic> toInterSCityFormat() {
    return {
      'sensor_id': id,
      'location': location,
      'vehicle_count': vehicleCount,
      'average_speed': averageSpeed,
      'congestion_level': congestionLevel,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Método para criar uma cópia com dados atualizados
  TrafficSensor copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    int? vehicleCount,
    double? averageSpeed,
    String? congestionLevel,
    String? status,
    DateTime? lastUpdate,
  }) {
    return TrafficSensor(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      congestionLevel: congestionLevel ?? this.congestionLevel,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() {
    return 'TrafficSensor(id: $id, name: $name, location: $location, vehicleCount: $vehicleCount, averageSpeed: $averageSpeed, congestionLevel: $congestionLevel, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrafficSensor && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
