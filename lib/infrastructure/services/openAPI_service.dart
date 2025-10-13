import 'dart:convert';
import 'package:http/http.dart' as http;

const AIApiKey = 'sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

Future<String> obtenerRespuestaIA(String mensaje) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $AIApiKey',
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "user", "content": mensaje},
      ],
      "max_tokens": 150,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'].trim();
  } else {
    throw Exception('Error al conectar con OpenAI: ${response.body}');
  }
}
