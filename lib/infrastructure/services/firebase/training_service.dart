import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/training.dart';
import '../../../models/serie.dart';

class TrainingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<Series>?> getLastSeriesForExercise(String exerciseId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Get last 50 trainings to find the most recent one with this exercise
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    for (var doc in snap.docs) {
      final data = doc.data();
      final exercisesList = data['exercises'] as List<dynamic>?;

      if (exercisesList != null) {
        // Check if this training contains the exercise
        final exerciseData = exercisesList.firstWhere(
          (e) => e['exerciseId'] == exerciseId,
          orElse: () => null,
        );

        if (exerciseData != null) {
          final seriesList = exerciseData['series'] as List<dynamic>?;
          if (seriesList != null) {
            return seriesList.map((s) => Series.fromMap(s)).toList();
          }
        }
      }
    }
    return null;
  }

  Future<List<Training>> getTrainings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return Training.fromFirestore(doc.id, data);
    }).toList();
  }

  Future<void> saveTraining(Training training) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');
    final trainingsRef = _db
        .collection('users')
        .doc(uid)
        .collection('trainings');

    // If training has an id, update that document; otherwise add a new one.
    if (training.id.isNotEmpty) {
      await trainingsRef.doc(training.id).set(training.toMap());
    } else {
      await trainingsRef.add(training.toMap());
    }
  }

  Future<void> deleteTraining(Training training) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trainings')
          .doc(training.id) // ✅ importante: usar el ID del documento
          .delete();

      // ← indicamos al historial que se actualice
    } catch (e) {
      throw Exception('Error al eliminar el entrenamiento: $e');
    }
  }
}
