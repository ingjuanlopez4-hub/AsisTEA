import 'dart:convert';

import '../models/conducta_record.dart';
import 'file_saver.dart';

/// Resultado de una exportación.
class ExportResult {
  final String content;
  final String suggestedFilename;
  final String mimeType;

  const ExportResult({
    required this.content,
    required this.suggestedFilename,
    required this.mimeType,
  });
}

/// Servicio de exportación de la bitácora.
///
/// Genera contenido JSON (datos estructurados) y HTML (informe
/// legible para terapeutas) a partir de los registros de conducta.
/// El contenido se guarda a archivo mediante [FileSaver] (que
/// maneja la diferencia entre web y nativo).
class ExportService {
  /// Exporta los registros como archivo JSON.
  /// Retorna la ruta del archivo generado.
  Future<String> exportToJson(List<ConductaRecord> records) async {
    final result = buildJsonResult(records);
    return FileSaver.save(result.content, result.suggestedFilename);
  }

  /// Exporta los registros como archivo HTML.
  /// Retorna la ruta del archivo generado.
  Future<String> exportToHtml(List<ConductaRecord> records) async {
    final result = buildHtmlResult(records);
    return FileSaver.save(result.content, result.suggestedFilename);
  }

  /// Construye el [ExportResult] con contenido JSON.
  ExportResult buildJsonResult(List<ConductaRecord> records) {
    final timestamp = _timestamp();
    final jsonList = records.map((r) => r.toJson()).toList();
    final metadata = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRecords': records.length,
      'appName': 'TEAcompáñame',
      'version': '1.0.0',
    };
    final payload = {'metadata': metadata, 'records': jsonList};
    final content = const JsonEncoder.withIndent('  ').convert(payload);
    return ExportResult(
      content: content,
      suggestedFilename: 'bitacora_$timestamp.json',
      mimeType: 'application/json',
    );
  }

  /// Construye el [ExportResult] con contenido HTML.
  ExportResult buildHtmlResult(List<ConductaRecord> records) {
    final timestamp = _timestamp();
    final html = _buildHtml(records);
    return ExportResult(
      content: html,
      suggestedFilename: 'informe_teacompaname_$timestamp.html',
      mimeType: 'text/html',
    );
  }

  String _timestamp() {
    return DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
  }

  // ================================================================
  // Construcción del HTML
  // ================================================================

  String _buildHtml(List<ConductaRecord> records) {
    final now = DateTime.now();
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const primaryGreen = '#5B9F6F';
    const accentWarm = '#E8A87C';

    // Métricas
    final total = records.length;
    final confirmados = records.where((r) => r.confirmado).length;
    final crisis = records.where((r) => r.tipo == 'crisis').length;
    final logros = records.where((r) =>
        r.tipo == 'logro_comunicativo' ||
        r.tipo == 'logro_social' ||
        r.tipo == 'avance_motor' ||
        r.tipo == 'autorregulación').length;

    // Desencadenantes más frecuentes
    final triggerFreq = <String, int>{};
    for (final r in records) {
      for (final t in r.desencadenantes) {
        final key = t.trim().toLowerCase();
        if (key.isNotEmpty) {
          triggerFreq[key] = (triggerFreq[key] ?? 0) + 1;
        }
      }
    }
    final topTriggers = triggerFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTriggersHtml = topTriggers.take(5).map((e) =>
      '<li><strong>${_capitalize(e.key)}</strong> — ${e.value} vez${e.value == 1 ? '' : 'es'}</li>'
    ).join('\n');

    // Distribución por tipo
    final tipoCount = <String, int>{};
    for (final r in records) {
      tipoCount[r.tipo] = (tipoCount[r.tipo] ?? 0) + 1;
    }
    final tipoLabels = {
      'crisis': 'Crisis',
      'estereotipia': 'Estereotipias',
      'rechazo_alimentario': 'Rechazo alimentario',
      'problema_sueño': 'Problemas de sueño',
      'logro_comunicativo': 'Logros comunicativos',
      'logro_social': 'Logros sociales',
      'desencadenante_sensorial': 'Desencadenantes sensoriales',
      'avance_motor': 'Avances motores',
      'rigidez_cognitiva': 'Rigidez cognitiva',
      'interés_restringido': 'Intereses restringidos',
      'ansiedad_separación': 'Ansiedad por separación',
      'autorregulación': 'Autorregulación',
      'otro': 'Otros',
    };
    final tipoRows = tipoCount.entries
        .where((e) => e.value > 0)
        .map((e) {
      final label = tipoLabels[e.key] ?? e.key.replaceAll('_', ' ');
      final pct = (e.value / total * 100).toStringAsFixed(0);
      return '''
        <tr>
          <td style="padding: 6px 12px; border-bottom: 1px solid #eee;">$label</td>
          <td style="padding: 6px 12px; border-bottom: 1px solid #eee; text-align: center; font-weight: 600;">${e.value}</td>
          <td style="padding: 6px 12px; border-bottom: 1px solid #eee; text-align: center;">$pct%</td>
        </tr>''';
    }).join('\n');

    // Tabla de registros
    final recordsRows = records.take(50).map((r) {
      final tipoLabel = tipoLabels[r.tipo] ?? r.tipo.replaceAll('_', ' ');
      final fechaStr = _formatDateHtml(r.fechaNormalizada);
      final intensidadClr = _intensidadColorHtml(r.intensidad);
      final checkIcon = r.confirmado ? '✓' : '—';
      return '''
        <tr>
          <td style="padding: 8px 12px; border-bottom: 1px solid #eee; font-size: 13px;">$fechaStr</td>
          <td style="padding: 8px 12px; border-bottom: 1px solid #eee; font-size: 13px;">$tipoLabel</td>
          <td style="padding: 8px 12px; border-bottom: 1px solid #eee; font-size: 13px; color: #555;">${r.descripcion.length > 80 ? r.descripcion.substring(0, 80) + '...' : r.descripcion}</td>
          <td style="padding: 8px 12px; border-bottom: 1px solid #eee; text-align: center; font-size: 13px; font-weight: 600; color: $intensidadClr;">${r.intensidad == 'no_especificada' ? '—' : r.intensidad}</td>
          <td style="padding: 8px 12px; border-bottom: 1px solid #eee; text-align: center; font-size: 13px;">$checkIcon</td>
        </tr>''';
    }).join('\n');

    final recordsCount = records.length;
    final showingCount = recordsCount > 50 ? 50 : recordsCount;

    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Informe TEAcompáñame</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #2D3436;
      background: #F8F6F0;
      padding: 40px 20px;
      line-height: 1.6;
    }
    .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
    h1 { font-size: 24px; color: $primaryGreen; margin-bottom: 4px; }
    h2 { font-size: 18px; color: #2D3436; margin-top: 28px; margin-bottom: 12px; padding-bottom: 6px; border-bottom: 2px solid $primaryGreen; }
    h3 { font-size: 15px; color: #555; margin-top: 16px; margin-bottom: 8px; }
    .subtitle { color: #636E72; font-size: 14px; margin-bottom: 24px; }
    .meta { font-size: 13px; color: #636E72; margin-bottom: 8px; }
    .grid { display: flex; gap: 12px; margin: 16px 0; flex-wrap: wrap; }
    .card {
      flex: 1; min-width: 120px;
      background: #F8F6F0; border-radius: 12px; padding: 16px;
      text-align: center; border: 1px solid #eee;
    }
    .card .num { font-size: 28px; font-weight: 700; color: $primaryGreen; }
    .card .label { font-size: 12px; color: #636E72; margin-top: 2px; }
    .card .num.crisis { color: #e53935; }
    .card .num.logros { color: #F9A825; }
    table { width: 100%; border-collapse: collapse; margin-top: 8px; }
    th { text-align: left; padding: 10px 12px; font-size: 12px; text-transform: uppercase; color: #636E72; border-bottom: 2px solid #eee; }
    td { }
    .footer { margin-top: 32px; padding-top: 16px; border-top: 1px solid #eee; font-size: 12px; color: #636E72; text-align: center; }
    .badge {
      display: inline-block; padding: 2px 8px; border-radius: 4px;
      font-size: 11px; font-weight: 600; background: $primaryGreen; color: white;
    }
    .triggers { list-style: none; padding: 0; }
    .triggers li { padding: 6px 0; border-bottom: 1px solid #f0f0f0; font-size: 13px; }
    @media print {
      body { background: white; padding: 0; }
      .container { box-shadow: none; padding: 20px; }
    }
  </style>
</head>
<body>
  <div class="container">

    <h1>📋 Informe de Bitácora</h1>
    <p class="subtitle">TEAcompáñame — Generado el ${now.day} de ${meses[now.month - 1]} de ${now.year}</p>

    <p class="meta">Período: Desde el primer registro hasta la fecha</p>
    <p class="meta">Total de registros: <strong>$total</strong></p>

    <!-- Métricas -->
    <div class="grid">
      <div class="card">
        <div class="num">$total</div>
        <div class="label">Registros totales</div>
      </div>
      <div class="card">
        <div class="num crisis">$crisis</div>
        <div class="label">Crisis</div>
      </div>
      <div class="card">
        <div class="num logros">$logros</div>
        <div class="label">Logros</div>
      </div>
      <div class="card">
        <div class="num">$confirmados</div>
        <div class="label">Confirmados</div>
      </div>
    </div>

    <!-- Distribución por tipo -->
    <h2>Distribución por tipo</h2>
    <table>
      <thead>
        <tr>
          <th>Tipo</th>
          <th style="text-align: center;">Cantidad</th>
          <th style="text-align: center;">%</th>
        </tr>
      </thead>
      <tbody>
        $tipoRows
      </tbody>
    </table>

    <!-- Desencadenantes frecuentes -->
    <h2>Desencadenantes frecuentes</h2>
    ${topTriggersHtml.isNotEmpty
      ? '<ul class="triggers">$topTriggersHtml</ul>'
      : '<p style="color: #636E72; font-size: 13px;">No se han registrado desencadenantes.</p>'
    }

    <!-- Registros detallados -->
    <h2>Registros detallados</h2>
    <p class="meta">Mostrando los $showingCount registros más recientes${recordsCount > 50 ? ' (de $recordsCount totales)' : ''}.</p>
    <table>
      <thead>
        <tr>
          <th>Fecha</th>
          <th>Tipo</th>
          <th>Descripción</th>
          <th style="text-align: center;">Int.</th>
          <th style="text-align: center;">✓</th>
        </tr>
      </thead>
      <tbody>
        $recordsRows
      </tbody>
    </table>

    <!-- Footer -->
    <div class="footer">
      <p>Generado por <strong>TEAcompáñame</strong> — ${now.day}/${now.month}/${now.year}</p>
      <p style="margin-top: 4px;">Este informe puede ser compartido con terapeutas y profesionales de la salud.</p>
    </div>

  </div>
</body>
</html>
''';
  }

  // ================================================================
  // Helpers
  // ================================================================

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatDateHtml(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${d.day} ${meses[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _intensidadColorHtml(String intensidad) {
    switch (intensidad) {
      case '1': return '#4CAF50';
      case '2': return '#8BC34A';
      case '3': return '#FF9800';
      case '4': return '#FF5722';
      case '5': return '#E53935';
      default: return '#636E72';
    }
  }
}
