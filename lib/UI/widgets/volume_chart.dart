import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VolumenChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const VolumenChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Sort data by date
    final sortedData = List<Map<String, dynamic>>.from(data);
    sortedData.sort((a, b) => a['date'].compareTo(b['date']));

    if (sortedData.isEmpty) {
      return const Center(child: Text("No hay datos suficientes"));
    }

    // Calculate Min/Max for Y-Axis padding
    double maxY = 0;
    double minY = double.infinity;
    for (var item in sortedData) {
      final val = (item['volumen'] as num).toDouble();
      if (val > maxY) maxY = val;
      if (val < minY) minY = val;
    }

    // Add 10% padding
    final range = maxY - minY;
    final padding = range == 0 ? 10.0 : range * 0.2;
    final effectiveMaxY = maxY + padding;
    final effectiveMinY = (minY - padding) < 0 ? 0.0 : (minY - padding);

    // Calculate X-Axis interval to show max ~5 dates
    final xInterval = (sortedData.length / 5).ceil().toDouble();

    return LineChart(
      LineChartData(
        minY: effectiveMinY,
        maxY: effectiveMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 5 : range / 5, // Approx 5 lines
          getDrawingHorizontalLine: (value) {
            return FlLine(color: colorScheme.outlineVariant, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedData.length) {
                  final date = sortedData[index]['date'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "${date.day}/${date.month}",
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              // Dynamic interval to prevent repeating labels
              interval: range == 0 ? 5 : range / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < sortedData.length; i++)
                FlSpot(
                  i.toDouble(),
                  (sortedData[i]['volumen'] as num).toDouble(),
                ),
            ],
            isCurved: true,
            preventCurveOverShooting: true, // Fixes curve going out of bounds
            barWidth: 3,
            color: colorScheme.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < sortedData.length) {
                  final date = sortedData[index]['date'] as DateTime;
                  return LineTooltipItem(
                    "${date.day}/${date.month}\n${spot.y.toStringAsFixed(1)} kg",
                    TextStyle(color: colorScheme.onPrimary),
                  );
                }
                return null;
              }).toList();
            },
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            // tooltipBgColor: colorScheme.primary, // Deprecated in some versions, check theme
          ),
        ),
      ),
    );
  }
}
