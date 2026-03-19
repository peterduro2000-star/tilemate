import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../services/tilemate_database.dart';

/// All persistence operations for [TilePreset].
class PresetRepository {
  PresetRepository._();
  static final PresetRepository instance = PresetRepository._();

  final _db = TileMateDatabase.instance;

  Future<List<TilePreset>> getAllPresets() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      TileMateDatabase.tablePresets,
      orderBy: 'created_at DESC',
    );
    return rows
        .map((r) => TilePreset.fromJson(r['json_data'] as String))
        .toList();
  }

  Future<TilePreset?> getPresetById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      TileMateDatabase.tablePresets,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return TilePreset.fromJson(rows.first['json_data'] as String);
  }

  Future<void> savePreset(TilePreset preset) async {
    final db = await _db.database;
    await db.insert(
      TileMateDatabase.tablePresets,
      {
        'id':             preset.id,
        'name':           preset.name,
        'tile_length':    preset.tileLength,
        'tile_width':     preset.tileWidth,
        'tile_unit':      preset.tileUnit.name,
        'price_per_tile': preset.pricePerTile,
        'tiles_per_box':  preset.tilesPerBox,
        'box_price':      preset.boxPrice,
        'brand':          preset.brand,
        'product_code':   preset.productCode,
        'notes':          preset.notes,
        'created_at':     preset.createdAt.toIso8601String(),
        'json_data':      preset.toJson(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePreset(String id) async {
    final db = await _db.database;
    await db.delete(
      TileMateDatabase.tablePresets,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderPresets(List<TilePreset> presets) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < presets.length; i++) {
        final fakeDate = DateTime(2099).subtract(Duration(seconds: i));
        await txn.update(
          TileMateDatabase.tablePresets,
          {'created_at': fakeDate.toIso8601String()},
          where: 'id = ?',
          whereArgs: [presets[i].id],
        );
      }
    });
  }
}