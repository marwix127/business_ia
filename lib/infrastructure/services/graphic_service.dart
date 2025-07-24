import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VolumenChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const VolumenChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No hay datos para este ejercicio"));
    }

    data.sort((a, b) => a['date'].compareTo(b['date']));

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final fecha = data[index]['date'] as DateTime;
                    return Text("${fecha.day}/${fecha.month}");
                  }
                  return const Text("");
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), (data[i]['volumen'] as double)),
              ],
              isCurved: true,
              dotData: FlDotData(show: true),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
