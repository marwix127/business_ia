import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:business_ia/models/selected_exercise.dart';
import 'package:business_ia/models/serie.dart';
import 'package:business_ia/models/training.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_ia/infrastructure/services/local/training_draft_service.dart';
import 'exercises_categories.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with WidgetsBindingObserver {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final List<SelectedExercise> selectedExercises = [];

  bool get _hasUnsavedChanges {
    return _nombreController.text.isNotEmpty ||
        _pesoController.text.isNotEmpty ||
        selectedExercises.isNotEmpty;
  }

  Future<bool> _confirmExit() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text(
          'Hay cambios sin guardar. ¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void addExercise(Map<String, dynamic> ejercicio) {
    final alreadyAdded = selectedExercises.any((e) => e.id == ejercicio['id']);
    if (alreadyAdded) return;

    setState(() {
      selectedExercises.add(
        SelectedExercise(
          id: ejercicio['id'],
          name: ejercicio['nombre'],
          category: ejercicio['categoria'],
        ),
      );
    });
  }

  void startExerciseSelection() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExercisesCategories()),
    );

    if (selected != null && selected is Map<String, dynamic>) {
      addExercise(selected);
    }
  }

  void updateSeries(
    int exerciseIndex,
    int seriesIndex,
    String field,
    String value,
  ) {
    setState(() {
      final serie = selectedExercises[exerciseIndex].series[seriesIndex];
      if (field == 'weight') {
        serie.weight = double.tryParse(value) ?? 0;
      } else {
        serie.repetitions = int.tryParse(value) ?? 0;
      }
    });
  }

  final TrainingDraftService _draftService = TrainingDraftService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nombreController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save draft when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    final data = {
      'name': _nombreController.text,
      'weight': _pesoController.text,
      'exercises': selectedExercises.map((e) => e.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    try {
      await _draftService.saveDraft(data);
    } catch (_) {
      // ignore save errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _confirmExit()) {
              if (mounted) context.pop();
            }
          },
        ),
        title: const Text('Entrenamiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del entrenamiento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _pesoController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: selectedExercises.isEmpty
                  ? const Center(child: Text("No hay ejercicios añadidos."))
                  : ListView.builder(
                      itemCount: selectedExercises.length,
                      itemBuilder: (context, i) {
                        final ejercicio = selectedExercises[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ejercicio.name,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(
                                          () => selectedExercises.removeAt(i),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: ejercicio.series.length,
                                  itemBuilder: (context, j) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Peso (kg)',
                                              hintText: 'Ej: 20',
                                            ),
                                            onChanged: (value) => updateSeries(
                                              i,
                                              j,
                                              'weight',
                                              value,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Reps',
                                              hintText: 'Ej: 10',
                                            ),
                                            onChanged: (value) => updateSeries(
                                              i,
                                              j,
                                              'reps',
                                              value,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              ejercicio.series.removeAt(j);
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      ejercicio.series.add(
                                        Series(repetitions: 0, weight: 0),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Añadir serie'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: startExerciseSelection,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar ejercicio'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final name = _nombreController.text.trim();
                      final weight = double.tryParse(
                        _pesoController.text.trim(),
                      );

                      if (name.isEmpty || selectedExercises.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Añade un nombre y al menos un ejercicio.",
                            ),
                          ),
                        );
                        return;
                      }

                      final training = Training(
                        id: '', // ID will be generated by Firestore
                        name: name,
                        weight: weight,
                        date: DateTime.now(),
                        exercises: selectedExercises,
                      );

                      try {
                        await TrainingService().saveTraining(training);
                        // remove any saved draft now that we've persisted
                        try {
                          await _draftService.removeDraft();
                        } catch (_) {}
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Entrenamiento guardado con éxito"),
                          ),
                        );
                        context.pop(true); // volver atrás tras guardar
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error al guardar: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
