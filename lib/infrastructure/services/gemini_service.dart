import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final http.Client _client;
  GeminiService([http.Client? client]) : _client = client ?? http.Client();

  Future<String> generateReply(
    String userMessage, {
    required String uid,
  }) async {
    // recoge entrenos y convierte Timestamp a ISO strings
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .get();

    final entrenos = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data.forEach((k, v) {
        if (v is Timestamp) data[k] = v.toDate().toIso8601String();
        if (v is List) {
          // opcional: convertir timestamps dentro de listas/ejercicios
          for (var item in v) {
            if (item is Map) {
              item.forEach((ik, iv) {
                if (iv is Timestamp) item[ik] = iv.toDate().toIso8601String();
              });
            }
          }
        }
      });
      return data;
    }).toList();

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not set');
    }

    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "Eres un entrenador personal virtual. Estos son mis entrenamientos en formato JSON: ${jsonEncode(entrenos)}. El usuario dice: $userMessage",
            },
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
}
