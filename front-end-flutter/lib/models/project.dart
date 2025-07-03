class Project {
  final String id;
  final String name;
  final String location;
  final String region;
  final List<String> supportedBrokers;
  final String token;

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.region,
    required this.supportedBrokers,
    required this.token,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      region: json['region'] ?? '',
      supportedBrokers: List<String>.from(json['supportedBrokers'] ?? []),
      token: json['authToken'] ?? '', // Backend retorna 'authToken'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'region': region,
      'supportedBrokers': supportedBrokers,
      'token': token,
    };
  }
}
