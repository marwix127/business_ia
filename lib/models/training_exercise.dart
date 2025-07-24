import 'package:business_ia/models/serie.dart';

class TrainingExercise {
  final String exerciseId;
  final String name;
  final List<Series> series;

  TrainingExercise({
    required this.exerciseId,
    required this.name,
    required this.series,
  });

  factory TrainingExercise.fromMap(Map<String, dynamic> map) {
    return TrainingExercise(
      exerciseId: map['exerciseId'],
      name: map['name'],
      series: (map['series'] as List<dynamic>)
          .map((s) => Series.fromMap(s))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'name': name,
    'series': series.map((s) => s.toMap()).toList(),
  };
}
