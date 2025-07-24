import 'package:business_ia/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';

class ExercisesByCategories extends StatelessWidget {
  final String categoria;
  const ExercisesByCategories({required this.categoria, super.key});

  Future<List<Map<String, dynamic>>> obtenerEjercicios() async {
    return EjercicioService().obtenerPorCategoria(categoria);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoria)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerEjercicios(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ejercicios = snapshot.data!;
          return ListView.builder(
            itemCount: ejercicios.length,
            itemBuilder: (context, index) {
              final ejercicio = ejercicios[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(ejercicio['nombre']),
                subtitle: Text(ejercicio['descripcion'] ?? ''),
                onTap: () {
                  Navigator.pop(context, ejercicio); // ✅ ya contiene el id
                },
              );
            },
          );
        },
      ),
    );
  }
}
