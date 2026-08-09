import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import 'package:intl/intl.dart';
import 'package:stronger/UI/widgets/body_composition_chart.dart';
import 'package:stronger/infrastructure/services/firebase/corporal_service.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';
import 'package:stronger/models/measurement.dart';

/// Página unificada "Cuerpo" con dos pestañas:
///   0 → Fatiga Muscular (mapa SVG coloreado)
///   1 → Datos Corporales (mediciones + historial)
class BodyPage extends StatelessWidget {
  final BodyMeasurementService? measurementService;
  final MuscleFatigueService? fatigueService;
  final String? Function()? getUid;

  const BodyPage({
    super.key,
    this.measurementService,
    this.fatigueService,
    this.getUid,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.monitor_weight_outlined),
                text: 'Mediciones',
              ),
              Tab(icon: Icon(Icons.accessibility_new), text: 'Fatiga'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BodyDataTab(measurementService: measurementService),
            _MuscleFatigueTab(fatigueService: fatigueService, getUid: getUid),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Fatiga Muscular
// ─────────────────────────────────────────────────────────────────────────────

class _MuscleFatigueTab extends StatefulWidget {
  final MuscleFatigueService? fatigueService;
  final String? Function()? getUid;

  const _MuscleFatigueTab({this.fatigueService, this.getUid});

  @override
  State<_MuscleFatigueTab> createState() => _MuscleFatigueTabState();
}

class _MuscleFatigueTabState extends State<_MuscleFatigueTab>
    with AutomaticKeepAliveClientMixin {
  // Maps Gemini keys → flutter_body_atlas SVG element IDs
  static const Map<String, List<String>> _muscleIds = {
    'chest': ['pectoralis_major_l', 'pectoralis_major_r'],
    'frontShoulders': ['anterior_deltoid_l', 'anterior_deltoid_r'],
    'biceps': [
      'biceps_brachii_caput_longum_l',
      'biceps_brachii_caput_longum_r',
      'biceps_brachii_caput_breve_l',
      'biceps_brachii_caput_breve_r',
    ],
    'forearms': [
      'brachioradialis_l',
      'brachioradialis_r',
      'flexor_carpi_radialis_l',
      'flexor_carpi_radialis_r',
      'flexor_carpi_ulnaris_l',
      'flexor_carpi_ulnaris_r',
      'extensor_carpi_radialis_longus_l',
      'extensor_carpi_radialis_longus_r',
    ],
    'abs': [
      'rectus_abdominis_1',
      'rectus_abdominis_2_l',
      'rectus_abdominis_2_r',
      'rectus_abdominis_3_l',
      'rectus_abdominis_3_r',
      'rectus_abdominis_4_l',
      'rectus_abdominis_4_r',
      'external_oblique_1_l',
      'external_oblique_1_r',
    ],
    'quads': [
      'rectus_femoris_l',
      'rectus_femoris_r',
      'vastus_lateralis_l',
      'vastus_lateralis_r',
      'vastus_medialis_l',
      'vastus_medialis_r',
    ],
    'calves': [
      'gastrocnemius_l',
      'gastrocnemius_r',
      'tibialis_anterior_l',
      'tibialis_anterior_r',
      'fibularis_longus_l',
      'fibularis_longus_r',
    ],
    'traps': [
      'trapezius_upper_l',
      'trapezius_upper_r',
      'trapezius_middle_l',
      'trapezius_middle_r',
      'trapezius_lower_l',
      'trapezius_lower_r',
    ],
    'lats': ['latissimus_dorsi_l', 'latissimus_dorsi_r'],
    'rearShoulders': ['posterior_deltoid_l', 'posterior_deltoid_r'],
    'triceps': [
      'triceps_brachii_caput_laterale_l',
      'triceps_brachii_caput_laterale_r',
      'triceps_brachii_caput_longum_l',
      'triceps_brachii_caput_longum_r',
      'triceps_brachii_caput_mediale_l',
      'triceps_brachii_caput_mediale_r',
    ],
    'glutes': [
      'gluteus_maximus_l',
      'gluteus_maximus_r',
      'gluteus_medius_1_l',
      'gluteus_medius_1_r',
      'gluteus_medius_2_l',
      'gluteus_medius_2_r',
    ],
    'hamstrings': [
      'semimembranosus_1_l',
      'semimembranosus_1_r',
      'semimembranosus_2_l',
      'semimembranosus_2_r',
      'semitendinosus_l',
      'semitendinosus_r',
      'biceps_femoris_l',
      'biceps_femoris_r',
    ],
    'lowerBack': ['erector_spinae_l', 'erector_spinae_r'],
  };

  late final MuscleFatigueService _service;
  late final String? Function() _getUid;
  bool _showFront = true;
  bool _loading = true;
  Map<String, double> _scores = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _service = widget.fatigueService ?? MuscleFatigueService();
    _getUid = widget.getUid ?? (() => FirebaseAuth.instance.currentUser?.uid);
    _loadScores();
  }

  Future<void> _loadScores() async {
    final uid = _getUid();
    var scores = uid != null
        ? await _service.loadCurrentScores(uid)
        : <String, double>{};
    if (uid != null && scores.isEmpty) {
      final recalculated = await _service.recalculateLatest(uid);
      if (recalculated) scores = await _service.loadCurrentScores(uid);
    }
    if (!mounted) return;
    setState(() {
      _scores = scores;
      _loading = false;
    });
  }

  Map<MuscleInfo, Color> _buildColorMapping() {
    final mapping = <MuscleInfo, Color>{};
    for (final entry in _scores.entries) {
      final ids = _muscleIds[entry.key] ?? [];
      final color = _scoreToColor(entry.value);
      for (final id in ids) {
        final info = MuscleCatalog.tryById(id);
        if (info != null) mapping[info] = color;
      }
    }
    return mapping;
  }

  Color _scoreToColor(double score) {
    if (score < 25) return const Color(0xFF4CAF50); // verde   — descansado
    if (score < 50) return const Color(0xFFFFC107); // amarillo — recuperando
    if (score < 75) return const Color(0xFFFF9800); // naranja  — cansado
    return const Color(0xFFF44336); //               rojo      — fatigado
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        // Selector frontal / dorsal + botón actualizar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Frontal')),
                ButtonSegment(value: false, label: Text('Dorsal')),
              ],
              selected: {_showFront},
              onSelectionChanged: (s) => setState(() => _showFront = s.first),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: _loading
                  ? null
                  : () {
                      setState(() => _loading = true);
                      _loadScores();
                    },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Mapa corporal
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BodyAtlasView<MuscleInfo>(
                    view: _showFront
                        ? AtlasAsset.musclesFront
                        : AtlasAsset.musclesBack,
                    resolver: const MuscleResolver(),
                    colorMapping: _buildColorMapping(),
                  ),
                ),
        ),
        // Leyenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _chip(const Color(0xFF4CAF50), 'Descansado'),
              _chip(const Color(0xFFFFC107), 'Recuperando'),
              _chip(const Color(0xFFFF9800), 'Cansado'),
              _chip(const Color(0xFFF44336), 'Fatigado'),
              _chip(Colors.grey, 'Sin datos'),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _chip(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Datos Corporales
// ─────────────────────────────────────────────────────────────────────────────

class _BodyDataTab extends StatefulWidget {
  final BodyMeasurementService? measurementService;

  const _BodyDataTab({this.measurementService});

  @override
  State<_BodyDataTab> createState() => _BodyDataTabState();
}

class _BodyDataTabState extends State<_BodyDataTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _fatController = TextEditingController();
  final _muscleController = TextEditingController();
  late final BodyMeasurementService _measurementService;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _measurementService = widget.measurementService ?? BodyMeasurementService();
    _loadLastHeight();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _fatController.dispose();
    _muscleController.dispose();
    super.dispose();
  }

  Future<void> _loadLastHeight() async {
    final lastMeasurement = await _measurementService.getLastMeasurement();
    if (lastMeasurement != null && lastMeasurement['height'] != null) {
      if (mounted) {
        setState(() {
          _heightController.text = lastMeasurement['height'].toString();
        });
      }
    }
  }

  double? _parseMeasurement(String value) {
    final normalizedValue = value.trim().replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  String? _validateMeasurement(
    String? value, {
    bool required = false,
    double min = 0,
    double? max,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Requerido' : null;
    final parsed = _parseMeasurement(text);
    if (parsed == null || !parsed.isFinite) return 'Número no válido';
    if (parsed <= min) return 'Debe ser mayor que $min';
    if (max != null && parsed > max) return 'Debe ser como máximo $max';
    return null;
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _measurementService.addMeasurement({
        'weight': _parseMeasurement(_weightController.text),
        'height': _parseMeasurement(_heightController.text),
        'fat_percentage': _parseMeasurement(_fatController.text),
        'muscle_mass': _parseMeasurement(_muscleController.text),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medición guardada correctamente')),
        );
        _weightController.clear();
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

  Future<void> _deleteMeasurement(String id) async {
    try {
      await _measurementService.deleteMeasurement(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medición eliminada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar Medición'),
        content: const Text(
          '¿Estás seguro de que deseas borrar este registro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Borrar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteMeasurement(id);
  }

  Future<void> _showEditDialog(String id, Map<String, dynamic> data) async {
    final wCtrl = TextEditingController(text: data['weight']?.toString());
    final hCtrl = TextEditingController(text: data['height']?.toString());
    final fCtrl = TextEditingController(
      text: data['fat_percentage']?.toString(),
    );
    final mCtrl = TextEditingController(text: data['muscle_mass']?.toString());
    final editKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Medición'),
        content: Form(
          key: editKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(wCtrl, 'Peso (kg)', required: true),
                const SizedBox(height: 12),
                _editField(hCtrl, 'Altura (cm)'),
                const SizedBox(height: 12),
                _editField(fCtrl, '% Grasa', max: 100),
                const SizedBox(height: 12),
                _editField(mCtrl, 'Músculo (kg)'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!editKey.currentState!.validate()) return;
              try {
                await _measurementService.updateMeasurement(id, {
                  'weight': _parseMeasurement(wCtrl.text),
                  'height': _parseMeasurement(hCtrl.text),
                  'fat_percentage': _parseMeasurement(fCtrl.text),
                  'muscle_mass': _parseMeasurement(mCtrl.text),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  TextFormField _editField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    double? max,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) =>
          _validateMeasurement(value, required: required, max: max),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Formulario nueva medición ──────────────────────────────────────
        Text('Nueva Medición', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          _validateMeasurement(value, required: true),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateMeasurement,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          _validateMeasurement(value, max: 100),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateMeasurement,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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

        // ── Historial ───────────────────────────────────────────────────────
        Text('Historial', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _measurementService.getMeasurements(),
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
                  padding: EdgeInsets.all(32),
                  child: Text('No hay mediciones registradas'),
                ),
              );
            }

            final measurements = docs
                .map(
                  (d) => Measurement.fromMap(d.data() as Map<String, dynamic>),
                )
                .toList();

            return Column(
              children: [
                BodyCompositionChart(measurements: measurements),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final date =
                        (data['date'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    final formatted = DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(date);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatted,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () =>
                                          _showEditDialog(docs[index].id, data),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () =>
                                          _confirmDelete(docs[index].id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: colorScheme.error,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widget — ítem de medición en tarjeta
// ─────────────────────────────────────────────────────────────────────────────

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
