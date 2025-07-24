import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final int age;
  final int height;
  final String gender;
  final String currentGoal;
  final double currentWeight;
  final double currentBodyFat;
  final double currentMuscle;
  final DateTime lastUpdate;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.height,
    required this.gender,
    required this.currentGoal,
    required this.currentWeight,
    required this.currentBodyFat,
    required this.currentMuscle,
    required this.lastUpdate,
  });

  factory User.fromMap(String uid, Map<String, dynamic> data) {
    return User(
      uid: uid,
      name: data['name'],
      email: data['email'],
      age: data['age'],
      height: data['height'],
      gender: data['gender'],
      currentGoal: data['currentGoal'],
      currentWeight: (data['currentWeight'] ?? 0).toDouble(),
      currentBodyFat: (data['currentBodyFat'] ?? 0).toDouble(),
      currentMuscle: (data['currentMuscle'] ?? 0).toDouble(),
      lastUpdate: (data['lastUpdate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'age': age,
    'height': height,
    'gender': gender,
    'currentGoal': currentGoal,
    'currentWeight': currentWeight,
    'currentBodyFat': currentBodyFat,
    'currentMuscle': currentMuscle,
    'lastUpdate': lastUpdate,
  };
}
