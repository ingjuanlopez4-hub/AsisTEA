import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as p;
import '../models/conducta_record.dart';
import '../models/message.dart';
import '../models/child_profile.dart';
import '../models/api_config.dart';

/// Almacenamiento dual: SQLite en nativo, SharedPreferences en web.
class StorageService {
  final bool _useWeb = kIsWeb;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> _webSet(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<String?> _webGet(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<List<Map<String, dynamic>>> _webGetList(String key) async {
    final raw = await _webGet(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _webSetList(
      String key, List<Map<String, dynamic>> items) async {
    await _webSet(key, jsonEncode(items));
  }

  // ================================================================
  // API Config
  // ================================================================

  Future<void> saveApiConfig(ApiConfig config) async {
    if (_useWeb) {
      await _webSet('api_config', jsonEncode(config.toJson()));
    } else {
      try {
        final db = await _initNativeDb();
        await db.saveApiConfig(config);
      } catch (e) {
        print('[StorageService] Error saving API config: $e');
      }
    }
  }

  Future<ApiConfig> getApiConfig() async {
    if (_useWeb) {
      try {
        final raw = await _webGet('api_config');
        if (raw != null) {
          return ApiConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      } catch (e) {
        print('[StorageService] Error reading API config: $e');
      }
      return const ApiConfig();
    } else {
      try {
        final db = await _initNativeDb();
        return await db.getApiConfig();
      } catch (e) {
        print('[StorageService] Error reading API config: $e');
        return const ApiConfig();
      }
    }
  }

  // ================================================================
  // ConductaRecords
  // ================================================================

  Future<void> insertConductaRecord(ConductaRecord record) async {
    if (_useWeb) {
      final items = await _webGetList('conducta_records');
      items.add(record.toJson());
      await _webSetList('conducta_records', items);
    } else {
      try {
        final db = await _initNativeDb();
        await db.insertConductaRecord(record);
      } catch (e) {
        print('[StorageService] Error inserting record: $e');
      }
    }
  }

  Future<List<ConductaRecord>> getConductaRecords({String? childId}) async {
    if (_useWeb) {
      final items = await _webGetList('conducta_records');
      var records = items.map((json) {
        if (json['desencadenantes'] is String) {
          json['desencadenantes'] =
              jsonDecode(json['desencadenantes'] as String) as List;
        }
        return ConductaRecord.fromJson(json);
      }).toList();

      if (childId != null) {
        records = records.where((r) => r.childId == childId).toList();
      }

      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } else {
      try {
        final db = await _initNativeDb();
        return await db.getConductaRecords(childId: childId);
      } catch (e) {
        print('[StorageService] Error reading records: $e');
        return [];
      }
    }
  }

  Future<void> updateConductaRecord(ConductaRecord record) async {
    if (_useWeb) {
      final items = await _webGetList('conducta_records');
      final index = items.indexWhere((j) => j['recordId'] == record.recordId);
      if (index != -1) {
        items[index] = record.toJson();
        await _webSetList('conducta_records', items);
      }
    } else {
      try {
        final db = await _initNativeDb();
        await db.updateConductaRecord(record);
      } catch (e) {
        print('[StorageService] Error updating record: $e');
      }
    }
  }

  Future<void> deleteConductaRecord(String recordId) async {
    if (_useWeb) {
      final items = await _webGetList('conducta_records');
      items.removeWhere((j) => j['recordId'] == recordId);
      await _webSetList('conducta_records', items);
    } else {
      try {
        final db = await _initNativeDb();
        await db.deleteConductaRecord(recordId);
      } catch (e) {
        print('[StorageService] Error deleting record: $e');
      }
    }
  }

  // ================================================================
  // Messages
  // ================================================================

  Future<void> insertMessage(ChatMessage message) async {
    if (_useWeb) {
      final items = await _webGetList('messages');
      items.add(message.toJson());
      await _webSetList('messages', items);
    } else {
      final db = await _initNativeDb();
      await db.insertMessage(message);
    }
  }

  Future<List<ChatMessage>> getMessages({int limit = 50}) async {
    if (_useWeb) {
      final items = await _webGetList('messages');
      items.sort((a, b) =>
          (a['timestamp'] as String).compareTo(b['timestamp'] as String));
      final limited =
          items.length > limit ? items.sublist(items.length - limit) : items;
      return limited.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      final db = await _initNativeDb();
      return await db.getMessages(limit: limit);
    }
  }

  Future<void> clearMessages() async {
    if (_useWeb) {
      await _webSetList('messages', []);
    } else {
      final db = await _initNativeDb();
      await db.clearMessages();
    }
  }

  // ================================================================
  // Child Profiles
  // ================================================================

  Future<void> insertChildProfile(ChildProfile profile) async {
    if (_useWeb) {
      final items = await _webGetList('child_profiles');
      final json = profile.toJson();
      json['sensorySensitivities'] = jsonEncode(json['sensorySensitivities']);
      json['knownTriggers'] = jsonEncode(json['knownTriggers']);
      json['effectiveStrategies'] = jsonEncode(json['effectiveStrategies']);
      json['favoriteReinforcers'] = jsonEncode(json['favoriteReinforcers']);
      final index = items.indexWhere((j) => j['childId'] == profile.childId);
      if (index != -1) {
        items[index] = json;
      } else {
        items.add(json);
      }
      await _webSetList('child_profiles', items);
    } else {
      final db = await _initNativeDb();
      await db.insertChildProfile(profile);
    }
  }

  Future<List<ChildProfile>> getChildProfiles() async {
    if (_useWeb) {
      final items = await _webGetList('child_profiles');
      return items.map((json) {
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
    } else {
      final db = await _initNativeDb();
      return await db.getChildProfiles();
    }
  }

  Future<void> deleteChildProfile(String childId) async {
    if (_useWeb) {
      final items = await _webGetList('child_profiles');
      items.removeWhere((j) => j['childId'] == childId);
      await _webSetList('child_profiles', items);
    } else {
      final db = await _initNativeDb();
      await db.deleteChildProfile(childId);
    }
  }

  // ================================================================
  // Utility & Metrics
  // ================================================================

  Future<int> getRecordCount() async {
    if (_useWeb) {
      final items = await _webGetList('conducta_records');
      return items.length;
    } else {
      final db = await _initNativeDb();
      return await db.getRecordCount();
    }
  }

  /// Retorna registros dentro de un rango de fechas.
  Future<List<ConductaRecord>> getRecordsByDateRange({
    required DateTime from,
    required DateTime to,
    String? childId,
  }) async {
    if (_useWeb) {
      final all = await getConductaRecords(childId: childId);
      return all.where((r) {
        final d = r.createdAt;
        return !d.isBefore(from) && !d.isAfter(to);
      }).toList();
    } else {
      final db = await _initNativeDb();
      return await db.getRecordsByDateRange(from: from, to: to, childId: childId);
    }
  }

  /// Conteo de registros por tipo en un período.
  Future<Map<String, int>> getRecordCountByType({
    DateTime? from,
    DateTime? to,
    String? childId,
  }) async {
    if (_useWeb) {
      final all = await getConductaRecords(childId: childId);
      var filtered = all;
      if (from != null) filtered = filtered.where((r) => !r.createdAt.isBefore(from)).toList();
      if (to != null) filtered = filtered.where((r) => !r.createdAt.isAfter(to)).toList();
      final map = <String, int>{};
      for (final r in filtered) {
        map[r.tipo] = (map[r.tipo] ?? 0) + 1;
      }
      return map;
    } else {
      final db = await _initNativeDb();
      return await db.getRecordCountByType(from: from, to: to, childId: childId);
    }
  }

  /// Obtiene los desencadenantes más frecuentes.
  Future<List<MapEntry<String, int>>> getTopTriggers({int limit = 10}) async {
    final records = await getConductaRecords();
    final freq = <String, int>{};
    for (final r in records) {
      for (final t in r.desencadenantes) {
        final key = t.trim().toLowerCase();
        if (key.isNotEmpty) {
          freq[key] = (freq[key] ?? 0) + 1;
        }
      }
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Obtiene conteo de crisis por semana (últimas N semanas).
  Future<List<Map<String, dynamic>>> getCrisisByWeek({int weeks = 6}) async {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday - i * 7 + 1);
      final weekEnd = weekStart.add(const Duration(days: 7));

      final records = await getRecordsByDateRange(from: weekStart, to: weekEnd);
      final crisis = records.where((r) => r.tipo == 'crisis').length;

      result.add({
        'weekLabel': 'S${weeks - i}',
        'count': crisis,
        'startDate': weekStart,
      });
    }

    return result;
  }

  // ================================================================
  // Native DB initialization (lazy)
  // ================================================================

  DatabaseHelper? _nativeDb;

  Future<DatabaseHelper> _initNativeDb() async {
    _nativeDb ??= DatabaseHelper();
    await _nativeDb!.database;
    return _nativeDb!;
  }
}

// ================================================================
// Native: SQLite backend
// ================================================================

class DatabaseHelper {
  sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    final path = p.join(dbPath, 'tea_companame.db');

    return sql.openDatabase(
      path,
      version: 2,
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

        await db.execute('''
          CREATE TABLE api_config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS api_config (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  // API Config
  Future<void> saveApiConfig(ApiConfig config) async {
    final db = await database;
    await db.insert(
      'api_config',
      {'key': 'llm_config', 'value': jsonEncode(config.toJson())},
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<ApiConfig> getApiConfig() async {
    final db = await database;
    final results = await db.query(
      'api_config',
      where: 'key = ?',
      whereArgs: ['llm_config'],
    );
    if (results.isNotEmpty) {
      return ApiConfig.fromJson(
        jsonDecode(results.first['value'] as String) as Map<String, dynamic>,
      );
    }
    return const ApiConfig();
  }

  // ConductaRecords
  Future<void> insertConductaRecord(ConductaRecord record) async {
    final db = await database;
    await db.insert(
      'conducta_records',
      record.toJson(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<List<ConductaRecord>> getConductaRecords({String? childId}) async {
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
      if (json['desencadenantes'] is String) {
        json['desencadenantes'] =
            jsonDecode(json['desencadenantes'] as String) as List;
      }
      return ConductaRecord.fromJson(json);
    }).toList();
  }

  Future<void> updateConductaRecord(ConductaRecord record) async {
    final db = await database;
    await db.update(
      'conducta_records',
      record.toJson(),
      where: 'recordId = ?',
      whereArgs: [record.recordId],
    );
  }

  Future<void> deleteConductaRecord(String recordId) async {
    final db = await database;
    await db.delete(
      'conducta_records',
      where: 'recordId = ?',
      whereArgs: [recordId],
    );
  }

  // Messages
  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toJson(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
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

  // Child Profiles
  Future<void> insertChildProfile(ChildProfile profile) async {
    final db = await database;
    final json = profile.toJson();
    json['sensorySensitivities'] = jsonEncode(json['sensorySensitivities']);
    json['knownTriggers'] = jsonEncode(json['knownTriggers']);
    json['effectiveStrategies'] = jsonEncode(json['effectiveStrategies']);
    json['favoriteReinforcers'] = jsonEncode(json['favoriteReinforcers']);

    await db.insert(
      'child_profiles',
      json,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<List<ChildProfile>> getChildProfiles() async {
    final db = await database;
    final results = await db.query('child_profiles');
    return results.map((json) {
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

  // Utility
  Future<int> getRecordCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM conducta_records');
    return sql.Sqflite.firstIntValue(result) ?? 0;
  }

  // Metrics
  Future<List<ConductaRecord>> getRecordsByDateRange({
    required DateTime from,
    required DateTime to,
    String? childId,
  }) async {
    final db = await database;
    String where = 'createdAt >= ? AND createdAt <= ?';
    List<dynamic> whereArgs = [from.toIso8601String(), to.toIso8601String()];
    if (childId != null) {
      where += ' AND childId = ?';
      whereArgs.add(childId);
    }
    final results = await db.query(
      'conducta_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );
    return results.map((json) {
      if (json['desencadenantes'] is String) {
        json['desencadenantes'] = jsonDecode(json['desencadenantes'] as String) as List;
      }
      return ConductaRecord.fromJson(json);
    }).toList();
  }

  Future<Map<String, int>> getRecordCountByType({
    DateTime? from,
    DateTime? to,
    String? childId,
  }) async {
    final db = await database;
    String query = 'SELECT tipo, COUNT(*) as cnt FROM conducta_records WHERE 1=1';
    final args = <dynamic>[];
    if (from != null) { query += ' AND createdAt >= ?'; args.add(from.toIso8601String()); }
    if (to != null) { query += ' AND createdAt <= ?'; args.add(to.toIso8601String()); }
    if (childId != null) { query += ' AND childId = ?'; args.add(childId); }
    query += ' GROUP BY tipo';
    final results = await db.rawQuery(query, args);
    final map = <String, int>{};
    for (final r in results) {
      map[r['tipo'] as String] = r['cnt'] as int;
    }
    return map;
  }
}
