import 'package:flutter/material.dart';
import 'package:business_ia/models/training.dart';
import 'package:business_ia/infrastructure/services/firebase/training_service.dart';

class TrainingDetailPage extends StatelessWidget {
  TrainingDetailPage({super.key, required this.training});
  final Training training;
  final TrainingService trainingService = TrainingService();

  Future<void> _deleteTraining(BuildContext context) async {
    try {
      await trainingService.deleteTraining(training);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entrenamiento eliminado')));

      Navigator.pop(context, true); // ← indicamos al historial que se actualice
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este entrenamiento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // cerrar el diálogo
              await _deleteTraining(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(training.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Fecha: ${training.date.toLocal().toString().split(' ')[0]}"),
            if (training.weight != null)
              Text("Peso corporal: ${training.weight} kg"),
            const SizedBox(height: 16),
            ...training.exercises.map(
              (e) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...e.series.asMap().entries.map((entry) {
                        final i = entry.key + 1;
                        final s = entry.value;
                        return Text(
                          "Serie $i: ${s.weight} kg x ${s.repetitions} reps",
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
