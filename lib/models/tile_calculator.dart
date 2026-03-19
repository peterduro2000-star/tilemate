import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import 'enums.dart';
import 'room_section.dart';
import 'tile_calculation.dart';

/// Pure calculation engine. No Flutter dependencies — fully testable.
///
/// Usage:
/// ```dart
/// final result = TileCalculator.calculate(input: TileCalculatorInput(...));
/// ```
class TileCalculator {
  TileCalculator._(); // static-only

  static const _uuid = Uuid();

  static TileCalculation calculate({required TileCalculatorInput input}) {
    // ── 1. Net floor area ────────────────────────────────────────────────────
    final floorArea = _netFloorArea(input.sections, input.roomUnit);

    // ── 2. Effective tile size (cm → m, including grout joint) ───────────────
    final tileLengthM = _tileLengthInMeters(
      input.tileLength,
      input.tileUnit,
      input.groutJointMm,
    );
    final tileWidthM = _tileWidthInMeters(
      input.tileWidth,
      input.tileUnit,
      input.groutJointMm,
    );
    final effectiveTileAreaM2 = tileLengthM * tileWidthM;

    // ── 3. Base tiles needed ─────────────────────────────────────────────────
    final baseTiles = floorArea / effectiveTileAreaM2;

    // ── 4. Wastage ───────────────────────────────────────────────────────────
    final patternWastage = input.layoutPattern.baseWastagePercent;
    final totalWastage = patternWastage + input.extraBufferPercent;
    final totalTilesExact = baseTiles * (1 + totalWastage / 100);
    final tilesNeeded = baseTiles.ceil();
    final wasteTiles = (baseTiles * totalWastage / 100).ceil();
    final totalTilesRequired = tilesNeeded + wasteTiles;

    // ── 5. Box purchasing ────────────────────────────────────────────────────
    final tilesPerBox = input.tilesPerBox < 1 ? 1 : input.tilesPerBox;
    final boxesRequired = (totalTilesRequired / tilesPerBox).ceil();
    final spareTiles = (boxesRequired * tilesPerBox) - totalTilesRequired;
    final coverageM2 = boxesRequired * tilesPerBox * effectiveTileAreaM2;

    // ── 6. Estimated cut tiles (perimeter-based heuristic) ───────────────────
    final estimatedCutTiles = _estimateCutTiles(
      sections: input.sections,
      roomUnit: input.roomUnit,
      tileLengthM: tileLengthM,
      tileWidthM: tileWidthM,
      pattern: input.layoutPattern,
    );

    // ── 7. Costs ─────────────────────────────────────────────────────────────
    final effectivePricePerTile = input.boxPrice != null && tilesPerBox > 0
        ? input.boxPrice! / tilesPerBox
        : input.pricePerTile;

    final tileCost = boxesRequired *
        (input.boxPrice ?? (input.pricePerTile * tilesPerBox));

    final laborCost =
        (input.laborCostPerM2 * floorArea) + input.laborFlatCost;

    final groutBags = input.groutBagCoverage != null && input.groutBagCoverage! > 0
        ? (floorArea / input.groutBagCoverage!).ceil()
        : 0;
    final groutCost = (input.groutBagPrice ?? 0.0) * groutBags;

    final totalCost = tileCost + laborCost + groutCost + input.otherCost;

    // ── 8. Build result ──────────────────────────────────────────────────────
    return TileCalculation(
      id: input.id ?? _uuid.v4(),
      date: input.date ?? DateTime.now(),
      projectId: input.projectId,
      roomName: input.roomName,
      sections: input.sections,
      roomUnit: input.roomUnit,
      tileLength: input.tileLength,
      tileWidth: input.tileWidth,
      tileUnit: input.tileUnit,
      groutJointMm: input.groutJointMm,
      layoutPattern: input.layoutPattern,
      presetId: input.presetId,
      pricePerTile: input.pricePerTile,
      tilesPerBox: tilesPerBox,
      boxPrice: input.boxPrice,
      laborCostPerM2: input.laborCostPerM2,
      laborFlatCost: input.laborFlatCost,
      otherCost: input.otherCost,
      currency: input.currency,
      patternWastagePercent: patternWastage,
      extraBufferPercent: input.extraBufferPercent,
      groutColor: input.groutColor,
      groutBagCoverage: input.groutBagCoverage,
      groutBagPrice: input.groutBagPrice,
      // calculated
      floorArea: floorArea,
      effectiveTileAreaM2: effectiveTileAreaM2,
      tilesNeeded: tilesNeeded,
      wasteTiles: wasteTiles,
      totalTilesRequired: totalTilesRequired,
      boxesRequired: boxesRequired,
      spareTiles: spareTiles,
      tileCost: tileCost,
      laborCost: laborCost,
      groutCost: groutCost,
      totalCost: totalCost,
      estimatedCutTiles: estimatedCutTiles,
      coverageM2: coverageM2,
    );
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  /// Convert all sections to m² and sum (subtractions are negative)
  static double _netFloorArea(
    List<RoomSection> sections,
    RoomUnit roomUnit,
  ) {
    double total = 0.0;
    for (final section in sections) {
      final lengthM = _toMeters(section.length, roomUnit);
      final widthM = _toMeters(section.width, roomUnit);
      final area = lengthM * widthM;
      total += section.isSubtracted ? -area : area;
    }
    return total.clamp(0.0, double.infinity);
  }

  static double _toMeters(double value, RoomUnit unit) {
    return unit == RoomUnit.feet ? value * 0.3048 : value;
  }

  /// Tile length in metres including one grout joint
  static double _tileLengthInMeters(
    double length,
    TileUnit unit,
    double groutJointMm,
  ) {
    final lengthCm = unit == TileUnit.inches ? length * 2.54 : length;
    return (lengthCm / 100) + (groutJointMm / 1000);
  }

  /// Tile width in metres including one grout joint
  static double _tileWidthInMeters(
    double width,
    TileUnit unit,
    double groutJointMm,
  ) {
    final widthCm = unit == TileUnit.inches ? width * 2.54 : width;
    return (widthCm / 100) + (groutJointMm / 1000);
  }

  /// Heuristic: estimate how many tiles will need cutting on the borders.
  /// Based on room perimeter and tile size, adjusted for pattern.
  static int _estimateCutTiles({
    required List<RoomSection> sections,
    required RoomUnit roomUnit,
    required double tileLengthM,
    required double tileWidthM,
    required LayoutPattern pattern,
  }) {
    // Use the largest non-subtracted section for the perimeter heuristic
    final mainSection = sections
        .where((s) => !s.isSubtracted)
        .fold<RoomSection?>(null, (best, s) {
      if (best == null) return s;
      return s.area > best.area ? s : best;
    });

    if (mainSection == null) return 0;

    final lengthM = _toMeters(mainSection.length, roomUnit);
    final widthM = _toMeters(mainSection.width, roomUnit);

    final perimeterTilesLength = (lengthM / tileLengthM).ceil();
    final perimeterTilesWidth = (widthM / tileWidthM).ceil();

    // Two sides each direction, minus corners counted twice
    int cuts = 2 * perimeterTilesLength + 2 * perimeterTilesWidth - 4;

    // Diagonal/herringbone roughly doubles border cuts
    if (pattern == LayoutPattern.diagonal ||
        pattern == LayoutPattern.herringbone) {
      cuts = (cuts * 1.8).round();
    }

    return cuts.clamp(0, 9999);
  }
}

/// All inputs required to perform a tile calculation.
/// Keeps [TileCalculation] as a pure result type.
class TileCalculatorInput {
  final String? id;
  final DateTime? date;
  final String? projectId;
  final String roomName;
  final List<RoomSection> sections;
  final RoomUnit roomUnit;
  final double tileLength;
  final double tileWidth;
  final TileUnit tileUnit;
  final double groutJointMm;
  final LayoutPattern layoutPattern;
  final String? presetId;
  final double pricePerTile;
  final int tilesPerBox;
  final double? boxPrice;
  final double laborCostPerM2;
  final double laborFlatCost;
  final double otherCost;
  final Currency currency;
  final double extraBufferPercent;
  final String? groutColor;
  final double? groutBagCoverage;
  final double? groutBagPrice;

