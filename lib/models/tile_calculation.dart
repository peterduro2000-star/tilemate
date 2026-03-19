import 'dart:convert';
import 'dart:math' as math;

import 'enums.dart';
import 'room_section.dart';

/// Full result of a tile calculation for one room.
/// Supports composite room shapes, grout joints, layout patterns, and box-based purchasing.
class TileCalculation {
  // ─── Identity ────────────────────────────────────────────────────────────────
  final String id;
  final DateTime date;
  final String? projectId; // belongs to a TileProject when set
  final String roomName;

  // ─── Room geometry ───────────────────────────────────────────────────────────
  /// All rectangular sections that make up this room.
  /// At least one section required. Sections with [RoomSection.isSubtracted] = true
  /// are deducted from the total area (pillars, bathtubs, kitchen islands, etc.)
  final List<RoomSection> sections;
  final RoomUnit roomUnit;

  // ─── Tile spec ───────────────────────────────────────────────────────────────
  final double tileLength; // stored in cm
  final double tileWidth;  // stored in cm
  final TileUnit tileUnit;
  final double groutJointMm; // grout gap between tiles in mm
  final LayoutPattern layoutPattern;
  final String? presetId; // references a TilePreset if one was used

  // ─── Pricing ─────────────────────────────────────────────────────────────────
  final double pricePerTile;
  final int tilesPerBox;
  final double? boxPrice;      // if set, used instead of pricePerTile × tilesPerBox
  final double laborCostPerM2; // labour charged per m² (more realistic than flat fee)
  final double laborFlatCost;  // optional flat labour fee
  final double otherCost;      // adhesive, sealer, delivery, etc.
  final Currency currency;

  // ─── Wastage ─────────────────────────────────────────────────────────────────
  final double patternWastagePercent;  // auto-set from layoutPattern
  final double extraBufferPercent;     // user-added buffer on top of pattern wastage

  // ─── Grout ───────────────────────────────────────────────────────────────────
  final String? groutColor;
  final double? groutBagCoverage; // m² per bag
  final double? groutBagPrice;

  // ─── Calculated outputs (set by TileCalculator) ───────────────────────────────
  final double floorArea;          // net m² (after subtractions)
  final double effectiveTileAreaM2; // single tile area including grout, in m²
  final int tilesNeeded;           // base tiles for the area
  final int wasteTiles;            // tiles lost to cuts/wastage
  final int totalTilesRequired;    // tilesNeeded + wasteTiles
  final int boxesRequired;         // ceil(totalTilesRequired / tilesPerBox)
  final int spareTiles;            // tiles left over from full boxes
  final double tileCost;           // cost of tiles only
  final double laborCost;          // total labour cost
  final double groutCost;          // total grout cost
  final double totalCost;          // grand total
  final int estimatedCutTiles;     // approx border cut tiles
  final double coverageM2;         // m² covered by purchased tiles (incl. spare)

  const TileCalculation({
    required this.id,
    required this.date,
    this.projectId,
    this.roomName = 'Room',
    required this.sections,
    this.roomUnit = RoomUnit.meters,
    required this.tileLength,
    required this.tileWidth,
    this.tileUnit = TileUnit.centimeters,
    this.groutJointMm = 3.0,
    this.layoutPattern = LayoutPattern.straight,
    this.presetId,
    required this.pricePerTile,
    this.tilesPerBox = 1,
    this.boxPrice,
    this.laborCostPerM2 = 0.0,
    this.laborFlatCost = 0.0,
    this.otherCost = 0.0,
    this.currency = Currency.usd,
    required this.patternWastagePercent,
    this.extraBufferPercent = 0.0,
    this.groutColor,
    this.groutBagCoverage,
    this.groutBagPrice,
    // calculated
    required this.floorArea,
    required this.effectiveTileAreaM2,
    required this.tilesNeeded,
    required this.wasteTiles,
    required this.totalTilesRequired,
    required this.boxesRequired,
    required this.spareTiles,
    required this.tileCost,
    required this.laborCost,
    required this.groutCost,
    required this.totalCost,
    required this.estimatedCutTiles,
    required this.coverageM2,
  });

  // ─── Convenience getters ─────────────────────────────────────────────────────

  double get totalWastagePercent => patternWastagePercent + extraBufferPercent;

  /// Price per box, falling back to pricePerTile × tilesPerBox
  double get effectiveBoxPrice => boxPrice ?? (pricePerTile * tilesPerBox);

  String get currencySymbol => currency.symbol;

