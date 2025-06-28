class Project {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime createdAt;
  final String token;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.token,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'token': token,
    };
  }
}
