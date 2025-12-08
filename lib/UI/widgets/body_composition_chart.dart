import 'package:business_ia/models/measurement.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BodyCompositionChart extends StatelessWidget {
  final List<Measurement> measurements;

  const BodyCompositionChart({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No hay datos suficientes para la gráfica")),
      );
    }

    // Sort measurements by date
    final sortedMeasurements = List<Measurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Prepare spots
    final weightSpots = <FlSpot>[];
    final fatSpots = <FlSpot>[];
    final muscleSpots = <FlSpot>[];

    for (int i = 0; i < sortedMeasurements.length; i++) {
      final m = sortedMeasurements[i];
      weightSpots.add(FlSpot(i.toDouble(), m.weight));
      fatSpots.add(FlSpot(i.toDouble(), m.fat));
      muscleSpots.add(FlSpot(i.toDouble(), m.muscle));
    }

    // Calculate min and max Y for better scaling
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var m in sortedMeasurements) {
      if (m.weight < minY) minY = m.weight;
      if (m.fat < minY) minY = m.fat;
      if (m.muscle < minY) minY = m.muscle;

      if (m.weight > maxY) maxY = m.weight;
      if (m.fat > maxY) maxY = m.fat;
      if (m.muscle > maxY) maxY = m.muscle;
    }

    // Add some padding to Y axis
    minY = (minY - 5).clamp(0, double.infinity);
    maxY += 5;

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: Colors.blue, text: "Peso (kg)"),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.red, text: "Grasa (%)"),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.green, text: "Músculo (kg)"),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedMeasurements.length) {
                          // Show date for every few items to avoid clutter if many items
                          // For now, show all or let fl_chart handle overlap if possible,
                          // but simple logic: show first, last, and some in between?
                          // Let's just show Day/Month
                          final date = sortedMeasurements[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Weight Line
                  LineChartBarData(
                    spots: weightSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Fat Line
                  LineChartBarData(
                    spots: fatSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Muscle Line
                  LineChartBarData(
                    spots: muscleSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        if (spot.barIndex == 0) label = 'Peso';
                        if (spot.barIndex == 1) label = 'Grasa';
                        if (spot.barIndex == 2) label = 'Músculo';
                        return LineTooltipItem(
                          '$label: ${spot.y}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
