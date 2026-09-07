import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/body_index_calculator.dart';
import 'package:stronger/models/measurement.dart';

Measurement measurement({
  required double weight,
  required double fat,
  required double muscle,
  DateTime? date,
}) => Measurement(
  weight: weight,
  fat: fat,
  muscle: muscle,
  date: date ?? DateTime(2026, 1, 1),
);

void main() {
  test('ratio divides muscle mass by fat mass', () {
    final value = BodyIndexCalculator.ratio(
      measurement(weight: 80, fat: 20, muscle: 60),
    );

    // 60 kg de músculo / 16 kg de grasa (20% de 80).
    expect(value, closeTo(3.75, 0.0001));
  });

  test('ratio is null when the measurement lacks fat or muscle', () {
    expect(
      BodyIndexCalculator.ratio(measurement(weight: 80, fat: 0, muscle: 60)),
      isNull,
    );
    expect(
      BodyIndexCalculator.ratio(measurement(weight: 80, fat: 20, muscle: 0)),
      isNull,
    );
    expect(
      BodyIndexCalculator.ratio(measurement(weight: 0, fat: 20, muscle: 60)),
      isNull,
    );
  });

  test('index rises when the bulk improves the muscle/fat proportion', () {
    final before = BodyIndexCalculator.ratio(
      measurement(weight: 80, fat: 20, muscle: 60),
    )!;
    // +3 kg de músculo y solo +0.38 kg de grasa: el % de grasa baja.
    final after = BodyIndexCalculator.ratio(
      measurement(weight: 84, fat: 19.5, muscle: 63),
    )!;

    expect(after, greaterThan(before));
  });

  test('index falls when fat grows proportionally faster than muscle', () {
    final before = BodyIndexCalculator.ratio(
      measurement(weight: 80, fat: 20, muscle: 60),
    )!;
    // +3 kg de músculo frente a +1.22 kg de grasa parece buen reparto, pero el
    // índice es una proporción: con 3.75 de partida hacen falta 3.75 kg de
    // músculo por cada kg de grasa solo para no perder terreno.
    final after = BodyIndexCalculator.ratio(
      measurement(weight: 84, fat: 20.5, muscle: 63),
    )!;

    expect(after, lessThan(before));
  });

  test('index falls when the bulk adds more fat than muscle', () {
    final before = BodyIndexCalculator.ratio(
      measurement(weight: 80, fat: 20, muscle: 60),
    )!;
    final after = BodyIndexCalculator.ratio(
      measurement(weight: 84, fat: 23, muscle: 61),
    )!;

    expect(after, lessThan(before));
  });

  test('index rises when the cut loses more fat than muscle', () {
    final before = BodyIndexCalculator.ratio(
      measurement(weight: 80, fat: 20, muscle: 60),
    )!;
    final after = BodyIndexCalculator.ratio(
      measurement(weight: 76, fat: 17, muscle: 59),
    )!;

    expect(after, greaterThan(before));
  });

  test('series sorts by date and skips incomplete measurements', () {
    final points = BodyIndexCalculator.series([
      measurement(
        weight: 80,
        fat: 20,
        muscle: 60,
        date: DateTime(2026, 1, 10),
      ),
      measurement(weight: 82, fat: 0, muscle: 61, date: DateTime(2026, 1, 5)),
      measurement(weight: 78, fat: 26, muscle: 58, date: DateTime(2026, 1, 1)),
    ]);

    expect(points.map((p) => p.date), [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 10),
    ]);
    expect(points.last.ratio, closeTo(3.75, 0.0001));
  });
}
