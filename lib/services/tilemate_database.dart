import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Central SQLite database manager for TileMate.
/// Single instance, handles schema creation and migrations.
class TileMateDatabase {
  TileMateDatabase._();
  static final TileMateDatabase instance = TileMateDatabase._();

  static Database? _db;

  static const _dbName    = 'tilemate.db';
  static const _dbVersion = 1;

  // ── Table names ────────────────────────────────────────────────────────────
  static const tableProjects     = 'projects';
  static const tableCalculations = 'calculations';
  static const tablePresets      = 'tile_presets';
  static const tableHistory      = 'calculation_history';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // ── Projects ──────────────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE $tableProjects (
          id            TEXT PRIMARY KEY,
          name          TEXT NOT NULL,
          client_name   TEXT,
          client_phone  TEXT,
          client_email  TEXT,
          site_address  TEXT,
          notes         TEXT,
          currency      TEXT NOT NULL DEFAULT 'usd',
          status        TEXT NOT NULL DEFAULT 'draft',
          created_at    TEXT NOT NULL,
          quote_date    TEXT,
          completion_date TEXT,
          updated_at    TEXT NOT NULL
        )
      ''');

      // ── Calculations (rooms) ───────────────────────────────────────────────
      // Stored as a JSON blob — model already has toJson/fromJson
      await txn.execute('''
        CREATE TABLE $tableCalculations (
          id            TEXT PRIMARY KEY,
          project_id    TEXT REFERENCES $tableProjects(id) ON DELETE CASCADE,
          room_name     TEXT NOT NULL,
          floor_area    REAL NOT NULL,
          total_cost    REAL NOT NULL,
          currency      TEXT NOT NULL DEFAULT 'usd',
          created_at    TEXT NOT NULL,
          json_data     TEXT NOT NULL
        )
      ''');

      // ── Tile presets ───────────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE $tablePresets (
          id              TEXT PRIMARY KEY,
          name            TEXT NOT NULL,
          tile_length     REAL NOT NULL,
          tile_width      REAL NOT NULL,
          tile_unit       TEXT NOT NULL DEFAULT 'centimeters',
          price_per_tile  REAL NOT NULL,
          tiles_per_box   INTEGER NOT NULL DEFAULT 1,
          box_price       REAL,
          brand           TEXT,
          product_code    TEXT,
          notes           TEXT,
          created_at      TEXT NOT NULL,
          json_data       TEXT NOT NULL
        )
      ''');

      // ── Standalone calculation history ─────────────────────────────────────
      // Calculations done outside a project (quick estimates)
      await txn.execute('''
        CREATE TABLE $tableHistory (
          id            TEXT PRIMARY KEY,
          room_name     TEXT NOT NULL,
          floor_area    REAL NOT NULL,
          total_cost    REAL NOT NULL,
          currency      TEXT NOT NULL DEFAULT 'usd',
          created_at    TEXT NOT NULL,
          json_data     TEXT NOT NULL
        )
      ''');

      // ── Indices ────────────────────────────────────────────────────────────
      await txn.execute(
        'CREATE INDEX idx_calculations_project ON $tableCalculations(project_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_history_created ON $tableHistory(created_at DESC)',
      );
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here, e.g.:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  /// Wipe all data — used in tests or a "Reset App" settings option.
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableHistory);
      await txn.delete(tableCalculations);
      await txn.delete(tablePresets);
      await txn.delete(tableProjects);
    });
  }

  /// Close the database connection (call on app dispose if needed).
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}