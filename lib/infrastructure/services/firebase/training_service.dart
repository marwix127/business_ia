import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/training.dart';

class TrainingService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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

    await _db
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .add(training.toMap());
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
