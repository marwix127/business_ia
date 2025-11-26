import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class EjercicioService {
  final _db = FirebaseFirestore.instance;

  Future<void> cargarEjerciciosInicialesSiEsNecesario() async {
    final snap = await _db.collection('ejercicios2').get();

    if (snap.docs.isEmpty) {
      final jsonString = await rootBundle.loadString('assets/ejercicios2.json');
      final List<dynamic> ejercicios = jsonDecode(jsonString);

      for (final ej in ejercicios) {
        await _db.collection('ejercicios2').add({
          ...ej,
          'esPersonalizado': false,
          'uid': null,
        });
      }
    } else {}
  }

  Future<List<String>> obtenerCategoriasUnicas() async {
    final snapshot = await _db.collection('ejercicios2').get();
    final categorias = snapshot.docs
        .map((doc) => doc['categoria'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    categorias.sort();
    return categorias;
  }

  Future<List<Map<String, dynamic>>> obtenerPorCategoria(
    String categoria,
  ) async {
    final snapshot = await _db
        .collection('ejercicios2')
        .where('categoria', isEqualTo: categoria)
        .get();

    // ⬅️ Incluye el doc.id junto con los datos
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id, // 👈 aquí guardas el id
        ...data,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosEjercicios() async {
    final snapshot = await _db.collection('ejercicios2').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }

  Future<void> agregarEjercicioPersonalizado(
    Map<String, dynamic> ejercicio,
  ) async {
    await _db.collection('ejercicios2').add({
      ...ejercicio,
      'esPersonalizado': true,
    });
  }

  Future<void> eliminarEjercicio(String id) async {
    await _db.collection('ejercicios2').doc(id).delete();
  }

  Future<void> actualizarEjercicio(
    String id,
    Map<String, dynamic> ejercicio,
  ) async {
    await _db.collection('ejercicios2').doc(id).update(ejercicio);
  }
}
