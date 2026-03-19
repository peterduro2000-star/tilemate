import 'dart:convert';
import 'enums.dart';

/// A saved tile configuration the tiler reuses across jobs.
/// e.g. "600×600 Porcelain Matt, $3.20/tile, 6 per box"
class TilePreset {
  final String id;
  final String name;              // e.g. "600×600 Porcelain Matt"
  final double tileLength;        // stored in cm
  final double tileWidth;         // stored in cm
  final TileUnit tileUnit;
  final double pricePerTile;
  final int tilesPerBox;
  final double? boxPrice;         // optional: price per box (overrides pricePerTile * tilesPerBox)
  final String? brand;
  final String? productCode;
  final String? notes;
  final DateTime createdAt;

  const TilePreset({
    required this.id,
    required this.name,
    required this.tileLength,
    required this.tileWidth,
    this.tileUnit = TileUnit.centimeters,
    required this.pricePerTile,
    this.tilesPerBox = 1,
    this.boxPrice,
    this.brand,
    this.productCode,
    this.notes,
    required this.createdAt,
  });

  /// Effective price per tile (box price takes precedence when set)
  double get effectivePricePerTile {
    if (boxPrice != null && tilesPerBox > 0) {
      return boxPrice! / tilesPerBox;
    }
    return pricePerTile;
  }

  /// Tile length in cm regardless of input unit
  double get lengthInCm {
    if (tileUnit == TileUnit.inches) return tileLength * 2.54;
    return tileLength;
  }

  /// Tile width in cm regardless of input unit
  double get widthInCm {
    if (tileUnit == TileUnit.inches) return tileWidth * 2.54;
    return tileWidth;
  }

  TilePreset copyWith({
    String? id,
    String? name,
    double? tileLength,
    double? tileWidth,
    TileUnit? tileUnit,
    double? pricePerTile,
    int? tilesPerBox,
    double? boxPrice,
    String? brand,
    String? productCode,
    String? notes,
    DateTime? createdAt,
  }) {
    return TilePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      tileLength: tileLength ?? this.tileLength,
      tileWidth: tileWidth ?? this.tileWidth,
      tileUnit: tileUnit ?? this.tileUnit,
      pricePerTile: pricePerTile ?? this.pricePerTile,
      tilesPerBox: tilesPerBox ?? this.tilesPerBox,
      boxPrice: boxPrice ?? this.boxPrice,
      brand: brand ?? this.brand,
      productCode: productCode ?? this.productCode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'tileLength': tileLength,
        'tileWidth': tileWidth,
        'tileUnit': tileUnit.name,
        'pricePerTile': pricePerTile,
        'tilesPerBox': tilesPerBox,
        'boxPrice': boxPrice,
        'brand': brand,
        'productCode': productCode,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TilePreset.fromMap(Map<String, dynamic> map) => TilePreset(
        id: map['id'] as String,
        name: map['name'] as String,
        tileLength: (map['tileLength'] as num).toDouble(),
        tileWidth: (map['tileWidth'] as num).toDouble(),
        tileUnit: TileUnit.values.firstWhere(
          (e) => e.name == map['tileUnit'],
          orElse: () => TileUnit.centimeters,
        ),
        pricePerTile: (map['pricePerTile'] as num).toDouble(),
        tilesPerBox: (map['tilesPerBox'] as int?) ?? 1,
        boxPrice: map['boxPrice'] != null
            ? (map['boxPrice'] as num).toDouble()
            : null,
        brand: map['brand'] as String?,
        productCode: map['productCode'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  String toJson() => json.encode(toMap());

  factory TilePreset.fromJson(String source) =>
      TilePreset.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'TilePreset($name, ${tileLength}×${tileWidth}${tileUnit.label}, \$$pricePerTile/tile)';
}