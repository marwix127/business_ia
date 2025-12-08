import 'package:business_ia/models/selected_exercise.dart';
import 'package:business_ia/models/serie.dart';
import 'package:business_ia/UI/widgets/series_row.dart';
import 'package:flutter/material.dart';

/// Widget para mostrar una tarjeta de ejercicio con sus series.
class ExerciseCard extends StatelessWidget {
  final SelectedExercise exercise;
  final List<Series>? hints;
  final bool isEditing;
  final VoidCallback onDelete;
  final VoidCallback onAddSeries;
  final Function(int seriesIndex, String field, String value) onUpdateSeries;
  final Function(int seriesIndex) onRemoveSeries;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.hints,
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
            // Headers for columns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Peso (kg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Reps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Space for delete button
                ],
              ),
            ),
            const SizedBox(height: 4),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.series.length,
              itemBuilder: (context, j) {
                final hint = (hints != null && j < hints!.length)
                    ? hints![j]
                    : null;
                return SeriesRow(
                  series: exercise.series[j],
                  hintWeight: hint?.weight,
                  hintReps: hint?.repetitions,
                  isEditing: isEditing,
                  onWeightChanged: (value) =>
                      onUpdateSeries(j, 'weight', value),
                  onRepsChanged: (value) => onUpdateSeries(j, 'reps', value),
                  onRemove: () => onRemoveSeries(j),
                );
              },
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
