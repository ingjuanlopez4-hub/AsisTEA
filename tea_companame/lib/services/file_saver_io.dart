import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Guarda contenido en un archivo en el directorio temporal.
/// Implementación nativa (Android / iOS / Linux / macOS / Windows).
class FileSaver {
  /// Escribe [content] en un archivo llamado [filename] dentro
  /// del directorio temporal de la app.
  ///
  /// Retorna la ruta absoluta del archivo generado.
  static Future<String> save(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final exportDir = Directory('${dir.path}/teacompaname_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}
