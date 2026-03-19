/// Unit system for room dimensions
enum RoomUnit { meters, feet }

/// Unit system for tile dimensions
enum TileUnit { centimeters, inches }

/// Tile layout/laying pattern
enum LayoutPattern {
  straight,
  diagonal,
  herringbone,
  brick,
  versailles,
}

/// Currency options
enum Currency {
  usd,
  gbp,
  eur,
  kes,
  ngn,
  zar,
  ghs,
  ugx,
  tzs,
  inr,
  aud,
  cad,
}

extension LayoutPatternExtension on LayoutPattern {
  String get displayName {
    switch (this) {
      case LayoutPattern.straight:
        return 'Straight Lay';
      case LayoutPattern.diagonal:
        return 'Diagonal / 45°';
      case LayoutPattern.herringbone:
        return 'Herringbone';
      case LayoutPattern.brick:
        return 'Brick / Offset';
      case LayoutPattern.versailles:
        return 'Versailles';
    }
  }

  /// Base wastage percentage recommended for this pattern
  double get baseWastagePercent {
    switch (this) {
      case LayoutPattern.straight:
        return 5.0;
      case LayoutPattern.diagonal:
        return 15.0;
      case LayoutPattern.herringbone:
        return 20.0;
      case LayoutPattern.brick:
        return 10.0;
      case LayoutPattern.versailles:
        return 15.0;
    }
  }

  String get description {
    switch (this) {
      case LayoutPattern.straight:
        return 'Classic grid alignment. Lowest waste (~5%).';
      case LayoutPattern.diagonal:
        return 'Tiles set at 45°. More cuts needed (~15% waste).';
      case LayoutPattern.herringbone:
        return 'V-shaped zigzag. High cut count (~20% waste).';
      case LayoutPattern.brick:
        return 'Staggered rows like brickwork (~10% waste).';
      case LayoutPattern.versailles:
        return 'Mixed-size pattern. Complex cuts (~15% waste).';
    }
  }
}

extension CurrencyExtension on Currency {
  String get symbol {
    switch (this) {
      case Currency.usd:
        return '\$';
      case Currency.gbp:
        return '£';
      case Currency.eur:
        return '€';
      case Currency.kes:
        return 'KSh';
      case Currency.ngn:
        return '₦';
      case Currency.zar:
        return 'R';
      case Currency.ghs:
        return 'GH₵';
      case Currency.ugx:
        return 'USh';
      case Currency.tzs:
        return 'TSh';
      case Currency.inr:
        return '₹';
      case Currency.aud:
        return 'A\$';
      case Currency.cad:
        return 'C\$';
    }
  }

  String get code {
    return name.toUpperCase();
  }

  String get displayName => '$code (${symbol})';
}

extension RoomUnitExtension on RoomUnit {
  String get label => this == RoomUnit.meters ? 'm' : 'ft';
}

extension TileUnitExtension on TileUnit {
  String get label => this == TileUnit.centimeters ? 'cm' : 'in';
}