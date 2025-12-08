import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  GeminiService();

  Future<String> generateReply(
    String userMessage, {
    required String uid,
    int maxTrainings = 50,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not set');
    }

    // Initialize model if not already done
    _model ??= GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    // Initialize chat session if not active
    if (_chatSession == null) {
      final historyContext = await _fetchAndFormatHistory(uid, maxTrainings);

      _chatSession = _model!.startChat(
        history: [
          Content('user', [
            TextPart('''
Eres un entrenador personal virtual experto.
Aquí tienes el historial detallado de los últimos entrenamientos del usuario:
$historyContext

Usa esta información para dar respuestas personalizadas y precisas sobre su progreso, pesos, y frecuencia.
'''),
          ]),
          Content('model', [
            TextPart(
              'Entendido. Tengo el contexto de tus entrenamientos. ¿En qué puedo ayudarte hoy?',
            ),
          ]),
        ],
      );
    }

    final response = await _chatSession!.sendMessage(Content.text(userMessage));
    return response.text ?? 'No response from AI.';
  }

  void resetChat() {
    _chatSession = null;
  }

  Future<String> _fetchAndFormatHistory(String uid, int maxTrainings) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .orderBy('date', descending: true)
        .limit(maxTrainings)
        .get();

    final entrenos = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      return {
        'id': d.id,
        'name': data['name'] ?? data['nombre'],
        'date': (data['date'] is Timestamp)
            ? (data['date'] as Timestamp).toDate()
            : DateTime.tryParse(data['date'].toString()),
        'exercises':
            (data['exercises'] as List<dynamic>?)
                ?.map(
                  (e) => {
                    'name': e['name'] ?? e['nombre'],
                    'series':
                        (e['series'] as List<dynamic>?)
                            ?.map(
                              (s) => {
                                'repetitions': s['repetitions'],
                                'weight': s['weight'],
                              },
                            )
                            .toList() ??
                        [],
                  },
                )
                .toList() ??
            [],
      };
    }).toList();

    return _formatTrainingHistory(entrenos);
  }

  String _formatTrainingHistory(List<Map<String, dynamic>> entrenos) {
    if (entrenos.isEmpty) return 'No hay entrenamientos registrados.';
    final buffer = StringBuffer();

    for (final t in entrenos) {
      final date = t['date'] as DateTime?;
      final dateStr = date != null
          ? "${date.day}/${date.month}/${date.year}"
          : "Fecha desconocida";
      final name = t['name'] ?? 'Sin nombre';

      buffer.writeln('- $dateStr: $name');

      final exercises = t['exercises'] as List<dynamic>;
      for (final e in exercises) {
        final exName = e['name'] ?? 'Ejercicio';
        final series = e['series'] as List<dynamic>;

        final seriesStr = series
            .map((s) {
              final reps = s['repetitions'] ?? 0;
              final weight = s['weight'] ?? 0;
              return '${reps}x${weight}kg';
            })
            .join(', ');

        buffer.writeln('  * $exName: $seriesStr');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
