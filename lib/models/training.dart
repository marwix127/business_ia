import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:business_ia/models/selected_exercise.dart';

class Training {
  final String id; // Added to uniquely identify the training
  final String name;
  final double? weight;
  final DateTime date;
  final List<SelectedExercise> exercises;

  Training({
    required this.id, // Default to empty string if not provided
    required this.name,
    required this.date,
    this.weight,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weight': weight,
      'date': Timestamp.fromDate(date),
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory Training.fromFirestore(String id, Map<String, dynamic> data) {
    return Training(
      id: id,
      name: data['name'],
      weight: (data['weight'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      exercises: (data['exercises'] as List<dynamic>)
          .map((e) => SelectedExercise.fromMap(e))
          .toList(),
    );
  }
}
