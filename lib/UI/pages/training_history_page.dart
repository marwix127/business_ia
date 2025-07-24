import 'package:business_ia/UI/pages/training_detail_page.dart';
import 'package:business_ia/UI/pages/training_page.dart';
import 'package:business_ia/models/training.dart';
import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:flutter/material.dart';

class TrainingHistoryPage extends StatefulWidget {
  const TrainingHistoryPage({super.key});

  @override
  State<TrainingHistoryPage> createState() => _TrainingHistoryPageState();
}

class _TrainingHistoryPageState extends State<TrainingHistoryPage> {
  late Future<List<Training>> _trainingsFuture;
  final TrainingService _trainingService = TrainingService();

  @override
  void initState() {
    super.initState();
    _trainingsFuture = _trainingService.getTrainings();
  }

  void _navigateToNewTraining() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPage()),
    );

    // Si el usuario guardó algo, recarga la lista
    if (result != null) {
      setState(() {
        _trainingsFuture = _trainingService.getTrainings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de entrenamientos")),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewTraining,
        child: const Icon(Icons.add),
        tooltip: "Nuevo entrenamiento",
      ),
      body: FutureBuilder<List<Training>>(
        future: _trainingsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trainings = snapshot.data!;
          if (trainings.isEmpty) {
            return const Center(
              child: Text("No hay entrenamientos registrados."),
            );
          }

          return ListView.builder(
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              final training = trainings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(training.name),
                  subtitle: Text(
                    "Fecha: ${training.date.toLocal().toString().split(' ')[0]}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingDetailPage(training: training),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _trainingsFuture = _trainingService.getTrainings();
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
