import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../services/tilemate_database.dart';

/// All persistence operations for [TileProject] and its child [TileCalculation] rooms.
class ProjectRepository {
  ProjectRepository._();
  static final ProjectRepository instance = ProjectRepository._();

  final _db = TileMateDatabase.instance;

  // ── Read ────────────────────────────────────────────────────────────────────

  Future<List<TileProject>> getAllProjects() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> projectRows = await db.query(
      TileMateDatabase.tableProjects,
      orderBy: 'created_at DESC',
    );
    final projects = <TileProject>[];
    for (final row in projectRows) {
      final rooms = await _getRoomsForProject(row['id'] as String, db);
      projects.add(_projectFromRow(row, rooms));
    }
    return projects;
  }

  Future<TileProject?> getProjectById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      TileMateDatabase.tableProjects,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final rooms = await _getRoomsForProject(id, db);
    return _projectFromRow(rows.first, rooms);
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  Future<void> saveProject(TileProject project) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert(
        TileMateDatabase.tableProjects,
        {
          'id':              project.id,
          'name':            project.name,
          'client_name':     project.clientName,
          'client_phone':    project.clientPhone,
          'client_email':    project.clientEmail,
          'site_address':    project.siteAddress,
          'notes':           project.notes,
          'currency':        project.currency.name,
          'status':          project.status.name,
          'created_at':      project.createdAt.toIso8601String(),
          'quote_date':      project.quoteDate?.toIso8601String(),
          'completion_date': project.completionDate?.toIso8601String(),
          'updated_at':      now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        TileMateDatabase.tableCalculations,
        where: 'project_id = ?',
        whereArgs: [project.id],
      );
      for (final room in project.rooms) {
        await txn.insert(
          TileMateDatabase.tableCalculations,
          _calcToRow(room, projectId: project.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateProjectMeta(TileProject project) async {
    final db = await _db.database;
    await db.update(
      TileMateDatabase.tableProjects,
      {
        'name':            project.name,
        'client_name':     project.clientName,
        'client_phone':    project.clientPhone,
        'client_email':    project.clientEmail,
        'site_address':    project.siteAddress,
        'notes':           project.notes,
        'currency':        project.currency.name,
        'status':          project.status.name,
        'quote_date':      project.quoteDate?.toIso8601String(),
        'completion_date': project.completionDate?.toIso8601String(),
        'updated_at':      DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> addRoomToProject(String projectId, TileCalculation room) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        TileMateDatabase.tableCalculations,
        _calcToRow(room, projectId: projectId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        TileMateDatabase.tableProjects,
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
  }

  Future<void> removeRoomFromProject(String projectId, String roomId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        TileMateDatabase.tableCalculations,
        where: 'id = ? AND project_id = ?',
        whereArgs: [roomId, projectId],
      );
      await txn.update(
        TileMateDatabase.tableProjects,
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
  }

  Future<void> deleteProject(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        TileMateDatabase.tableCalculations,
        where: 'project_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        TileMateDatabase.tableProjects,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<List<TileCalculation>> _getRoomsForProject(
      String projectId, dynamic db) async {
    final List<Map<String, dynamic>> rows = await db.query(
      TileMateDatabase.tableCalculations,
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at ASC',
    );
    return rows
        .map((r) => TileCalculation.fromJson(r['json_data'] as String))
        .toList();
  }

  TileProject _projectFromRow(
      Map<String, dynamic> row, List<TileCalculation> rooms) {
    return TileProject(
      id:             row['id'] as String,
      name:           row['name'] as String,
      clientName:     row['client_name'] as String?,
      clientPhone:    row['client_phone'] as String?,
      clientEmail:    row['client_email'] as String?,
      siteAddress:    row['site_address'] as String?,
      notes:          row['notes'] as String?,
      currency:       Currency.values.firstWhere(
        (e) => e.name == row['currency'],
        orElse: () => Currency.usd,
      ),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => ProjectStatus.draft,
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
      quoteDate: row['quote_date'] != null
          ? DateTime.parse(row['quote_date'] as String)
          : null,
      completionDate: row['completion_date'] != null
          ? DateTime.parse(row['completion_date'] as String)
          : null,
      rooms: rooms,
    );
  }

  Map<String, dynamic> _calcToRow(
    TileCalculation calc, {
    String? projectId,
  }) {
    return {
      'id':         calc.id,
      'project_id': projectId ?? calc.projectId,
      'room_name':  calc.roomName,
      'floor_area': calc.floorArea,
      'total_cost': calc.totalCost,
      'currency':   calc.currency.name,
      'created_at': calc.date.toIso8601String(),
      'json_data':  calc.toJson(),
    };
  }
}