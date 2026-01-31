import 'dart:convert';

import 'package:business_ia/infrastructure/services/firebase/training_service.dart';
import 'package:business_ia/models/selected_exercise.dart';
import 'package:business_ia/models/serie.dart';
import 'package:business_ia/models/training.dart';
import 'package:business_ia/UI/widgets/exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercises_categories.dart';

class TrainingPage extends StatefulWidget {
  final Training? training;
  final bool loadDraft;

  const TrainingPage({super.key, this.training, this.loadDraft = false});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final TextEditingController _nombreController = TextEditingController();
  List<SelectedExercise> exercises = [];
  final TrainingService _trainingService = TrainingService();
  final Map<String, List<Series>> _exerciseHints = {};
  static const String _draftKey = 'training_draft';

  bool get _isEditing => widget.training != null;

  // Mantener la página viva mientras haya cambios sin guardar
  @override
  bool get wantKeepAlive => _hasUnsavedChanges;

  bool get _hasUnsavedChanges {
    if (_isEditing) {
      return _nombreController.text != widget.training!.name ||
          _exercisesChanged();
    }
    return _nombreController.text.isNotEmpty || exercises.isNotEmpty;
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

  double? _parseDecimal(String value) {
    // Reemplazar coma por punto para permitir ambos formatos
    final normalizedValue = value.trim().replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeExercises();
    // Cargar borrador solo si se solicita explícitamente y no estamos editando
    if (!_isEditing && widget.loadDraft) {
      _loadDraft();
    }
  }

  void _initializeControllers() {
    // Ya están creados; solo establecer texto si estamos en edición
    if (_isEditing) {
      _nombreController.text = widget.training!.name;
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

    // Load hints for all exercises
    for (var exercise in exercises) {
      _loadHints(exercise.id);
    }
  }

  Future<void> _loadHints(String exerciseId) async {
    if (_exerciseHints.containsKey(exerciseId)) return;

    try {
      final lastSeries = await _trainingService.getLastSeriesForExercise(
        exerciseId,
      );
      if (lastSeries != null && mounted) {
        setState(() {
          _exerciseHints[exerciseId] = lastSeries;
        });
      } else {
        // Optional: Log that no history was found
        print('No history found for exercise $exerciseId');
      }
    } catch (e) {
      print('Error loading hints for $exerciseId: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nombreController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.updateKeepAlive();
    // Guardar borrador cuando la app pasa a segundo plano
    if (state == AppLifecycleState.paused &&
        !_isEditing &&
        _hasUnsavedChanges) {
      _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'name': _nombreController.text,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
      await prefs.setString(_draftKey, jsonEncode(draft));
    } catch (_) {
      // Ignorar errores de guardado
    }
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null) return;

      final draft = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;

      setState(() {
        _nombreController.text = draft['name'] ?? '';
        exercises = (draft['exercises'] as List<dynamic>)
            .map((e) => SelectedExercise.fromMap(e as Map<String, dynamic>))
            .toList();
      });
      // Cargar hints para ejercicios restaurados
      for (var exercise in exercises) {
        _loadHints(exercise.id);
      }
    } catch (_) {
      // Ignorar errores de carga
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {
      // Ignorar errores
    }
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
    _loadHints(ejercicio['id']);
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
        serie.weight = _parseDecimal(value) ?? 0;
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

    if (name.isEmpty || exercises.isEmpty) {
      _showSnackBar('Añade un nombre y al menos un ejercicio.');
      return;
    }

    final training = Training(
      id: _isEditing ? widget.training!.id : '',
      name: name,
      weight: null,
      date: _isEditing ? widget.training!.date : DateTime.now(),
      exercises: exercises,
    );

    try {
      await _trainingService.saveTraining(training);
      await _clearDraft(); // Limpiar borrador después de guardar
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
    return TextField(
      controller: _nombreController,
      decoration: const InputDecoration(
        labelText: 'Nombre del entrenamiento',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildExercisesList() {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, i) => ExerciseCard(
        exercise: exercises[i],
        hints: _exerciseHints[exercises[i].id],
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
