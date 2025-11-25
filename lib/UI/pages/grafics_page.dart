import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:business_ia/models/selected_exercise.dart';
import 'package:business_ia/models/training.dart';
import 'package:flutter/material.dart';
import 'package:business_ia/UI/widgets/volume_chart.dart';
import 'package:business_ia/UI/widgets/average_weight.dart';

List<Map<String, dynamic>> calcularVolumenPorEjercicio(
  List<Training> trainings,
  String nombreEjercicio,
) {
  return trainings
      .map((training) {
        final ejercicio = training.exercises.firstWhere(
          (e) => e.name.toLowerCase() == nombreEjercicio.toLowerCase(),
          orElse: () =>
              SelectedExercise(id: '', name: '', category: '', series: []),
        );

        final volumen = ejercicio.series.fold<double>(
          0,
          (total, serie) => total + (serie.weight * serie.repetitions),
        );

        return {'date': training.date, 'volumen': volumen};
      })
      .where((e) => (e['volumen'] as num) > 0)
      .toList();
}

List<Map<String, dynamic>> calcularPesoMedioPorEjercicio(
  List<Training> trainings,
  String nombreEjercicio,
) {
  return trainings
      .map((training) {
        final ejercicio = training.exercises.firstWhere(
          (e) => e.name.toLowerCase() == nombreEjercicio.toLowerCase(),
          orElse: () =>
              SelectedExercise(id: '', name: '', category: '', series: []),
        );

        if (ejercicio.series.isEmpty) {
          return {'date': training.date, 'average_weight': 0.0};
        }

        final totalWeight = ejercicio.series.fold<double>(
          0,
          (total, serie) => total + serie.weight,
        );
        final average = totalWeight / ejercicio.series.length;

        return {'date': training.date, 'average_weight': average};
      })
      .where((e) => (e['average_weight'] as num) > 0)
      .toList();
}

class GraficsPage extends StatefulWidget {
  const GraficsPage({super.key});

  @override
  State<GraficsPage> createState() => _GraficsPageState();
}

class _GraficsPageState extends State<GraficsPage> {
  List<Training> trainings = [];
  String? selectedExercise;
  String chartType = 'Volumen';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTrainings();
  }

  Future<void> loadTrainings() async {
    final loaded = await TrainingService()
        .getTrainings(); // 👈 este método ya lo tienes
    setState(() {
      trainings = loaded;
      loading = false;
    });
  }

  List<String> getAllExercises() {
    final all = trainings
        .expand((t) => t.exercises)
        .map((e) => e.name)
        .toSet()
        .toList();
    all.sort();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chartData = selectedExercise == null
        ? []
        : chartType == 'Volumen'
        ? calcularVolumenPorEjercicio(trainings, selectedExercise!)
        : calcularPesoMedioPorEjercicio(trainings, selectedExercise!);

    return Scaffold(
      appBar: AppBar(title: const Text("Volumen de Entrenamiento")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: const Text("Selecciona un ejercicio"),
              value: selectedExercise,
              isExpanded: true,
              items: getAllExercises()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedExercise = value);
              },
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Volumen', label: Text('Volumen')),
                ButtonSegment(value: 'Peso Medio', label: Text('Peso Medio')),
              ],
              selected: {chartType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  chartType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            if (chartData.isEmpty)
              const Text("No hay datos para este ejercicio")
            else
              Expanded(
                child: chartType == 'Volumen'
                    ? VolumenChart(data: chartData.cast<Map<String, dynamic>>())
                    : AverageWeightChart(
                        data: chartData.cast<Map<String, dynamic>>(),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