  // ─── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'projectId': projectId,
        'roomName': roomName,
        'sections': sections.map((s) => s.toMap()).toList(),
        'roomUnit': roomUnit.name,
        'tileLength': tileLength,
        'tileWidth': tileWidth,
        'tileUnit': tileUnit.name,
        'groutJointMm': groutJointMm,
        'layoutPattern': layoutPattern.name,
        'presetId': presetId,
        'pricePerTile': pricePerTile,
        'tilesPerBox': tilesPerBox,
        'boxPrice': boxPrice,
        'laborCostPerM2': laborCostPerM2,
        'laborFlatCost': laborFlatCost,
        'otherCost': otherCost,
        'currency': currency.name,
        'patternWastagePercent': patternWastagePercent,
        'extraBufferPercent': extraBufferPercent,
        'groutColor': groutColor,
        'groutBagCoverage': groutBagCoverage,
        'groutBagPrice': groutBagPrice,
        // calculated
        'floorArea': floorArea,
        'effectiveTileAreaM2': effectiveTileAreaM2,
        'tilesNeeded': tilesNeeded,
        'wasteTiles': wasteTiles,
        'totalTilesRequired': totalTilesRequired,
        'boxesRequired': boxesRequired,
        'spareTiles': spareTiles,
        'tileCost': tileCost,
        'laborCost': laborCost,
        'groutCost': groutCost,
        'totalCost': totalCost,
        'estimatedCutTiles': estimatedCutTiles,
        'coverageM2': coverageM2,
      };

  factory TileCalculation.fromMap(Map<String, dynamic> map) {
    final sections = (map['sections'] as List<dynamic>?)
            ?.map((s) => RoomSection.fromMap(s as Map<String, dynamic>))
            .toList() ??
        // Legacy: reconstruct a single section from old roomLength/roomWidth fields
        _legacySections(map);

    return TileCalculation(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      projectId: map['projectId'] as String?,
      roomName: (map['roomName'] as String?) ?? 'Room',
      sections: sections,
      roomUnit: RoomUnit.values.firstWhere(
        (e) => e.name == map['roomUnit'],
        orElse: () => RoomUnit.meters,
      ),
      tileLength: (map['tileLength'] as num).toDouble(),
      tileWidth: (map['tileWidth'] as num).toDouble(),
      tileUnit: TileUnit.values.firstWhere(
        (e) => e.name == map['tileUnit'],
        orElse: () => TileUnit.centimeters,
      ),
      groutJointMm: (map['groutJointMm'] as num?)?.toDouble() ?? 3.0,
      layoutPattern: LayoutPattern.values.firstWhere(
        (e) => e.name == map['layoutPattern'],
        orElse: () => LayoutPattern.straight,
      ),
      presetId: map['presetId'] as String?,
      pricePerTile: (map['pricePerTile'] as num).toDouble(),
      tilesPerBox: (map['tilesPerBox'] as int?) ?? 1,
      boxPrice: map['boxPrice'] != null ? (map['boxPrice'] as num).toDouble() : null,
      laborCostPerM2: (map['laborCostPerM2'] as num?)?.toDouble() ?? 0.0,
      laborFlatCost: (map['laborFlatCost'] as num?)?.toDouble() ?? 0.0,
      otherCost: (map['otherCost'] as num?)?.toDouble() ?? 0.0,
      currency: Currency.values.firstWhere(
        (e) => e.name == map['currency'],
        orElse: () => Currency.usd,
      ),
      patternWastagePercent:
          (map['patternWastagePercent'] as num?)?.toDouble() ??
              (map['wastagePercentage'] as num?)?.toDouble() ??
              5.0,
      extraBufferPercent: (map['extraBufferPercent'] as num?)?.toDouble() ?? 0.0,
      groutColor: map['groutColor'] as String?,
      groutBagCoverage:
          map['groutBagCoverage'] != null ? (map['groutBagCoverage'] as num).toDouble() : null,
      groutBagPrice:
          map['groutBagPrice'] != null ? (map['groutBagPrice'] as num).toDouble() : null,
      floorArea: (map['floorArea'] as num).toDouble(),
      effectiveTileAreaM2: (map['effectiveTileAreaM2'] as num?)?.toDouble() ??
          _fallbackTileArea(map),
      tilesNeeded: map['tilesNeeded'] as int,
      wasteTiles: (map['wasteTiles'] as int?) ?? (map['extraTiles'] as int? ?? 0),
      totalTilesRequired: (map['totalTilesRequired'] as int?) ??
          ((map['tilesNeeded'] as int) + (map['extraTiles'] as int? ?? 0)),
      boxesRequired: (map['boxesRequired'] as int?) ?? (map['tilesNeeded'] as int),
      spareTiles: (map['spareTiles'] as int?) ?? 0,
      tileCost: (map['tileCost'] as num?)?.toDouble() ?? 0.0,
      laborCost: (map['laborCost'] as num?)?.toDouble() ?? 0.0,
      groutCost: (map['groutCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['totalCost'] as num).toDouble(),
      estimatedCutTiles: (map['estimatedCutTiles'] as int?) ?? 0,
      coverageM2: (map['coverageM2'] as num?)?.toDouble() ??
          (map['floorArea'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory TileCalculation.fromJson(String source) =>
      TileCalculation.fromMap(json.decode(source) as Map<String, dynamic>);

  // ─── Legacy migration helpers ─────────────────────────────────────────────────

  static List<RoomSection> _legacySections(Map<String, dynamic> map) {
    final l = (map['roomLength'] as num?)?.toDouble() ?? 1.0;
    final w = (map['roomWidth'] as num?)?.toDouble() ?? 1.0;
    return [
      RoomSection(
        id: 'legacy_main',
        label: 'Main area',
        length: l,
        width: w,
      )
    ];
  }

  static double _fallbackTileArea(Map<String, dynamic> map) {
    final l = (map['tileLength'] as num).toDouble() / 100;
    final w = (map['tileWidth'] as num).toDouble() / 100;
    return l * w;
  }

  @override
  String toString() =>
      'TileCalculation($roomName, ${floorArea.toStringAsFixed(2)}m², '
      '${totalTilesRequired} tiles, $boxesRequired boxes, '
      '${currency.symbol}${totalCost.toStringAsFixed(2)})';
}