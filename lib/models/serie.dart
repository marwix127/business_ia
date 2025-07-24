class Series {
  int repetitions = 0;
  double weight;

  Series({required this.repetitions, required this.weight});

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      repetitions: map['repetitions'],
      weight: (map['weight'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'repetitions': repetitions,
    'weight': weight,
  };
}
