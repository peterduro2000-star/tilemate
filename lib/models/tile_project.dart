import 'dart:convert';

import 'enums.dart';
import 'tile_calculation.dart';

/// A project groups multiple room calculations into one job/quote.
/// Tilers can total up costs across rooms and generate a single client PDF.
class TileProject {
  final String id;
  final String name;           // e.g. "Johnson Bathroom Reno"
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? siteAddress;
  final DateTime createdAt;
  final DateTime? quoteDate;
  final DateTime? completionDate;
  final String? notes;
  final Currency currency;
  final List<TileCalculation> rooms;
  final ProjectStatus status;

  const TileProject({
    required this.id,
    required this.name,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.siteAddress,
    required this.createdAt,
    this.quoteDate,
    this.completionDate,
    this.notes,
    this.currency = Currency.usd,
    this.rooms = const [],
    this.status = ProjectStatus.draft,
  });

  // ─── Aggregated getters ───────────────────────────────────────────────────────

  /// Total floor area across all rooms in m²
  double get totalFloorArea =>
      rooms.fold(0.0, (sum, r) => sum + r.floorArea);

  /// Total number of tiles required across all rooms
  int get totalTilesRequired =>
      rooms.fold(0, (sum, r) => sum + r.totalTilesRequired);

  /// Total number of boxes across all rooms
  int get totalBoxesRequired =>
      rooms.fold(0, (sum, r) => sum + r.boxesRequired);

  /// Total tile cost only
  double get totalTileCost =>
      rooms.fold(0.0, (sum, r) => sum + r.tileCost);

  /// Total labour cost
  double get totalLaborCost =>
      rooms.fold(0.0, (sum, r) => sum + r.laborCost);

  /// Total grout cost
  double get totalGroutCost =>
      rooms.fold(0.0, (sum, r) => sum + r.groutCost);

  /// Total other/miscellaneous costs
  double get totalOtherCost =>
      rooms.fold(0.0, (sum, r) => sum + r.otherCost);

  /// Grand total across all rooms
  double get grandTotal =>
      rooms.fold(0.0, (sum, r) => sum + r.totalCost);

  /// Currency symbol (from first room, or default)
  String get currencySymbol =>
      rooms.isNotEmpty ? rooms.first.currency.symbol : currency.symbol;

  int get roomCount => rooms.length;

  bool get isEmpty => rooms.isEmpty;

  // ─── Mutation helpers (returns new instance — immutable pattern) ──────────────

  TileProject addRoom(TileCalculation room) => copyWith(
        rooms: [...rooms, room],
      );

  TileProject removeRoom(String roomId) => copyWith(
        rooms: rooms.where((r) => r.id != roomId).toList(),
      );

  TileProject replaceRoom(TileCalculation updated) => copyWith(
        rooms: rooms.map((r) => r.id == updated.id ? updated : r).toList(),
      );

  TileProject copyWith({
    String? id,
    String? name,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? siteAddress,
    DateTime? createdAt,
    DateTime? quoteDate,
    DateTime? completionDate,
    String? notes,
    Currency? currency,
    List<TileCalculation>? rooms,
    ProjectStatus? status,
  }) {
    return TileProject(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      siteAddress: siteAddress ?? this.siteAddress,
      createdAt: createdAt ?? this.createdAt,
      quoteDate: quoteDate ?? this.quoteDate,
      completionDate: completionDate ?? this.completionDate,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      rooms: rooms ?? this.rooms,
      status: status ?? this.status,
    );
  }

  // ─── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientEmail': clientEmail,
        'siteAddress': siteAddress,
        'createdAt': createdAt.toIso8601String(),
        'quoteDate': quoteDate?.toIso8601String(),
        'completionDate': completionDate?.toIso8601String(),
        'notes': notes,
        'currency': currency.name,
        'rooms': rooms.map((r) => r.toMap()).toList(),
        'status': status.name,
      };

  factory TileProject.fromMap(Map<String, dynamic> map) => TileProject(
        id: map['id'] as String,
        name: map['name'] as String,
        clientName: map['clientName'] as String?,
        clientPhone: map['clientPhone'] as String?,
        clientEmail: map['clientEmail'] as String?,
        siteAddress: map['siteAddress'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        quoteDate: map['quoteDate'] != null
            ? DateTime.parse(map['quoteDate'] as String)
            : null,
        completionDate: map['completionDate'] != null
            ? DateTime.parse(map['completionDate'] as String)
            : null,
        notes: map['notes'] as String?,
        currency: Currency.values.firstWhere(
          (e) => e.name == map['currency'],
          orElse: () => Currency.usd,
        ),
        rooms: (map['rooms'] as List<dynamic>?)
                ?.map((r) =>
                    TileCalculation.fromMap(r as Map<String, dynamic>))
                .toList() ??
            [],
        status: ProjectStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ProjectStatus.draft,
        ),
      );

  String toJson() => json.encode(toMap());

  factory TileProject.fromJson(String source) =>
      TileProject.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'TileProject($name, $roomCount rooms, $currencySymbol${grandTotal.toStringAsFixed(2)})';
}

enum ProjectStatus {
  draft,
  quoted,
  accepted,
  inProgress,
  completed,
  cancelled,
}

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.quoted:
        return 'Quoted';
      case ProjectStatus.accepted:
        return 'Accepted';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }
}
