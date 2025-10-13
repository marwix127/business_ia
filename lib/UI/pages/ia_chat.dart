import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IAChatPage extends StatefulWidget {
  const IAChatPage({super.key});

  @override
  State<IAChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<IAChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final uid = FirebaseAuth.instance.currentUser?.uid;

  bool _loading = false;

  // 🔹 Obtiene todos los entrenos guardados en Firestore
  Future<String> _getEntrenos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid) // Cambia esto si tienes autenticación
        .collection('trainings')
        .get();
    final entrenos = snapshot.docs.map((d) {
      final data = d.data();
      // Convierte todos los Timestamp a String
      data.forEach((key, value) {
        if (value is Timestamp) {
          data[key] = value.toDate().toIso8601String();
        }
      });
      return data;
    }).toList();

    return jsonEncode(entrenos);
  }

  // 🔹 Envía el mensaje y los entrenos a Gemini
  Future<String> _sendToGemini(String userMessage) async {
    setState(() => _loading = true);

    final entrenos = await _getEntrenos();
    final apiKey = dotenv.env['GEMINI_API_KEY']!;
    final url =
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text":
                    "Eres un entrenador personal virtual. Estos son mis entrenamientos en formato JSON: $entrenos. El usuario dice: $userMessage",
              },
            ],
          },
        ],
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode != 200) {
      return "Error: ${response.statusCode} → ${response.body}";
    }

    final data = jsonDecode(response.body);

    // 🔸 Gemini puede devolver la respuesta en distintos campos
    final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
    if (text != null) return text;

    if (data["outputText"] != null) return data["outputText"];

    return "No pude generar una respuesta. ${data.toString()}";
  }

  // 🔹 Envía el mensaje del usuario al chat
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
    });

    final reply = await _sendToGemini(text);

    setState(() {
      _messages.add({"role": "ai", "text": reply});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg["role"] == "user";
                return Container(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.indigo
                          : const Color.fromARGB(231, 255, 255, 255),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe tu mensaje...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: const Color.fromARGB(255, 75, 63, 181),
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
