class ProjectMaterial {
  final String id;
  final String name;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double wastagePercent;

  const ProjectMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.wastagePercent,
  });

  double get adjustedQuantity => quantity * (1 + (wastagePercent / 100));

  double get lineTotal => adjustedQuantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'wastagePercent': wastagePercent,
    };
  }

  factory ProjectMaterial.fromJson(Map<String, dynamic> json) {
    return ProjectMaterial(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'unit',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      wastagePercent: (json['wastagePercent'] ?? 0).toDouble(),
    );
  }
}

class ProjectHistoryEntry {
  final String id;
  final String title;
  final DateTime timestamp;
  final String? note;

  const ProjectHistoryEntry({
    required this.id,
    required this.title,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory ProjectHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ProjectHistoryEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Project update',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      note: json['note'],
    );
  }
}

class Project {
  final String id;
  final String name;
  final String location;
  final double budget;
  final DateTime createdAt;
  final String notes;
  final List<ProjectMaterial> materials;
  final List<ProjectHistoryEntry> history;

  const Project({
    required this.id,
    required this.name,
    required this.location,
    required this.budget,
    required this.createdAt,
    required this.notes,
    this.materials = const [],
    this.history = const [],
  });

  double get totalMaterialCost {
    return materials.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  double get totalQuantity {
    return materials.fold(0.0, (sum, item) => sum + item.adjustedQuantity);
  }

  double get budgetRemaining => budget - totalMaterialCost;

  double get coveragePercent {
    if (budget <= 0) return 0;
    return ((totalMaterialCost / budget) * 100).clamp(0.0, 100.0);
  }

  String get statusLabel {
    if (budgetRemaining < 0) return 'Over budget';
    if (budgetRemaining == 0) return 'Exactly at budget';
    return 'Within budget';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'budget': budget,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'materials': materials.map((m) => m.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawMaterials = json['materials'] as List? ?? const [];
    final rawHistory = json['history'] as List? ?? const [];

    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled project',
      location: json['location'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      notes: json['notes'] ?? '',
      materials: rawMaterials
          .map(
            (item) => ProjectMaterial.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      history: rawHistory
          .map(
            (item) =>
                ProjectHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
