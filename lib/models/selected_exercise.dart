import 'package:business_ia/models/serie.dart';

class SelectedExercise {
  final String id;
  final String name;
  final String category;
  List<Series> series;

  SelectedExercise({
    required this.id,
    required this.name,
    required this.category,
    List<Series>? series,
  }) : series = series ?? [Series(repetitions: 10, weight: 0)];

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': id,
      'name': name,
      'category': category,
      'series': series.map((s) => s.toMap()).toList(),
    };
  }

  factory SelectedExercise.fromMap(Map<String, dynamic> map) {
    return SelectedExercise(
      id: map['exerciseId'],
      name: map['name'],
      category: map['category'],
      series: (map['series'] as List<dynamic>)
          .map((s) => Series.fromMap(s))
          .toList(),
    );
  }
}
