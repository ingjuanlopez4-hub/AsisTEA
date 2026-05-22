class ConductaRecord {
  final String recordId;
  final String childId;
  final String userId;
  final String source; // 'auto' | 'manual'
  final String? conversationId;

  // Event data
  final String fecha;
  final String fechaNormalizada;
  final String tipo;
  final String descripcion;
  final String intensidad;
  final String duracion;
  final List<String> desencadenantes;
  final String contexto;
  final String estrategiasAplicadas;
  final String resultado;

  // Metadata
  final String? notas;
  final bool confirmado;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConductaRecord({
    required this.recordId,
    required this.childId,
    required this.userId,
    this.source = 'auto',
    this.conversationId,
    required this.fecha,
    required this.fechaNormalizada,
    required this.tipo,
    required this.descripcion,
    this.intensidad = 'no_especificada',
    this.duracion = '',
    this.desencadenantes = const [],
    this.contexto = '',
    this.estrategiasAplicadas = '',
    this.resultado = '',
    this.notas,
    this.confirmado = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static const List<String> tiposValidos = [
    'crisis',
    'estereotipia',
    'rechazo_alimentario',
    'problema_sueño',
    'logro_comunicativo',
    'logro_social',
    'desencadenante_sensorial',
    'avance_motor',
    'rigidez_cognitiva',
    'interés_restringido',
    'ansiedad_separación',
    'autorregulación',
    'otro',
  ];

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'childId': childId,
        'userId': userId,
        'source': source,
        'conversationId': conversationId,
        'fecha': fecha,
        'fechaNormalizada': fechaNormalizada,
        'tipo': tipo,
        'descripcion': descripcion,
        'intensidad': intensidad,
        'duracion': duracion,
        'desencadenantes': desencadenantes,
        'contexto': contexto,
        'estrategiasAplicadas': estrategiasAplicadas,
        'resultado': resultado,
        'notas': notas,
        'confirmado': confirmado ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ConductaRecord.fromJson(Map<String, dynamic> json) =>
      ConductaRecord(
        recordId: json['recordId'] as String,
        childId: json['childId'] as String,
        userId: json['userId'] as String,
        source: json['source'] as String? ?? 'auto',
        conversationId: json['conversationId'] as String?,
        fecha: json['fecha'] as String,
        fechaNormalizada: json['fechaNormalizada'] as String,
        tipo: json['tipo'] as String,
        descripcion: json['descripcion'] as String,
        intensidad: json['intensidad'] as String? ?? 'no_especificada',
        duracion: json['duracion'] as String? ?? '',
        desencadenantes:
            (json['desencadenantes'] as List?)?.cast<String>() ?? [],
        contexto: json['contexto'] as String? ?? '',
        estrategiasAplicadas:
            json['estrategiasAplicadas'] as String? ?? '',
        resultado: json['resultado'] as String? ?? '',
        notas: json['notas'] as String?,
        confirmado: json['confirmado'] == 1 || json['confirmado'] == true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
}
