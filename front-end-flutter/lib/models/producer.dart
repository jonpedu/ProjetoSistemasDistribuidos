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
    final status = json['status']?.toString() ?? 'unknown';

    print('🔍 [Producer.fromJson] Campos parseados:');
    print('  - ID: "$id"');
    print('  - Name: "$name"');
    print('  - Description: "$description"');
    print('  - Status: "$status"');

    return Producer(
      id: id,
      name: name,
      description: description,
      status: status,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      brokerId: json['brokerId']?.toString(),
      strategyId: json['strategyId']?.toString(),
      messageCount: json['messageCount'] ?? 0,
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
