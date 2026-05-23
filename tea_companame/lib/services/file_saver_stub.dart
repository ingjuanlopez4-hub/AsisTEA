/// Guarda contenido en un archivo.
/// Stub para web — en web no se puede escribir al sistema de archivos
/// directamente; el contenido debe descargarse vía Blob.
class FileSaver {
  /// Lanza [UnsupportedError] en web.
  /// En web, usa [ExportService.exportToJsonString] y descarga
  /// el contenido mediante `dart:html` Blob / `AnchorElement`.
  static Future<String> save(String content, String filename) async {
    throw UnsupportedError(
      'La exportación a archivo no está disponible en web. '
      'Usa ExportService.buildJsonResult() para obtener '
      'el contenido como String y descárgalo con dart:html.',
    );
  }
}
