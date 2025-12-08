import 'package:business_ia/models/serie.dart';
import 'package:flutter/material.dart';

/// Widget para mostrar una fila de serie con peso y repeticiones.
class SeriesRow extends StatelessWidget {
  final Series series;
  final double? hintWeight;
  final int? hintReps;
  final bool isEditing;
  final Function(String) onWeightChanged;
  final Function(String) onRepsChanged;
  final VoidCallback onRemove;

  const SeriesRow({
    super.key,
    required this.series,
    this.hintWeight,
    this.hintReps,
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
              decoration: InputDecoration(
                labelText: hintWeight != null ? '$hintWeight' : 'Peso (kg)',
                hintText: hintWeight != null ? '$hintWeight' : '0',
                floatingLabelBehavior: FloatingLabelBehavior.never,
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
              decoration: InputDecoration(
                labelText: hintReps != null ? '$hintReps' : 'Reps',
                hintText: hintReps != null ? '$hintReps' : '0',
                floatingLabelBehavior: FloatingLabelBehavior.never,
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