  const TileCalculatorInput({
    this.id,
    this.date,
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
    this.extraBufferPercent = 0.0,
    this.groutColor,
    this.groutBagCoverage,
    this.groutBagPrice,
  });

  /// Quick constructor for a simple single-rectangle room
  factory TileCalculatorInput.simpleRoom({
    String? id,
    DateTime? date,
    String? projectId,
    String roomName = 'Room',
    required double roomLength,
    required double roomWidth,
    RoomUnit roomUnit = RoomUnit.meters,
    required double tileLength,
    required double tileWidth,
    TileUnit tileUnit = TileUnit.centimeters,
    double groutJointMm = 3.0,
    LayoutPattern layoutPattern = LayoutPattern.straight,
    String? presetId,
    required double pricePerTile,
    int tilesPerBox = 1,
    double? boxPrice,
    double laborCostPerM2 = 0.0,
    double laborFlatCost = 0.0,
    double otherCost = 0.0,
    Currency currency = Currency.usd,
    double extraBufferPercent = 0.0,
    String? groutColor,
    double? groutBagCoverage,
    double? groutBagPrice,
  }) {
    return TileCalculatorInput(
      id: id,
      date: date,
      projectId: projectId,
      roomName: roomName,
      sections: [
        RoomSection(
          id: 'main',
          label: 'Main area',
          length: roomLength,
          width: roomWidth,
        )
      ],
      roomUnit: roomUnit,
      tileLength: tileLength,
      tileWidth: tileWidth,
      tileUnit: tileUnit,
      groutJointMm: groutJointMm,
      layoutPattern: layoutPattern,
      presetId: presetId,
      pricePerTile: pricePerTile,
      tilesPerBox: tilesPerBox,
      boxPrice: boxPrice,
      laborCostPerM2: laborCostPerM2,
      laborFlatCost: laborFlatCost,
      otherCost: otherCost,
      currency: currency,
      extraBufferPercent: extraBufferPercent,
      groutColor: groutColor,
      groutBagCoverage: groutBagCoverage,
      groutBagPrice: groutBagPrice,
    );
  }
}