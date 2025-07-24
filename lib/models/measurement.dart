import 'package:cloud_firestore/cloud_firestore.dart';

class Measurement {
  final DateTime date;
  final double weight;
  final double fat;
  final double muscle;

  Measurement({
    required this.date,
    required this.weight,
    required this.fat,
    required this.muscle,
  });

  factory Measurement.fromMap(Map<String, dynamic> data) {
    return Measurement(
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['currentWeight'] ?? 0).toDouble(),
      fat: (data['currentBodyFat'] ?? 0).toDouble(),
      muscle: (data['currentMuscle'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'fecha': date,
    'currentWeight': weight,
    'currentBodyFat': fat,
    'currentMuscle': muscle,
  };
}
