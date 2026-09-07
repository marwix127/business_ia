import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stronger/infrastructure/services/body_index_calculator.dart';
import 'package:stronger/models/measurement.dart';
import 'package:stronger/theme/app_colors.dart';

class BodyCompositionChart extends StatefulWidget {
  final List<Measurement> measurements;

  const BodyCompositionChart({super.key, required this.measurements});

  @override
  State<BodyCompositionChart> createState() => _BodyCompositionChartState();
}

/// Punto (fecha, valor) de la métrica que se está dibujando.
class _ChartPoint {
  final DateTime date;
  final double value;

  const _ChartPoint(this.date, this.value);
}

class _BodyCompositionChartState extends State<BodyCompositionChart> {
  static const _metricNames = {
    'Weight': 'Peso',
    'Fat': 'Grasa',
    'Muscle': 'Músculo',
    'Index': 'Índice M/G',
  };

  String _selectedMetric = 'Weight';

  bool get _isIndex => _selectedMetric == 'Index';

  int get _decimals => _isIndex ? 2 : 1;

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

    // El índice solo existe en las mediciones que traen peso, % grasa y
    // músculo, así que su serie puede ser más corta que el historial.
    final points = _isIndex
        ? [
            for (final point in BodyIndexCalculator.series(sortedMeasurements))
              _ChartPoint(point.date, point.ratio),
          ]
        : [
            for (final measurement in sortedMeasurements)
              _ChartPoint(measurement.date, _rawValue(measurement)),
          ];

    return Column(
      children: [
        _selector(),
        const SizedBox(height: 16),
        if (_isIndex && points.isNotEmpty) ...[
          _indexSummary(points),
          const SizedBox(height: 12),
        ],
        if (points.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Registra peso, % de grasa y músculo en una misma medición '
                  'para ver tu índice.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: _chart(points),
            ),
          ),
      ],
    );
  }

  // ── Métricas ───────────────────────────────────────────────────────────────

  double _rawValue(Measurement measurement) {
    switch (_selectedMetric) {
      case 'Fat':
        return measurement.fat;
      case 'Muscle':
        return measurement.muscle;
      default:
        return measurement.weight;
    }
  }

  Color _indexColor() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFCE93D8)
      : const Color(0xFF7B1FA2);

  Color _lineColor() {
    switch (_selectedMetric) {
      case 'Fat':
        return Colors.red;
      case 'Muscle':
        return Colors.green;
      case 'Index':
        return _indexColor();
      default:
        return Colors.blue;
    }
  }

  // ── Selector ───────────────────────────────────────────────────────────────

  Widget _selector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        _chip('Peso (kg)', 'Weight', Colors.blue),
        _chip('Grasa (%)', 'Fat', Colors.red),
        _chip('Músculo (kg)', 'Muscle', Colors.green),
        _chip('Índice M/G', 'Index', _indexColor()),
      ],
    );
  }

  Widget _chip(String label, String metric, Color color) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedMetric == metric,
      selectedColor: color.withValues(alpha: 0.2),
      onSelected: (selected) {
        if (selected) setState(() => _selectedMetric = metric);
      },
    );
  }

  // ── Resumen del índice ─────────────────────────────────────────────────────

  Widget _indexSummary(List<_ChartPoint> points) {
    final theme = Theme.of(context);
    final current = points.last.value;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Índice músculo/grasa',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        current.toStringAsFixed(2),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _indexColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (points.length > 1)
                      _delta(
                        'vs anterior',
                        current - points[points.length - 2].value,
                      ),
                    if (points.length > 2) ...[
                      const SizedBox(height: 4),
                      _delta('total', current - points.first.value),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Compara músculo y grasa en proporción: si la línea sube, tu '
              'composición mejora, tanto en volumen como en definición.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _delta(String label, double diff) {
    final theme = Theme.of(context);
    // Por debajo de 0.005 la cifra mostrada sería "0.00": lo tratamos como
    // "sin cambios" para no pintar un signo que no se aprecia en el número.
    final change = diff.abs() < 0.005 ? 0.0 : diff;

    final Color color;
    final IconData icon;
    if (change > 0) {
      color = AppColors.of(context).success;
      icon = Icons.trending_up;
    } else if (change < 0) {
      color = theme.colorScheme.error;
      icon = Icons.trending_down;
    } else {
      color = theme.colorScheme.onSurfaceVariant;
      icon = Icons.trending_flat;
    }

    final sign = change > 0 ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$sign${change.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  // ── Gráfica ────────────────────────────────────────────────────────────────

  Widget _chart(List<_ChartPoint> points) {
    // Prepare spots
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < points.length; i++) {
      final value = points[i].value;
      spots.add(FlSpot(i.toDouble(), value));

      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Add some padding to Y axis. El índice se mueve en décimas, así que un
    // margen tan amplio como el de las demás métricas aplastaría la línea justo
    // donde hay que leer la tendencia.
    final padFactor = _isIndex ? 0.25 : 1.5;
    final flatPad = _isIndex ? 0.5 : 5.0;
    if (minY == maxY) {
      minY = (minY - flatPad).clamp(0.0, double.infinity);
      maxY += flatPad;
    } else {
      final diff = maxY - minY;
      minY = (minY - (diff * padFactor)).clamp(0.0, double.infinity);
      maxY = maxY + (diff * padFactor);
    }

    // Fallback if still invalid
    if (minY == double.infinity) {
      minY = 0;
      maxY = 10;
    }

    final lineColor = _lineColor();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
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
              interval: (points.length / 4).ceilToDouble().clamp(
                1.0,
                double.infinity,
              ),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 &&
                    index < points.length &&
                    value == index.toDouble()) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(points[index].date),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                  value.toStringAsFixed(_decimals),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
              color: lineColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_metricNames[_selectedMetric]}: '
                  '${spot.y.toStringAsFixed(_decimals)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
