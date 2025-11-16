import 'package:business_ia/models/training.dart';
import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final result = await context.push('/training');
    if (result != null) {
      setState(() {
        _trainingsFuture = _trainingService.getTrainings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewTraining,
        tooltip: "Nuevo entrenamiento",
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
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
                    final result = await context.push(
                      '/training',
                      extra: training,
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

