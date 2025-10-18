import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final http.Client _client;
  GeminiService([http.Client? client]) : _client = client ?? http.Client();

  // ...existing code...
  Future<String> generateReply(
    String userMessage, {
    required String uid,
    int maxTrainings = 30, // <-- número máximo de entrenamientos a considerar
    bool includeSummary = true,
  }) async {
    // recoge solo los últimos `maxTrainings` ordenados por fecha descendente
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .orderBy('date', descending: true)
        .limit(maxTrainings)
        .get();

    // mapear a un shape mínimo para reducir tamaño y convertir Timestamp
    final entrenos = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      return {
        'id': d.id,
        'name': data['name'] ?? data['nombre'],
        'date': (data['date'] is Timestamp)
            ? (data['date'] as Timestamp).toDate().toIso8601String()
            : data['date']?.toString(),
        // incluye sólo lo imprescindible de ejercicios/series
        'exercises':
            (data['exercises'] as List<dynamic>?)
                ?.map(
                  (e) => {
                    'name': e['name'] ?? e['nombre'],
                    'series_count':
                        (e['series'] as List<dynamic>?)?.length ?? 0,
                    // opcional: volumen estimado
                  },
                )
                .toList() ??
            [],
      };
    }).toList();

    // generar resumen pequeño si se desea (opcional, evita mandar todo)
    String resumen = '';
    if (includeSummary) {
      resumen = _simpleSummary(entrenos);
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not set');
    }

    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final prompt = StringBuffer()
      ..writeln('Eres un entrenador personal virtual.')
      ..writeln('Resumen de entrenamientos (últimos ${entrenos.length}):')
      ..writeln(resumen)
      ..writeln(
        'Si necesitas ejemplos concretos, pide al usuario que lo confirme. Usuario pregunta: $userMessage',
      );

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt.toString()},
          ],
        },
      ],
    };

    final resp = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception('API error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final text =
        data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
        data["outputText"] ??
        '';

    return text;
  }

  String _simpleSummary(List<Map<String, dynamic>> entrenos) {
    if (entrenos.isEmpty) return 'No hay entrenamientos registrados.';
    final sesiones = entrenos.length;
    final ejercicioCounts = <String, int>{};
    for (final t in entrenos) {
      final exs = t['exercises'] as List<dynamic>;
      for (final e in exs) {
        final name = (e['name'] ?? 'unknown').toString();
        ejercicioCounts[name] = (ejercicioCounts[name] ?? 0) + 1;
      }
    }
    final top = ejercicioCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topText = top.isEmpty
        ? '–'
        : top.take(3).map((e) => '${e.key} (${e.value})').join(', ');
    return 'Sesiones (últimas): $sesiones. Ejercicios más frecuentes: $topText.';
  }
}
