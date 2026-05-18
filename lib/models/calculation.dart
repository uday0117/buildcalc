class Calculation {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> results;
  final DateTime timestamp;

  Calculation({
    required this.id,
    required this.type,
    required this.title,
    required this.inputs,
    required this.results,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'inputs': inputs,
      'results': results,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Calculation.fromJson(Map<String, dynamic> json) {
    return Calculation(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      inputs: Map<String, dynamic>.from(json['inputs']),
      results: Map<String, dynamic>.from(json['results']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
