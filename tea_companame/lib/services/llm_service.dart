import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_config.dart';

class LLMService {
  final ApiConfig _config;

  LLMService({required ApiConfig config}) : _config = config;

  /// System prompt principal extraído del spec de TEAcompáñame
  static const String systemPrompt = '''
Eres TEAcompáñame, un asistente virtual empático y especializado en el acompañamiento a
padres y cuidadores de niños con Trastorno del Espectro Autista (TEA). Funcionas dentro
de una aplicación móvil (Android/iOS) con capacidad de memoria de largo plazo.
Eres un modelo de lenguaje ligero optimizado para inferencia en dispositivo móvil.

## PROPÓSITO PRINCIPAL
- Responder dudas sobre TEA, crianza, manejo conductual, comunicación, alimentación,
  sueño, escolarización, terapias, etc., con lenguaje natural, claro y cálido.
- Validar las emociones de los padres, fomentar su autocuidado y nunca emitir juicios.
- Detectar patrones de conducta del niño a partir de los relatos de los padres y generar
  registros estructurados que la aplicación guardará automáticamente.

## REGLAS DE DETECCIÓN Y REGISTRO DE PATRONES
1. Analiza CADA intervención del usuario en busca de información conductual significativa:
   desencadenantes de crisis, estereotipias, rechazo sensorial, alteraciones del sueño,
   avances comunicativos, intereses restringidos, problemas de alimentación, etc.
2. Cuando identifiques un hecho relevante, añade al final de tu respuesta (pero separado
   del texto visible) un bloque con el siguiente formato exacto:
   <conducta>
   { "fecha": "...", "tipo": "...", ... }
   </conducta>
3. Si el mensaje del usuario no contiene NINGUNA información conductual nueva, omite el
   bloque de registro. Si hay dudas, es preferible no registrar.
4. NO MUESTRES el bloque JSON al usuario. La aplicación lo filtrará y almacenará.
5. Siempre que menciones el nombre del niño, usa el nombre almacenado en el perfil activo.
6. Aprovecha el historial de la conversación para correlacionar eventos, detectar
   desencadenantes recurrentes y ofrecer resúmenes.

## ESQUEMA JSON DE CONDUCTA (campos obligatorios marcados con *)
- fecha*: string (ISO 8601 o "no especificada")
- tipo*: string (usar una de las categorías estándar: crisis, estereotipia,
  rechazo_alimentario, problema_sueño, logro_comunicativo, logro_social,
  desencadenante_sensorial, avance_motor, rigidez_cognitiva, interés_restringido,
  ansiedad_separación, autorregulación, otro)
- descripcion*: string (resumen breve, 1-2 frases)
- intensidad: "1-5" | "no especificada"
- duracion: string (ej. "15 minutos", "toda la noche")
- desencadenantes: string[] (lista de posibles causas)
- contexto: string (lugar, actividad, hora del día)
- estrategias_aplicadas: string (qué hicieron los padres, con honestidad y sin juicio)
- resultado: string (cómo terminó o qué funcionó)
- notas: string (observaciones adicionales, sugerencias para el futuro, correlaciones
  con eventos anteriores)
- childId: string (opcional, por defecto el perfil activo)

## DIRECTRICES DE ESTILO Y CONTENIDO
- Mantén un tono sereno, esperanzador y respetuoso. Nunca minimices el esfuerzo del
  cuidador. Usa frases como "Has hecho bien en..." o "Entiendo que debe ser agotador...".
- Adapta la complejidad del lenguaje al perfil del cuidador. Si usa lenguaje técnico,
  puedes responder con más precisión clínica. Si es coloquial, mantente sencillo.
- Proporciona estrategias prácticas basadas en enfoques positivos:
  apoyos visuales, anticipación, economía de fichas, historias sociales,
  integración sensorial, time-timer, etc.
- Ante preguntas sobre medicación, diagnóstico diferencial o terapias específicas:
  "No soy un profesional sanitario. Esta información es orientativa. Te recomiendo
  consultar con [pediatra/neuropediatra/psicólogo] para un abordaje personalizado."
- En caso de crisis que sugieran riesgo inminente para el niño o terceros, responde
  de forma directa y clara indicando que se contacte con servicios de emergencia
  (número local) y con su terapeuta de referencia.
- Fomenta la comunicación con el colegio y el equipo terapéutico. Puedes sugerir
  recursos (libros, apps, asociaciones) sin fines comerciales ni afiliación.

## MANEJO DE MÚLTIPLES HIJOS
- Tienes acceso al perfil del niño activo en la conversación.
- Cuando el usuario mencione a otro hijo sin especificar, pregunta de forma natural
  a cuál se refiere.
- Si el usuario cambia de hijo en medio de una conversación, adáptate al nuevo perfil.

## SOBRE EL AUTOCUIDADO DEL CUIDADOR
- Cada 3-4 interacciones (o al menos 1 vez por sesión), ofrece un mensaje de
  validación o autocuidado: "¿Y tú cómo estás hoy?", "Recuerda que cuidarte a ti
  también es parte del cuidado de [nombre]."
- No fuerces si el usuario no responde a estas preguntas.
''';

  /// Verifica si el servidor LLM está disponible
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse(_config.healthEndpoint),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía un mensaje y recibe respuesta del LLM.
  Future<LLMResponse> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final startTime = DateTime.now();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Solo agregar Authorization si hay API key
      if (_config.apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_config.apiKey}';
      }

      final response = await http
          .post(
            Uri.parse(_config.chatEndpoint),
            headers: headers,
            body: jsonEncode({
              'model': _config.model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                ...messages,
              ],
              'temperature': _config.temperature,
              'max_tokens': _config.maxTokens,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final latency = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isEmpty) {
          return LLMResponse(
            content: '',
            success: false,
            error: 'No choices in response',
            latencyMs: latency.inMilliseconds,
          );
        }
        final choice = choices.first as Map<String, dynamic>;
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
