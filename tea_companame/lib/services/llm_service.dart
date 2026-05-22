import 'dart:convert';
import 'package:http/http.dart' as http;

class LLMService {
  final String _baseUrl;
  final String _apiKey;
  final String _model;

  LLMService({
    String baseUrl = 'https://api.openai.com/v1',
    required String apiKey,
    String model = 'gpt-4o-mini',
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _model = model;

  /// Envía un mensaje y recibe respuesta del LLM.
  /// Incluye el system prompt y el historial de mensajes.
  Future<LLMResponse> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final startTime = DateTime.now();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      final latency = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choice = (data['choices'] as List).first as Map<String, dynamic>;
        final message = choice['message'] as Map<String, dynamic>;
        final content = message['content'] as String;

        return LLMResponse(
          content: content,
          success: true,
          latencyMs: latency.inMilliseconds,
        );
      } else {
        return LLMResponse(
          content: '',
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
          latencyMs: latency.inMilliseconds,
        );
      }
    } catch (e) {
      final latency = DateTime.now().difference(startTime);
      return LLMResponse(
        content: '',
        success: false,
        error: e.toString(),
        latencyMs: latency.inMilliseconds,
      );
    }
  }

  /// Genera un resumen de una lista de mensajes.
  Future<String> generateSummary(String messages) async {
    final response = await sendMessage(
      systemPrompt:
          'Resume la siguiente conversación en 2-3 frases. Sé conciso.',
      messages: [
        {'role': 'user', 'content': messages},
      ],
    );
    return response.content;
  }
}

class LLMResponse {
  final String content;
  final bool success;
  final String? error;
  final int latencyMs;

  LLMResponse({
    required this.content,
    required this.success,
    this.error,
    required this.latencyMs,
  });
}
