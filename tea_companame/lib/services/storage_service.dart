import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/conducta_record.dart';
import '../models/message.dart';
import '../models/child_profile.dart';

class StorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tea_companame.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conducta_records (
            recordId TEXT PRIMARY KEY,
            childId TEXT NOT NULL,
            userId TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT 'auto',
            conversationId TEXT,
            fecha TEXT NOT NULL,
            fechaNormalizada TEXT NOT NULL,
            tipo TEXT NOT NULL,
            descripcion TEXT NOT NULL,
            intensidad TEXT DEFAULT 'no_especificada',
            duracion TEXT DEFAULT '',
            desencadenantes TEXT DEFAULT '[]',
            contexto TEXT DEFAULT '',
            estrategiasAplicadas TEXT DEFAULT '',
            resultado TEXT DEFAULT '',
            notas TEXT,
            confirmado INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            conductaRecordId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE child_profiles (
            childId TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            birthDate TEXT NOT NULL,
            diagnosis TEXT NOT NULL,
            diagnosisDate TEXT,
            communicationLevel TEXT DEFAULT 'frases',
            sensorySensitivities TEXT DEFAULT '[]',
            knownTriggers TEXT DEFAULT '[]',
            effectiveStrategies TEXT DEFAULT '[]',
            favoriteReinforcers TEXT DEFAULT '[]',
            avatar TEXT
          )
        ''');
      },
    );
  }

  // === ConductaRecords ===

  Future<void> insertConductaRecord(ConductaRecord record) async {
    try {
      final db = await database;
      await db.insert(
        'conducta_records',
        record.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('[StorageService] Error inserting record: $e');
    }
  }

  Future<List<ConductaRecord>> getConductaRecords({String? childId}) async {
    try {
      final db = await database;
      final where = childId != null ? 'childId = ?' : null;
      final whereArgs = childId != null ? [childId] : null;

      final results = await db.query(
        'conducta_records',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'createdAt DESC',
      );

      return results.map((json) {
        // Parsear desencadenantes de string JSON a List
        if (json['desencadenantes'] is String) {
          json['desencadenantes'] =
              jsonDecode(json['desencadenantes'] as String) as List;
        }
        return ConductaRecord.fromJson(json);
      }).toList();
    } catch (e) {
      print('[StorageService] Error reading records: $e');
      return [];
    }
  }

  Future<void> updateConductaRecord(ConductaRecord record) async {
    try {
      final db = await database;
      await db.update(
        'conducta_records',
        record.toJson(),
        where: 'recordId = ?',
        whereArgs: [record.recordId],
      );
    } catch (e) {
      print('[StorageService] Error updating record: $e');
    }
  }

  Future<void> deleteConductaRecord(String recordId) async {
    try {
      final db = await database;
      await db.delete(
        'conducta_records',
        where: 'recordId = ?',
        whereArgs: [recordId],
      );
    } catch (e) {
      print('[StorageService] Error deleting record: $e');
    }
  }

  // === Messages ===

  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getMessages({int limit = 50}) async {
    final db = await database;
    final results = await db.query(
      'messages',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return results.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  // === Child Profiles ===

  Future<void> insertChildProfile(ChildProfile profile) async {
    final db = await database;
    final json = profile.toJson();
    // Convertir listas a JSON string
    json['sensorySensitivities'] = jsonEncode(json['sensorySensitivities']);
    json['knownTriggers'] = jsonEncode(json['knownTriggers']);
    json['effectiveStrategies'] = jsonEncode(json['effectiveStrategies']);
    json['favoriteReinforcers'] = jsonEncode(json['favoriteReinforcers']);

    await db.insert(
      'child_profiles',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChildProfile>> getChildProfiles() async {
    final db = await database;
    final results = await db.query('child_profiles');
    return results.map((json) {
      // Parsear listas de string JSON
      if (json['sensorySensitivities'] is String) {
        json['sensorySensitivities'] =
            jsonDecode(json['sensorySensitivities'] as String) as List;
      }
      if (json['knownTriggers'] is String) {
        json['knownTriggers'] =
            jsonDecode(json['knownTriggers'] as String) as List;
      }
      if (json['effectiveStrategies'] is String) {
        json['effectiveStrategies'] =
            jsonDecode(json['effectiveStrategies'] as String) as List;
      }
      if (json['favoriteReinforcers'] is String) {
        json['favoriteReinforcers'] =
            jsonDecode(json['favoriteReinforcers'] as String) as List;
      }
      return ChildProfile.fromJson(json);
    }).toList();
  }

  Future<void> deleteChildProfile(String childId) async {
    final db = await database;
    await db.delete(
      'child_profiles',
      where: 'childId = ?',
      whereArgs: [childId],
    );
  }

  // === Utility ===

  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM conducta_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
