import 'package:flutter/material.dart';
import 'package:business_ia/models/training.dart';
import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:business_ia/models/selected_exercise.dart';
import 'package:business_ia/models/serie.dart';
import 'exercises_categories.dart';

class TrainingDetailPage extends StatefulWidget {
  TrainingDetailPage({super.key, required this.training});
  final Training training;

  @override
  State<TrainingDetailPage> createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late List<SelectedExercise> editableExercises;
  final TrainingService _trainingService = TrainingService();

  bool get _hasUnsavedChanges {
    if (_nameController.text != widget.training.name) return true;
    if (_weightController.text != (widget.training.weight?.toString() ?? ''))
      return true;
    if (editableExercises.length != widget.training.exercises.length)
      return true;

    // Comprobar si los ejercicios o sus series han cambiado
    for (var i = 0; i < editableExercises.length; i++) {
      final edited = editableExercises[i];
      final original = widget.training.exercises[i];

      if (edited.id != original.id ||
          edited.series.length != original.series.length) {
        return true;
      }

      for (var j = 0; j < edited.series.length; j++) {
        if (edited.series[j].weight != original.series[j].weight ||
            edited.series[j].repetitions != original.series[j].repetitions) {
          return true;
        }
      }
    }

    return false;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.training.name);
    _weightController = TextEditingController(
      text: widget.training.weight != null
          ? widget.training.weight.toString()
          : '',
    );

    // Deep copy exercises and series so edits don't mutate the original instance
    editableExercises = widget.training.exercises
        .map(
          (e) => SelectedExercise(
            id: e.id,
            name: e.name,
            category: e.category,
            series: e.series
                .map(
                  (s) => Series(repetitions: s.repetitions, weight: s.weight),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void addExercise(Map<String, dynamic> ejercicio) {
    final alreadyAdded = editableExercises.any((e) => e.id == ejercicio['id']);
    if (alreadyAdded) return;

    setState(() {
      editableExercises.add(
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
      final serie = editableExercises[exerciseIndex].series[seriesIndex];
      if (field == 'weight') {
        serie.weight = double.tryParse(value) ?? 0;
      } else {
        serie.repetitions = int.tryParse(value) ?? 0;
      }
    });
  }

  Future<void> _deleteTraining() async {
    try {
      await _trainingService.deleteTraining(widget.training);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrenamiento eliminado')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  void _confirmDelete() {
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
              Navigator.pop(ctx);
              await _deleteTraining();
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTraining() async {
    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text.trim());

    if (name.isEmpty || editableExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade un nombre y al menos un ejercicio.'),
        ),
      );
      return;
    }

    final updated = Training(
      id: widget.training.id,
      name: name,
      weight: weight,
      date: widget.training.date,
      exercises: editableExercises,
    );

    try {
      await _trainingService.saveTraining(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrenamiento guardado con éxito')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _confirmExit()) {
              if (mounted) Navigator.pop(context);
            }
          },
        ),
        title: const Text('Editar entrenamiento'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ],
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
                    controller: _nameController,
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
                    controller: _weightController,
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
              child: editableExercises.isEmpty
                  ? const Center(child: Text("No hay ejercicios añadidos."))
                  : ListView.builder(
                      itemCount: editableExercises.length,
                      itemBuilder: (context, i) {
                        final ejercicio = editableExercises[i];
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
                                          () => editableExercises.removeAt(i),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: colorScheme.error,
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
                                            initialValue: ejercicio
                                                .series[j]
                                                .weight
                                                .toString(),
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
                                            initialValue: ejercicio
                                                .series[j]
                                                .repetitions
                                                .toString(),
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
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: colorScheme.error,
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
                    onPressed: _saveTraining,
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
