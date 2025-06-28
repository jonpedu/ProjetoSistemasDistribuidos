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
    return Producer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      brokerId: json['brokerId'],
      strategyId: json['strategyId'],
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
