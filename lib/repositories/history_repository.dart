import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../services/tilemate_database.dart';

/// Persists standalone (non-project) calculations as a history log.
/// Auto-trims to the last [maxHistoryItems] entries.
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  final _db = TileMateDatabase.instance;

  static const int maxHistoryItems = 50;

  Future<List<TileCalculation>> getHistory({int limit = 30}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      TileMateDatabase.tableHistory,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows
        .map((r) => TileCalculation.fromJson(r['json_data'] as String))
        .toList();
  }

  Future<int> getCount() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${TileMateDatabase.tableHistory}',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> addToHistory(TileCalculation calc) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        TileMateDatabase.tableHistory,
        {
          'id':         calc.id,
          'room_name':  calc.roomName,
          'floor_area': calc.floorArea,
          'total_cost': calc.totalCost,
          'currency':   calc.currency.name,
          'created_at': calc.date.toIso8601String(),
          'json_data':  calc.toJson(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.rawDelete('''
        DELETE FROM ${TileMateDatabase.tableHistory}
        WHERE id NOT IN (
          SELECT id FROM ${TileMateDatabase.tableHistory}
          ORDER BY created_at DESC
          LIMIT $maxHistoryItems
        )
      ''');
    });
  }

  Future<void> deleteEntry(String id) async {
    final db = await _db.database;
    await db.delete(
      TileMateDatabase.tableHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearHistory() async {
    final db = await _db.database;
    await db.delete(TileMateDatabase.tableHistory);
  }
}