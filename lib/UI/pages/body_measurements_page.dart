import 'package:business_ia/UI/widgets/body_composition_chart.dart';
import 'package:business_ia/infrastructure/services/firebase/corporal_service.dart';
import 'package:business_ia/models/measurement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BodyMeasurementsPage extends StatefulWidget {
  const BodyMeasurementsPage({super.key});

  @override
  State<BodyMeasurementsPage> createState() => _BodyMeasurementsPageState();
}

class _BodyMeasurementsPageState extends State<BodyMeasurementsPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _fatController = TextEditingController();
  final _muscleController = TextEditingController();
  final CorporalService _corporalService = CorporalService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastHeight();
  }

  Future<void> _loadLastHeight() async {
    final lastMeasurement = await _corporalService.getLastMeasurement();
    if (lastMeasurement != null && lastMeasurement['height'] != null) {
      if (mounted) {
        setState(() {
          _heightController.text = lastMeasurement['height'].toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _fatController.dispose();
    _muscleController.dispose();
    super.dispose();
  }

  double? parseMeasurement(String value) {
    final normalizedValue = value.trim().replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _corporalService.addMeasurement({
        'weight': parseMeasurement(_weightController.text),
        'height': parseMeasurement(_heightController.text),
        'fat_percentage': parseMeasurement(_fatController.text),
        'muscle_mass': parseMeasurement(_muscleController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medición guardada correctamente')),
        );
        _weightController.clear();
        _heightController.clear();
        _fatController.clear();
        _muscleController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Datos Corporales')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nueva Medición',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Peso (kg)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monitor_weight),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: 'Altura (cm)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.height),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fatController,
                              decoration: const InputDecoration(
                                labelText: '% Grasa',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.opacity),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _muscleController,
                              decoration: const InputDecoration(
                                labelText: 'Músculo (kg)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.fitness_center),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _saveMeasurement,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Historial',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: _corporalService.getMeasurements(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar datos'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No hay mediciones registradas'),
                        ),
                      );
                    }

                    final measurements = docs.map((doc) {
                      return Measurement.fromMap(
                        doc.data() as Map<String, dynamic>,
                      );
                    }).toList();

                    return Column(
                      children: [
                        BodyCompositionChart(measurements: measurements),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final date =
                                (data['date'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                            final formattedDate = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(date);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                          ),
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _MeasurementItem(
                                          label: 'Peso',
                                          value: '${data['weight'] ?? '-'} kg',
                                          icon: Icons.monitor_weight,
                                        ),
                                        if (data['fat_percentage'] != null)
                                          _MeasurementItem(
                                            label: 'Grasa',
                                            value: '${data['fat_percentage']}%',
                                            icon: Icons.opacity,
                                          ),
                                        if (data['muscle_mass'] != null)
                                          _MeasurementItem(
                                            label: 'Músculo',
                                            value: '${data['muscle_mass']} kg',
                                            icon: Icons.fitness_center,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MeasurementItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
