import 'package:flutter_test/flutter_test.dart';
import 'package:tea_companame/models/conducta_record.dart';
import 'package:tea_companame/services/storage_service.dart';

void main() {
  group('ConductaRecord - Modelo', () {
    test('debe crear un registro válido con campos requeridos', () {
      final record = ConductaRecord(
        recordId: 'test-123',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Episodio de desregulación emocional',
      );

      expect(record.recordId, 'test-123');
      expect(record.childId, 'child-001');
      expect(record.tipo, 'crisis');
      expect(record.descripcion, 'Episodio de desregulación emocional');
      expect(record.source, 'auto'); // valor por defecto
      expect(record.confirmado, false); // valor por defecto
    });

    test('debe validar tipos de conducta válidos', () {
      expect(ConductaRecord.tiposValidos.contains('crisis'), true);
      expect(ConductaRecord.tiposValidos.contains('logro_comunicativo'), true);
      expect(ConductaRecord.tiposValidos.contains('otro'), true);
      expect(ConductaRecord.tiposValidos.contains('tipo_invalido'), false);
    });

    test('debe serializar y deserializar correctamente', () {
      final original = ConductaRecord(
        recordId: 'test-456',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'ayer',
        fechaNormalizada: '2024-11-14',
        tipo: 'logro_comunicativo',
        descripcion: 'Dijo una palabra nueva',
        intensidad: 'alta',
        desencadenantes: ['ruido fuerte', 'cambio de rutina'],
        confirmado: true,
      );

      final json = original.toJson();
      final restored = ConductaRecord.fromJson(json);

      expect(restored.recordId, original.recordId);
      expect(restored.tipo, original.tipo);
      expect(restored.descripcion, original.descripcion);
      expect(restored.desencadenantes.length, 2);
      expect(restored.confirmado, true);
    });

    test('debe manejar listas vacías por defecto', () {
      final record = ConductaRecord(
        recordId: 'test-789',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'otro',
        descripcion: 'Sin desencadenantes específicos',
      );

      expect(record.desencadenantes, isEmpty);
      expect(record.duracion, isEmpty);
      expect(record.contexto, isEmpty);
    });
  });

  group('StorageService - Deduplicación', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService();
    });

    test('debe detectar duplicados por fechaNormalizada, tipo y descripción', () async {
      final record1 = ConductaRecord(
        recordId: 'rec-001',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Episodio de desregulación',
      );

      final record2 = ConductaRecord(
        recordId: 'rec-002',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy por la tarde',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Episodio de desregulación',
      );

      // Simular que record1 ya existe
      await storage.insertConductaRecord(record1);
      
      // Intentar insertar record2 (debería ser detectado como duplicado)
      await storage.insertConductaRecord(record2);

      final records = await storage.getConductaRecords(childId: 'child-001');
      
      // Solo debería haber 1 registro (el segundo fue descartado)
      expect(records.length, 1);
      expect(records[0].recordId, 'rec-001');
    });

    test('debe permitir registros diferentes en el mismo día', () async {
      final record1 = ConductaRecord(
        recordId: 'rec-003',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Primera crisis del día',
      );

      final record2 = ConductaRecord(
        recordId: 'rec-004',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy tarde',
        fechaNormalizada: '2024-11-15',
        tipo: 'logro_comunicativo',
        descripcion: 'Dijo una palabra nueva',
      );

      await storage.insertConductaRecord(record1);
      await storage.insertConductaRecord(record2);

      final records = await storage.getConductaRecords(childId: 'child-001');
      
      // Debería haber 2 registros (diferente tipo)
      expect(records.length, 2);
    });

    test('debe normalizar strings para comparación de duplicados', () async {
      final record1 = ConductaRecord(
        recordId: 'rec-005',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Episodio   de   desregulación',
      );

      final record2 = ConductaRecord(
        recordId: 'rec-006',
        childId: 'child-001',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'episodio de desregulación',
      );

      await storage.insertConductaRecord(record1);
      await storage.insertConductaRecord(record2);

      final records = await storage.getConductaRecords(childId: 'child-001');
      
      // Debería detectar como duplicado a pesar de diferencias en espacios/mayúsculas
      expect(records.length, 1);
    });
  });

  group('StorageService - Operaciones CRUD', () {
    late StorageService storage;

    setUp(() {
      storage = StorageService();
    });

    test('debe insertar y recuperar un registro', () async {
      final record = ConductaRecord(
        recordId: 'crud-001',
        childId: 'child-002',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'estereotipia',
        descripcion: 'Movimiento repetitivo de manos',
      );

      await storage.insertConductaRecord(record);
      final records = await storage.getConductaRecords(childId: 'child-002');

      expect(records.any((r) => r.recordId == 'crud-001'), true);
    });

    test('debe actualizar un registro existente', () async {
      final record = ConductaRecord(
        recordId: 'crud-002',
        childId: 'child-002',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'problema_sueño',
        descripcion: 'No pudo dormir bien',
        confirmado: false,
      );

      await storage.insertConductaRecord(record);
      
      final updated = ConductaRecord(
        recordId: 'crud-002',
        childId: 'child-002',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'problema_sueño',
        descripcion: 'No pudo dormir bien',
        confirmado: true,
        notas: 'Mejoró por la noche',
      );

      await storage.updateConductaRecord(updated);
      final records = await storage.getConductaRecords(childId: 'child-002');
      final found = records.firstWhere((r) => r.recordId == 'crud-002');

      expect(found.confirmado, true);
      expect(found.notas, 'Mejoró por la noche');
    });

    test('debe eliminar un registro', () async {
      final record = ConductaRecord(
        recordId: 'crud-003',
        childId: 'child-002',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'ansiedad_separación',
        descripcion: 'Lloró al separarse',
      );

      await storage.insertConductaRecord(record);
      await storage.deleteConductaRecord('crud-003');

      final records = await storage.getConductaRecords(childId: 'child-002');
      expect(records.any((r) => r.recordId == 'crud-003'), false);
    });

    test('debe filtrar registros por childId', () async {
      final record1 = ConductaRecord(
        recordId: 'filter-001',
        childId: 'child-A',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Crisis child A',
      );

      final record2 = ConductaRecord(
        recordId: 'filter-002',
        childId: 'child-B',
        userId: 'user-001',
        fecha: 'hoy',
        fechaNormalizada: '2024-11-15',
        tipo: 'crisis',
        descripcion: 'Crisis child B',
      );

      await storage.insertConductaRecord(record1);
      await storage.insertConductaRecord(record2);

      final recordsA = await storage.getConductaRecords(childId: 'child-A');
      final recordsB = await storage.getConductaRecords(childId: 'child-B');

      expect(recordsA.length, 1);
      expect(recordsA[0].childId, 'child-A');
      expect(recordsB.length, 1);
      expect(recordsB[0].childId, 'child-B');
    });
  });
}
