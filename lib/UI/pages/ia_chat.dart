import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../infrastructure/services/gemini_service.dart';

class IAChatPage extends StatefulWidget {
  const IAChatPage({super.key});

  @override
  State<IAChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<IAChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final GeminiService _gemini = GeminiService();

  bool _loading = false;

  // ...existing code removed: _getEntrenos and _sendToGemini ...

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
      _loading = true;
    });

    try {
      if (uid == null) throw Exception('No user');
      final reply = await _gemini.generateReply(text, uid: uid!);
      setState(() {
        _messages.add({"role": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": 'Error: $e'});
      });
    } finally {
      setState(() => _loading = false);
    }
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
