/// Configuración del LLM (local o remoto)
class ApiConfig {
  /// URL base de la API (ej. http://localhost:11434/v1 para Ollama)
  final String baseUrl;

  /// Nombre del modelo (ej. llama3.2, phi3, gpt-4o-mini)
  final String model;

  /// API Key (vacío para servidores locales como Ollama)
  final String apiKey;

  /// Temperatura del modelo (0.0 - 1.0)
  final double temperature;

  /// Máximo de tokens en la respuesta
  final int maxTokens;

  /// Sistema de moderación (local | cloud | hibrido)
  final String mode;

  const ApiConfig({
    this.baseUrl = 'http://localhost:11434/v1',
    this.model = 'llama3.2',
    this.apiKey = '',
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.mode = 'local',
  });

  ApiConfig copyWith({
    String? baseUrl,
    String? model,
    String? apiKey,
    double? temperature,
    int? maxTokens,
    String? mode,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'model': model,
        'apiKey': apiKey,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'mode': mode,
      };

  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
        baseUrl: json['baseUrl'] as String? ?? 'http://localhost:11434/v1',
        model: json['model'] as String? ?? 'llama3.2',
        apiKey: json['apiKey'] as String? ?? '',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        maxTokens: json['maxTokens'] as int? ?? 1000,
        mode: json['mode'] as String? ?? 'local',
      );

  /// URL completa para el endpoint de chat
  String get chatEndpoint => '$baseUrl/chat/completions';

  /// URL completa para verificar disponibilidad del servidor
  String get healthEndpoint => '$baseUrl/models';

  /// Si el servidor es local (sin API key requerida)
  bool get isLocal => mode == 'local';

  /// Si usa un proveedor cloud con API key
  bool get isCloud => mode == 'cloud';
}
