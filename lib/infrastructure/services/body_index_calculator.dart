import 'package:stronger/models/measurement.dart';

/// Un punto de la serie del índice de composición corporal.
class BodyIndexPoint {
  final DateTime date;
  final double ratio;

  const BodyIndexPoint({required this.date, required this.ratio});
}

/// Índice de composición corporal: ratio músculo/grasa (*muscle-to-fat ratio*).
///
/// `índice = masa muscular (kg) / masa grasa (kg)`, con
/// `masa grasa = peso (kg) × % grasa / 100`.
///
/// Resume la condición física en un único número que **sube siempre que la
/// composición mejora**, sea cual sea la fase:
///  - en volumen sube si ganas más músculo que grasa,
///  - en definición sube si pierdes más grasa que músculo.
///
/// Por eso basta con mirar si la línea sube: no hace falta comparar a mano las
/// dos métricas por separado.
abstract final class BodyIndexCalculator {
  /// Masa grasa en kg, o `null` si la medición no trae peso y % de grasa.
  static double? fatMass(Measurement measurement) {
    if (measurement.weight <= 0 || measurement.fat <= 0) return null;
    final mass = measurement.weight * measurement.fat / 100;
    return mass.isFinite ? mass : null;
  }

  /// Ratio músculo/grasa, o `null` si faltan datos para calcularlo.
  static double? ratio(Measurement measurement) {
    final fat = fatMass(measurement);
    if (fat == null || fat <= 0 || measurement.muscle <= 0) return null;
    final value = measurement.muscle / fat;
    return value.isFinite ? value : null;
  }

  /// Serie ordenada por fecha, saltando las mediciones incompletas.
  static List<BodyIndexPoint> series(List<Measurement> measurements) {
    final points = <BodyIndexPoint>[];
    for (final measurement in measurements) {
      final value = ratio(measurement);
      if (value == null) continue;
      points.add(BodyIndexPoint(date: measurement.date, ratio: value));
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}
