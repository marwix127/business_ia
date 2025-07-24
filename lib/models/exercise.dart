class Exercise {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? type;
  final String? level;
  final String? uid; // null if it's a global exercise
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.type,
    this.level,
    this.uid,
    this.isCustom = false,
  });

  factory Exercise.fromFirestore(String id, Map<String, dynamic> data) {
    return Exercise(
      id: id,
      name: data['nombre'],
      category: data['categoria'],
      description: data['descripcion'],
      type: data['tipo'],
      level: data['nivel'],
      uid: data['uid'],
      isCustom: data['esPersonalizado'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': name,
    'categoria': category,
    'descripcion': description,
    'tipo': type,
    'nivel': level,
    'uid': uid,
    'esPersonalizado': isCustom,
  };
}
