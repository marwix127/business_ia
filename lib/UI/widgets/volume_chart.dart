import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VolumenChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const VolumenChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    data.sort((a, b) => a['date'].compareTo(b['date']));

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index]['date'] as DateTime;
                  return Text(
                    "${date.day}/${date.month}",
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), (data[i]['volumen'] as double)),
            ],
            isCurved: true,
            barWidth: 3,
            color: colorScheme.primary,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
