import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:business_ia/models/selected_exercise.dart';
import 'package:business_ia/models/serie.dart';
import 'package:business_ia/models/training.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'exercises_categories.dart';

class TrainingPage extends StatefulWidget {
  final Training? training;

  const TrainingPage({super.key, this.training});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  List<SelectedExercise> exercises = [];
  final TrainingService _trainingService = TrainingService();

  bool get _isEditing => widget.training != null;

  // Mantener la página viva mientras haya cambios sin guardar
  @override
  bool get wantKeepAlive => _hasUnsavedChanges;

  bool get _hasUnsavedChanges {
    if (_isEditing) {
      return _nombreController.text != widget.training!.name ||
          _pesoController.text != (widget.training!.weight?.toString() ?? '') ||
          _exercisesChanged();
    }
    return _nombreController.text.isNotEmpty ||
        _pesoController.text.isNotEmpty ||
        exercises.isNotEmpty;
  }

  bool _exercisesChanged() {
    if (exercises.length != widget.training!.exercises.length) return true;

    for (var i = 0; i < exercises.length; i++) {
      if (_exerciseChanged(exercises[i], widget.training!.exercises[i])) {
        return true;
      }
    }
    return false;
  }

  bool _exerciseChanged(SelectedExercise edited, SelectedExercise original) {
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
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeExercises();
  }

  void _initializeControllers() {
    // Ya están creados; solo establecer texto si estamos en edición
    if (_isEditing) {
      _nombreController.text = widget.training!.name;
      _pesoController.text = widget.training!.weight != null
          ? widget.training!.weight.toString()
          : '';
    }
  }

  void _initializeExercises() {
    exercises = _isEditing
        ? widget.training!.exercises
              .map(
                (e) => SelectedExercise(
                  id: e.id,
                  name: e.name,
                  category: e.category,
                  series: e.series
                      .map(
                        (s) => Series(
                          repetitions: s.repetitions,
                          weight: s.weight,
                        ),
                      )
                      .toList(),
                ),
              )
              .toList()
        : [];
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
    // AutomaticKeepAliveClientMixin mantiene la página viva,
    // así que ya no necesitamos guardar borradores manualmente
    super.updateKeepAlive();
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _addExercise(Map<String, dynamic> ejercicio) {
    if (exercises.any((e) => e.id == ejercicio['id'])) return;

    setState(() {
      exercises.add(
        SelectedExercise(
          id: ejercicio['id'],
          name: ejercicio['nombre'],
          category: ejercicio['categoria'],
        ),
      );
    });
  }

  Future<void> _startExerciseSelection() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExercisesCategories()),
    );

    if (selected != null && selected is Map<String, dynamic>) {
      _addExercise(selected);
    }
  }

  void _updateSeries(
    int exerciseIndex,
    int seriesIndex,
    String field,
    String value,
  ) {
    setState(() {
      final serie = exercises[exerciseIndex].series[seriesIndex];
      if (field == 'weight') {
        serie.weight = double.tryParse(value) ?? 0;
      } else {
        serie.repetitions = int.tryParse(value) ?? 0;
      }
    });
  }

  Future<void> _deleteTraining() async {
    try {
      await _trainingService.deleteTraining(widget.training!);
      _showSnackBar('Entrenamiento eliminado');
      if (mounted) context.pop(true);
    } catch (e) {
      _showSnackBar('Error al eliminar: $e', isError: true);
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
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTraining();
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
    final name = _nombreController.text.trim();
    final weight = double.tryParse(_pesoController.text.trim());

    if (name.isEmpty || exercises.isEmpty) {
      _showSnackBar('Añade un nombre y al menos un ejercicio.');
      return;
    }

    final training = Training(
      id: _isEditing ? widget.training!.id : '',
      name: name,
      weight: weight,
      date: _isEditing ? widget.training!.date : DateTime.now(),
      exercises: exercises,
    );

    try {
      await _trainingService.saveTraining(training);
      _showSnackBar('Entrenamiento guardado con éxito');
      if (mounted) context.pop(true);
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← Necesario para AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _confirmExit() && mounted) {
              context.pop();
            }
          },
        ),
        title: Text(_isEditing ? 'Editar entrenamiento' : 'Entrenamiento'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInputs(),
            const SizedBox(height: 16),
            Expanded(
              child: exercises.isEmpty
                  ? const Center(child: Text("No hay ejercicios añadidos."))
                  : _buildExercisesList(),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInputs() {
    return Row(
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
    );
  }

  Widget _buildExercisesList() {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, i) => _ExerciseCard(
        exercise: exercises[i],
        isEditing: _isEditing,
        onDelete: () => setState(() => exercises.removeAt(i)),
        onUpdateSeries: (seriesIndex, field, value) =>
            _updateSeries(i, seriesIndex, field, value),
        onAddSeries: () => setState(() {
          exercises[i].series.add(Series(repetitions: 0, weight: 0));
        }),
        onRemoveSeries: (seriesIndex) => setState(() {
          exercises[i].series.removeAt(seriesIndex);
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startExerciseSelection,
            icon: const Icon(Icons.add),
            label: const Text('Agregar ejercicio'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saveTraining,
            icon: const Icon(Icons.save),
            label: const Text("Guardar"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 50)),
          ),
        ),
      ],
    );
  }
}

// Widget extraído para ejercicios
class _ExerciseCard extends StatelessWidget {
  final SelectedExercise exercise;
  final bool isEditing;
  final VoidCallback onDelete;
  final VoidCallback onAddSeries;
  final Function(int seriesIndex, String field, String value) onUpdateSeries;
  final Function(int seriesIndex) onRemoveSeries;

  const _ExerciseCard({
    required this.exercise,
    required this.isEditing,
    required this.onDelete,
    required this.onAddSeries,
    required this.onUpdateSeries,
    required this.onRemoveSeries,
  });

  @override
  Widget build(BuildContext context) {
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
                    exercise.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.series.length,
              itemBuilder: (context, j) => _SeriesRow(
                series: exercise.series[j],
                isEditing: isEditing,
                onWeightChanged: (value) => onUpdateSeries(j, 'weight', value),
                onRepsChanged: (value) => onUpdateSeries(j, 'reps', value),
                onRemove: () => onRemoveSeries(j),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddSeries,
              icon: const Icon(Icons.add),
              label: const Text('Añadir serie'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget extraído para filas de series
class _SeriesRow extends StatelessWidget {
  final Series series;
  final bool isEditing;
  final Function(String) onWeightChanged;
  final Function(String) onRepsChanged;
  final VoidCallback onRemove;

  const _SeriesRow({
    required this.series,
    required this.isEditing,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: series.weight != 0
                  ? series.weight.toString()
                  : null,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'Ej: 20',
              ),
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: series.repetitions != 0
                  ? series.repetitions.toString()
                  : null,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                hintText: 'Ej: 10',
              ),
              onChanged: onRepsChanged,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
