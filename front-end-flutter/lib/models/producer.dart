class Producer {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? brokerId;
  final String? strategyId;
  final int messageCount;

  Producer({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    this.brokerId,
    this.strategyId,
    this.messageCount = 0,
  });

  factory Producer.fromJson(Map<String, dynamic> json) {
    // Log para debug do que está chegando da API
    print('🔍 [Producer.fromJson] Raw JSON: $json');

    final id = json['id']?.toString() ?? '';
    final name = json['username']?.toString() ?? json['name']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final status = json['status']?.toString() ?? 'active';

    // Tentar parsear a data em diferentes formatos
    DateTime createdAt;
    try {
      final createdAtStr = json['createdAt']?.toString() ??
          json['created_at']?.toString() ??
          json['timestamp']?.toString();

      if (createdAtStr != null) {
        createdAt = DateTime.parse(createdAtStr);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('⚠️ [Producer.fromJson] Erro ao parsear timestamp: $e');
      createdAt = DateTime.now();
    }

    print('🔍 [Producer.fromJson] Dados finais:');
    print('  - ID: "$id"');
    print('  - Name: "$name"');
    print('  - Description: "$description"');
    print('  - Status: "$status"');
    print('  - CreatedAt: "$createdAt"');

    return Producer(
      id: id,
      name: name,
      description: description,
      status: status,
      createdAt: createdAt,
      brokerId: json['brokerId']?.toString() ?? json['broker_id']?.toString(),
      strategyId:
          json['strategyId']?.toString() ?? json['strategy_id']?.toString(),
      messageCount: json['messageCount'] ?? json['message_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'brokerId': brokerId,
      'strategyId': strategyId,
      'messageCount': messageCount,
    };
  }
}
