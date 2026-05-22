import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/conducta_parser.dart';

void main() {
  group('ConductaParser - Extracción de bloques', () {
    test('debe extraer un bloque <conducta> válido', () {
      final input = '''
He notado que hoy ha tenido un día difícil.

<conducta>
{
  "fecha": "hoy",
  "tipo": "crisis",
  "descripcion": "Episodio de desregulación emocional",
  "intensidad": "4"
}
</conducta>
''';

      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks.length, 1);
      expect(blocks[0]['tipo'], 'crisis');
      expect(blocks[0]['descripcion'], 'Episodio de desregulación emocional');
    });

    test('debe ser case-insensitive con <Conducta> y <CONDUCTA>', () {
      final input1 = '<Conducta>{"tipo": "crisis", "descripcion": "test"}</Conducta>';
      final input2 = '<CONDUCTA>{"tipo": "crisis", "descripcion": "test"}</CONDUCTA>';

      expect(ConductaParser.parseConductaBlocks(input1).length, 1);
      expect(ConductaParser.parseConductaBlocks(input2).length, 1);
    });

    test('debe extraer múltiples bloques en una misma respuesta', () {
      final input = '''
<conducta>
{"tipo": "crisis", "descripcion": "primera crisis"}
</conducta>
Algo de texto intermedio...
<conducta>
{"tipo": "logro_comunicativo", "descripcion": "dijo una palabra nueva"}
</conducta>
''';

      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks.length, 2);
      expect(blocks[0]['tipo'], 'crisis');
      expect(blocks[1]['tipo'], 'logro_comunicativo');
    });

    test('debe ignorar bloques con JSON inválido', () {
      final input = '''
<conducta>
{ JSON inválido aquí }
</conducta>
''';

      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks.length, 0);
    });

    test('debe ignorar bloques vacíos', () {
      final input = '<conducta>  </conducta>';
      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks.length, 0);
    });

    test('debe devolver lista vacía si no hay bloques', () {
      final input = 'Texto normal sin bloques de conducta.';
      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks, isEmpty);
    });

    test('debe rechazar tipos de conducta inválidos', () {
      final input = '''
<conducta>
{"tipo": "tipo_invalido", "descripcion": "test"}
</conducta>
''';
      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks, isEmpty);
    });

    test('debe rechazar descripciones demasiado cortas', () {
      final input = '''
<conducta>
{"tipo": "crisis", "descripcion": "ab"}
</conducta>
''';
      final blocks = ConductaParser.parseConductaBlocks(input);
      expect(blocks, isEmpty);
    });
  });

  group('ConductaParser - Strip de bloques', () {
    test('debe eliminar bloques <conducta> del texto visible', () {
      final input = 'Hola, esto es un mensaje.\n\n<conducta>{"tipo": "crisis", "descripcion": "test"}</conducta>\n\n¿Cómo estás?';
      final cleaned = ConductaParser.stripConductaBlocks(input);
      expect(cleaned.contains('<conducta>'), false);
      expect(cleaned.contains('Hola, esto es un mensaje.'), true);
      expect(cleaned.contains('¿Cómo estás?'), true);
    });
  });

  group('ConductaParser - Normalización de fechas', () {
    test('"hoy" debe devolver la fecha actual ISO', () {
      final now = DateTime(2024, 11, 15);
      final result = ConductaParser.normalizarFecha('hoy', now);
      expect(result, '2024-11-15');
    });

    test('"ayer" debe devolver la fecha de ayer ISO', () {
      final now = DateTime(2024, 11, 15);
      final result = ConductaParser.normalizarFecha('ayer', now);
      expect(result, '2024-11-14');
    });

    test('una fecha ISO debe devolverse sin cambios', () {
      final now = DateTime(2024, 11, 15);
      final result = ConductaParser.normalizarFecha('2024-10-01', now);
      expect(result, '2024-10-01');
    });
  });

  group('ConductaParser - hasConductaBlocks', () {
    test('debe detectar presencia de bloques', () {
      expect(ConductaParser.hasConductaBlocks('<conducta>{}</conducta>'), true);
      expect(ConductaParser.hasConductaBlocks('Texto normal'), false);
    });
  });
}
