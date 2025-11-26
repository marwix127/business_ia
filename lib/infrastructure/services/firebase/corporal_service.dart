import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:business_ia/infrastructure/services/firebase/auth_service.dart';

class CorporalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // 📝 Agregar medición
  Future<void> addMeasurement(Map<String, dynamic> data) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_measurements')
          .add({...data, 'date': FieldValue.serverTimestamp()});
    } catch (e) {
      rethrow;
    }
  }

  // 📋 Obtener mediciones
  Stream<QuerySnapshot> getMeasurements() {
    final user = _authService.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('body_measurements')
        .orderBy('date', descending: true)
        .snapshots();
  }
}
