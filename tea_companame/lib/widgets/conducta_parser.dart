import 'dart:convert';
import '../models/conducta_record.dart';

class ConductaParser {
  /// Patrón regex para extraer bloques <conducta>
  /// Usa [\s\S]*? (non-greedy) para capturar JSON multilínea
  /// Flag i (case-insensitive) para <Conducta> o <CONDUCTA>
  static final RegExp _conductaRegex = RegExp(
    r'<\s*conducta\s*>([\s\S]*?)<\s*\/\s*conducta\s*>',
    caseSensitive: false,
  );

  /// Extrae y valida todos los bloques <conducta> de un texto.
  /// Retorna una lista de mapas JSON parseados (válidos).
  static List<Map<String, dynamic>> parseConductaBlocks(String text) {
    final matches = _conductaRegex.allMatches(text);
    final List<Map<String, dynamic>> validBlocks = [];

    for (final match in matches) {
      final jsonStr = match.group(1)?.trim();
      if (jsonStr == null || jsonStr.isEmpty) continue;

      try {
        final parsed = jsonDecode(jsonStr);
        if (parsed is Map<String, dynamic>) {
          if (_validateSchema(parsed)) {
            validBlocks.add(parsed);
          }
        }
      } catch (e) {
        // JSON malformado: descartar silenciosamente
        print('[ConductaParser] JSON inválido descartado: $e');
      }
    }

    return validBlocks;
  }

  /// Valida que el mapa cumpla con el esquema mínimo de ConductaRecord.
  static bool _validateSchema(Map<String, dynamic> data) {
    if (data['tipo'] is! String) return false;
    if (data['descripcion'] is! String) return false;
    if (data['descripcion'].toString().length < 3) return false;

    final tipo = data['tipo'] as String;
    if (!ConductaRecord.tiposValidos.contains(tipo)) return false;

    return true;
  }

  /// Normaliza la fecha: "hoy" → fecha actual ISO, "ayer" → fecha -1 día.
  static String normalizarFecha(String fecha, DateTime now) {
    final lower = fecha.toLowerCase().trim();
    if (lower == 'hoy') {
      return _toIsoDate(now);
    } else if (lower == 'ayer') {
      return _toIsoDate(now.subtract(const Duration(days: 1)));
    }
    return fecha;
  }

  static String _toIsoDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Limpia el texto quitando los bloques <conducta> para mostrar al usuario.
  static String stripConductaBlocks(String text) {
    return text.replaceAll(_conductaRegex, '').trim();
  }

  /// Detecta si hay bloques <conducta> en el texto.
  static bool hasConductaBlocks(String text) {
    return _conductaRegex.hasMatch(text);
  }
}
