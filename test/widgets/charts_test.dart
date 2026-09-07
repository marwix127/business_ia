import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/UI/widgets/average_weight.dart';
import 'package:stronger/UI/widgets/body_composition_chart.dart';
import 'package:stronger/UI/widgets/volume_chart.dart';
import 'package:stronger/models/measurement.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 600, height: 500, child: child)),
  );

  testWidgets('volume and average charts expose a clear empty state', (
    tester,
  ) async {
    await tester.pumpWidget(host(const VolumenChart(data: [])));
    expect(find.text('No hay datos suficientes'), findsOneWidget);

    await tester.pumpWidget(host(const AverageWeightChart(data: [])));
    expect(find.text('No hay datos suficientes'), findsOneWidget);
  });

  testWidgets('volume chart sorts data and creates one spot per value', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        VolumenChart(
          data: [
            {'date': DateTime(2026, 1, 2), 'volume': 200.0},
            {'date': DateTime(2026, 1, 1), 'volume': 100.0},
          ],
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.map((spot) => spot.y), [
      100,
      200,
    ]);
  });

  testWidgets('body composition switches values and colors by metric', (
    tester,
  ) async {
    final measurements = [
      Measurement(
        weight: 80,
        fat: 20,
        muscle: 60,
        date: DateTime(2026, 1, 1),
      ),
    ];
    await tester.pumpWidget(
      host(BodyCompositionChart(measurements: measurements)),
    );

    LineChart chart() => tester.widget<LineChart>(find.byType(LineChart));
    expect(chart().data.lineBarsData.single.spots.single.y, 80);
    expect(chart().data.lineBarsData.single.color, Colors.blue);

    await tester.tap(find.text('Grasa (%)'));
    await tester.pump();
    expect(chart().data.lineBarsData.single.spots.single.y, 20);
    expect(chart().data.lineBarsData.single.color, Colors.red);

    await tester.tap(find.text('Músculo (kg)'));
    await tester.pump();
    expect(chart().data.lineBarsData.single.spots.single.y, 60);
    expect(chart().data.lineBarsData.single.color, Colors.green);
  });

  testWidgets('body composition plots the muscle/fat index', (tester) async {
    Widget tallHost(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 600, height: 900, child: child)),
    );

    await tester.pumpWidget(
      tallHost(
        BodyCompositionChart(
          measurements: [
            Measurement(
              weight: 80,
              fat: 20,
              muscle: 60,
              date: DateTime(2026, 1, 1),
            ),
            // Sin grasa registrada: se queda fuera de la serie del índice.
            Measurement(
              weight: 81,
              fat: 0,
              muscle: 61,
              date: DateTime(2026, 1, 8),
            ),
            Measurement(
              weight: 82,
              fat: 19,
              muscle: 63,
              date: DateTime(2026, 1, 15),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Índice M/G'));
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final values = chart.data.lineBarsData.single.spots.map((spot) => spot.y);
    expect(values.length, 2);
    expect(values.first, closeTo(3.75, 0.0001));
    expect(values.last, closeTo(63 / (82 * 0.19), 0.0001));

    // Resumen: valor actual y mejora respecto a la medición anterior.
    expect(find.text('4.04'), findsOneWidget);
    expect(find.text('+0.29'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });

  testWidgets('index summary separates the last change from the total', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 900,
            child: BodyCompositionChart(
              measurements: [
                Measurement(
                  weight: 80,
                  fat: 20,
                  muscle: 60,
                  date: DateTime(2026, 1, 1),
                ),
                Measurement(
                  weight: 82,
                  fat: 19,
                  muscle: 63,
                  date: DateTime(2026, 1, 8),
                ),
                Measurement(
                  weight: 83,
                  fat: 20,
                  muscle: 64,
                  date: DateTime(2026, 1, 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Índice M/G'));
    await tester.pumpAndSettle();

    // Ha empeorado respecto a la anterior, pero sigue por encima del inicio.
    expect(find.text('3.86'), findsOneWidget);
    expect(find.text('-0.19'), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
    expect(find.text('+0.11'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });

  testWidgets('index asks for the missing data instead of drawing a line', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        BodyCompositionChart(
          measurements: [
            Measurement(
              weight: 80,
              fat: 0,
              muscle: 60,
              date: DateTime(2026, 1, 1),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Índice M/G'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNothing);
    expect(
      find.text(
        'Registra peso, % de grasa y músculo en una misma medición para ver '
        'tu índice.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the last date label stays inside the chart bounds', (
    tester,
  ) async {
    // 5 mediciones -> intervalo 2 -> se etiquetan los indices 0, 2 y 4, asi
    // que el ultimo punto (el pegado al borde derecho) lleva fecha.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 500,
            child: BodyCompositionChart(
              measurements: [
                for (var day = 1; day <= 5; day++)
                  Measurement(
                    weight: 80.0 + day,
                    fat: 20,
                    muscle: 60,
                    date: DateTime(2026, 1, day),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.getRect(find.byType(LineChart));
    final lastLabel = tester.getRect(find.text('05/01'));

    expect(
      lastLabel.right,
      lessThanOrEqualTo(chart.right),
      reason: 'la fecha del ultimo punto se sale por la derecha y se corta',
    );
  });

  testWidgets('the touch tooltip is kept inside the chart', (tester) async {
    await tester.pumpWidget(
      host(
        BodyCompositionChart(
          measurements: [
            for (var day = 1; day <= 5; day++)
              Measurement(
                weight: 80.0 + day,
                fat: 20,
                muscle: 60,
                date: DateTime(2026, 1, day),
              ),
          ],
        ),
      ),
    );

    // Sin esto el tooltip de los últimos puntos se sale de la pantalla.
    final tooltip = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineTouchData
        .touchTooltipData;
    expect(tooltip.fitInsideHorizontally, isTrue);
    expect(tooltip.fitInsideVertically, isTrue);
  });
}
