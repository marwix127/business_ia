import 'dart:convert';

class MuscleFatigueCalculator {
  static const recoveryHours = 72.0;
  static const fullRecoveryDuration = Duration(hours: 72);
  static const allowedMuscles = <String>[
    'chest',
    'frontShoulders',
    'biceps',
    'forearms',
    'abs',
    'quads',
    'calves',
    'traps',
    'lats',
    'rearShoulders',
    'triceps',
    'lowerBack',
    'glutes',
    'hamstrings',
  ];

  static Map<String, double> parseScores(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end < start) {
      return {};
    }

    try {
      final decoded = jsonDecode(cleaned.substring(start, end + 1));
      if (decoded is! Map) {
        return {};
      }

      final scores = <String, double>{};
      for (final entry in decoded.entries) {
        if (!allowedMuscles.contains(entry.key) || entry.value is! num) {
          continue;
        }
        final value = (entry.value as num).toDouble();
        if (!value.isFinite) {
          continue;
        }
        scores[entry.key as String] = value.clamp(0, 100).toDouble();
      }
      return scores;
    } catch (_) {
      return {};
    }
  }

  static double applyDecay(double score, DateTime updatedAt, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final hours = currentTime.difference(updatedAt).inMinutes / 60.0;
    final factor = (1 - hours / recoveryHours).clamp(0.0, 1.0);
    return score * factor;
  }
}
