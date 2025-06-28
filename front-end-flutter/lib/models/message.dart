class Message {
  final String id;
  final String content;
  final String producerId;
  final String producerName;
  final DateTime timestamp;
  final String status;
  final String? brokerId;
  final String? strategyId;

  Message({
    required this.id,
    required this.content,
    required this.producerId,
    required this.producerName,
    required this.timestamp,
    required this.status,
    this.brokerId,
    this.strategyId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      producerId: json['producerId'] ?? '',
      producerName: json['producerName'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      brokerId: json['brokerId'],
      strategyId: json['strategyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'producerId': producerId,
      'producerName': producerName,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'brokerId': brokerId,
      'strategyId': strategyId,
    };
  }
}
