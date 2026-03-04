import 'package:business_ia/models/measurement.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BodyCompositionChart extends StatefulWidget {
  final List<Measurement> measurements;

  const BodyCompositionChart({super.key, required this.measurements});

  @override
  State<BodyCompositionChart> createState() => _BodyCompositionChartState();
}

class _BodyCompositionChartState extends State<BodyCompositionChart> {
  String _selectedMetric = 'Peso';

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No hay datos suficientes para la gráfica")),
      );
    }

    // Sort measurements by date
    final sortedMeasurements = List<Measurement>.from(widget.measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Prepare spots
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < sortedMeasurements.length; i++) {
      final m = sortedMeasurements[i];
      double value = 0.0;
      switch (_selectedMetric) {
        case 'Peso':
          value = m.weight;
          break;
        case 'Grasa':
          value = m.fat;
          break;
        case 'Músculo':
          value = m.muscle;
          break;
      }

      spots.add(FlSpot(i.toDouble(), value));

      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Add some padding to Y axis
    if (minY == maxY) {
      minY = (minY - 5).clamp(0.0, double.infinity);
      maxY += 5;
    } else {
      double diff = maxY - minY;
      minY = (minY - (diff * 1.5)).clamp(0.0, double.infinity);
      maxY = maxY + (diff * 1.5);
    }

    // Fallback if still invalid
    if (minY == double.infinity) {
      minY = 0;
      maxY = 10;
    }

    Color lineColor;
    switch (_selectedMetric) {
      case 'Peso':
        lineColor = Colors.blue;
        break;
      case 'Grasa':
        lineColor = Colors.red;
        break;
      case 'Músculo':
        lineColor = Colors.green;
        break;
      default:
        lineColor = Colors.blue;
    }

    return Column(
      children: [
        // Selector
        Wrap(
          spacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Peso (kg)'),
              selected: _selectedMetric == 'Peso',
              selectedColor: Colors.blue.withOpacity(0.2),
              onSelected: (selected) {
                if (selected) setState(() => _selectedMetric = 'Peso');
              },
            ),
            ChoiceChip(
              label: const Text('Grasa (%)'),
              selected: _selectedMetric == 'Grasa',
              selectedColor: Colors.red.withOpacity(0.2),
              onSelected: (selected) {
                if (selected) setState(() => _selectedMetric = 'Grasa');
              },
            ),
            ChoiceChip(
              label: const Text('Músculo (kg)'),
              selected: _selectedMetric == 'Músculo',
              selectedColor: Colors.green.withOpacity(0.2),
              onSelected: (selected) {
                if (selected) setState(() => _selectedMetric = 'Músculo');
              },
            ),
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
                      interval: (sortedMeasurements.length / 4)
                          .ceilToDouble()
                          .clamp(1.0, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < sortedMeasurements.length &&
                            value == index.toDouble()) {
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
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
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
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '$_selectedMetric: ${spot.y.toStringAsFixed(1)}',
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
