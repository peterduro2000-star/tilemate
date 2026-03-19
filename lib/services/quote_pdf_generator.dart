import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

// ─── Colour palette (mirrors AppTheme) ────────────────────────────────────────

const _bg        = PdfColor.fromInt(0xFF0F0F0F);
const _surface   = PdfColor.fromInt(0xFF1A1A1A);
const _surfaceAlt= PdfColor.fromInt(0xFF242424);
const _border    = PdfColor.fromInt(0xFF2E2E2E);
const _amber     = PdfColor.fromInt(0xFFF5A623);
const _amberDark = PdfColor.fromInt(0xFFB87A14);
const _textHigh  = PdfColor.fromInt(0xFFF0EDE8);
const _textMid   = PdfColor.fromInt(0xFF9A9590);
const _textLow   = PdfColor.fromInt(0xFF5C5855);
const _success   = PdfColor.fromInt(0xFF4CAF6E);
const _error     = PdfColor.fromInt(0xFFE05252);
const _info      = PdfColor.fromInt(0xFF5B9FE0);

/// Generates PDF quotes for a single room calculation or a full project.
///
/// Usage:
/// ```dart
/// // Single room
/// final bytes = await QuotePdfGenerator.singleRoom(calculation: calc);
/// await Printing.sharePdf(bytes: bytes, filename: 'TileMate_Quote.pdf');
///
/// // Full project
/// final bytes = await QuotePdfGenerator.project(project: proj);
/// await Printing.layoutPdf(onLayout: (_) async => bytes);
/// ```
class QuotePdfGenerator {
  QuotePdfGenerator._();

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Build a single-room estimate PDF.
  static Future<Uint8List> singleRoom({
    required TileCalculation calculation,
    String? companyName,
    String? companyPhone,
    String? companyEmail,
  }) async {
    final doc = pw.Document(
      title: 'TileMate – ${calculation.roomName}',
      author: companyName ?? 'TileMate',
    );

    final fonts = await _loadFonts();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => [
          _PageWrapper(
            fonts: fonts,
            companyName: companyName,
            companyPhone: companyPhone,
            companyEmail: companyEmail,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _HeroHeader(
                  fonts: fonts,
                  title: calculation.roomName,
                  subtitle: _fmtDate(calculation.date),
                  totalLabel: 'TOTAL ESTIMATE',
                  totalValue: _fmtCurrency(
                      calculation.totalCost, calculation.currency),
                  meta:
                      '${calculation.floorArea.toStringAsFixed(2)} m²  ·  ${calculation.layoutPattern.displayName}  ·  ${calculation.boxesRequired} boxes',
                ),
                pw.SizedBox(height: 20),
                _TileSpecSection(
                    fonts: fonts, calculation: calculation),
                pw.SizedBox(height: 16),
                _TileCountSection(
                    fonts: fonts, calculation: calculation),
                pw.SizedBox(height: 16),
                _CostBreakdownSection(
                    fonts: fonts, calculation: calculation),
                if (calculation.groutColor != null ||
                    calculation.groutCost > 0) ...[
                  pw.SizedBox(height: 16),
                  _GroutSection(
                      fonts: fonts, calculation: calculation),
                ],
                pw.SizedBox(height: 16),
                _WastageSection(
                    fonts: fonts, calculation: calculation),
                pw.SizedBox(height: 16),
                _RoomShapeSection(
                    fonts: fonts, calculation: calculation),
                pw.SizedBox(height: 24),
                _Footer(fonts: fonts),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Build a full multi-room project quote PDF.
  static Future<Uint8List> project({
    required TileProject project,
    String? companyName,
    String? companyPhone,
    String? companyEmail,
  }) async {
    final doc = pw.Document(
      title: 'TileMate – ${project.name}',
      author: companyName ?? 'TileMate',
    );

    final fonts = await _loadFonts();

    // Page 1: project cover + summary
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => [
          _PageWrapper(
            fonts: fonts,
            companyName: companyName,
            companyPhone: companyPhone,
            companyEmail: companyEmail,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _HeroHeader(
                  fonts: fonts,
                  title: project.name,
                  subtitle: project.clientName != null
                      ? 'For ${project.clientName}'
                      : _fmtDate(project.createdAt),
                  totalLabel: 'GRAND TOTAL',
                  totalValue: _fmtCurrency(
                      project.grandTotal, project.currency),
                  meta:
                      '${project.roomCount} rooms  ·  ${project.totalFloorArea.toStringAsFixed(1)} m²  ·  ${project.totalBoxesRequired} boxes',
                  statusLabel: project.status.displayName,
                ),
                pw.SizedBox(height: 20),

                // Client info
                if (project.clientName != null ||
                    project.siteAddress != null)
                  _ClientSection(fonts: fonts, project: project),

                pw.SizedBox(height: 16),
                _ProjectSummarySection(
                    fonts: fonts, project: project),
                pw.SizedBox(height: 16),
                _ProjectRoomListSection(
                    fonts: fonts, project: project),
                pw.SizedBox(height: 24),
                _Footer(fonts: fonts),
              ],
            ),
          ),
        ],
      ),
    );

    // Additional pages: one per room
    for (final room in project.rooms) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) => [
            _PageWrapper(
              fonts: fonts,
              companyName: companyName,
              companyPhone: companyPhone,
              companyEmail: companyEmail,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Room sub-header
                  pw.Container(
                    color: _surfaceAlt,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            room.roomName,
                            style: pw.TextStyle(
                              font: fonts.bold,
                              fontSize: 18,
                              color: _textHigh,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        pw.Text(
                          _fmtCurrency(room.totalCost, room.currency),
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: 18,
                            color: _amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _TileSpecSection(fonts: fonts, calculation: room),
                        pw.SizedBox(height: 16),
                        _TileCountSection(
                            fonts: fonts, calculation: room),
                        pw.SizedBox(height: 16),
                        _CostBreakdownSection(
                            fonts: fonts, calculation: room),
                        if (room.groutColor != null || room.groutCost > 0) ...[
                          pw.SizedBox(height: 16),
                          _GroutSection(fonts: fonts, calculation: room),
                        ],
                        pw.SizedBox(height: 16),
                        _WastageSection(fonts: fonts, calculation: room),
                        pw.SizedBox(height: 16),
                        _RoomShapeSection(
                            fonts: fonts, calculation: room),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  _Footer(fonts: fonts),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return doc.save();
  }

  // ── Font loading ─────────────────────────────────────────────────────────────

  static Future<_Fonts> _loadFonts() async {
    final regular = await PdfGoogleFonts.interRegular();
    final medium = await PdfGoogleFonts.interMedium();
    final semiBold = await PdfGoogleFonts.interSemiBold();
    final bold = await PdfGoogleFonts.interBold();
    final extraBold = await PdfGoogleFonts.interExtraBold();
    return _Fonts(
      regular: regular,
      medium: medium,
      semiBold: semiBold,
      bold: bold,
      extraBold: extraBold,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _fmtCurrency(double value, Currency currency) {
    return NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
    ).format(value);
  }

  static String _fmtDate(DateTime dt) =>
      DateFormat('d MMMM yyyy').format(dt);
}

// ─── Font bundle ──────────────────────────────────────────────────────────────

class _Fonts {
  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font bold;
  final pw.Font extraBold;

  const _Fonts({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.bold,
    required this.extraBold,
  });
}

// ─── Page wrapper (outer chrome) ──────────────────────────────────────────────

class _PageWrapper extends pw.StatelessWidget {
  final _Fonts fonts;
  final pw.Widget child;
  final String? companyName;
  final String? companyPhone;
  final String? companyEmail;

  _PageWrapper({
    required this.fonts,
    required this.child,
    this.companyName,
    this.companyPhone,
    this.companyEmail,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      color: _bg,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Top brand bar
          pw.Container(
            color: _surface,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 32, vertical: 10),
            child: pw.Row(
              children: [
                // TILEMATE wordmark
                pw.Row(
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: const pw.BoxDecoration(
                        color: _amber,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      'TILEMATE',
                      style: pw.TextStyle(
                        font: fonts.extraBold,
                        fontSize: 11,
                        color: _amber,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                // Company info
                if (companyName != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        companyName!,
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 10,
                          color: _textHigh,
                        ),
                      ),
                      if (companyPhone != null)
                        pw.Text(
                          companyPhone!,
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 9,
                              color: _textMid),
                        ),
                      if (companyEmail != null)
                        pw.Text(
                          companyEmail!,
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 9,
                              color: _textMid),
                        ),
                    ],
                  )
                else
                  pw.Text(
                    'Professional Tile Calculator',
                    style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 9,
                        color: _textMid),
                  ),
              ],
            ),
          ),
          // Page content
          child,
        ],
      ),
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────

class _HeroHeader extends pw.StatelessWidget {
  final _Fonts fonts;
  final String title;
  final String subtitle;
  final String totalLabel;
  final String totalValue;
  final String meta;
  final String? statusLabel;

  _HeroHeader({
    required this.fonts,
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.totalValue,
    required this.meta,
    this.statusLabel,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_bg, PdfColor.fromInt(0xFF1A1500)],
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
        ),
      ),
      padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (statusLabel != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: _amber.shade(0.15),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(
                          color: _amber.shade(0.5), width: 0.5),
                    ),
                    child: pw.Text(
                      statusLabel!.toUpperCase(),
                      style: pw.TextStyle(
                        font: fonts.extraBold,
                        fontSize: 8,
                        color: _amber,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                ],
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: fonts.extraBold,
                    fontSize: 26,
                    color: _textHigh,
                    letterSpacing: -0.8,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 11,
                      color: _textMid),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  meta,
                  style: pw.TextStyle(
                      font: fonts.medium,
                      fontSize: 10,
                      color: _textLow),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          // Total box
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _surface,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: _amber, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  totalLabel,
                  style: pw.TextStyle(
                    font: fonts.extraBold,
                    fontSize: 8,
                    color: _textLow,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  totalValue,
                  style: pw.TextStyle(
                    font: fonts.extraBold,
                    fontSize: 22,
                    color: _amber,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

pw.Widget _sectionHeader(String label, _Fonts fonts) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              font: fonts.extraBold,
              fontSize: 9,
              color: _textLow,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Divider(color: _border, thickness: 0.5),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

// ─── Key-value row ────────────────────────────────────────────────────────────

pw.Widget _kvRow(String label, String value, _Fonts fonts,
    {PdfColor? valueColor}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
                font: fonts.regular, fontSize: 10, color: _textMid),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 10,
            color: valueColor ?? _textHigh,
          ),
        ),
      ],
    ),
  );
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────

pw.Widget _card({required pw.Widget child, bool highlight = false}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: _surface,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      border: pw.Border.all(
        color: highlight ? _amber : _border,
        width: highlight ? 1 : 0.5,
      ),
    ),
    padding: const pw.EdgeInsets.all(14),
    child: child,
  );
}

// ─── Tile spec section ────────────────────────────────────────────────────────

class _TileSpecSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileCalculation calculation;

  _TileSpecSection({required this.fonts, required this.calculation});

  @override
  pw.Widget build(pw.Context context) {
    final c = calculation;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Tile & Room Spec', fonts),
        _card(
          child: pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(children: [
                      _kvRow('Floor area',
                          '${c.floorArea.toStringAsFixed(2)} m²', fonts),
                      _kvRow(
                          'Tile size',
                          '${c.tileLength.toStringAsFixed(0)} × ${c.tileWidth.toStringAsFixed(0)} ${c.tileUnit.label}',
                          fonts),
                      _kvRow('Grout joint',
                          '${c.groutJointMm.toStringAsFixed(1)} mm', fonts),
                    ]),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(children: [
                      _kvRow('Pattern',
                          c.layoutPattern.displayName, fonts),
                      _kvRow(
                          'Effective tile area',
                          '${(c.effectiveTileAreaM2 * 10000).toStringAsFixed(1)} cm²',
                          fonts),
                      _kvRow('Coverage',
                          '${c.coverageM2.toStringAsFixed(2)} m²',
                          fonts),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tile count section ───────────────────────────────────────────────────────

class _TileCountSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileCalculation calculation;

  _TileCountSection({required this.fonts, required this.calculation});

  @override
  pw.Widget build(pw.Context context) {
    final c = calculation;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Tiles Required', fonts),
        pw.Row(
          children: [
            _StatBox(
                label: 'Floor Tiles',
                value: '${c.tilesNeeded}',
                fonts: fonts),
            pw.SizedBox(width: 8),
            _StatBox(
                label: 'Waste',
                value: '+${c.wasteTiles}',
                fonts: fonts,
                valueColor: _textMid),
            pw.SizedBox(width: 8),
            _StatBox(
                label: 'Total Tiles',
                value: '${c.totalTilesRequired}',
                fonts: fonts,
                valueColor: _amber),
            pw.SizedBox(width: 8),
            _StatBox(
                label: 'Boxes',
                value: '${c.boxesRequired}',
                fonts: fonts,
                valueColor: _amber),
            pw.SizedBox(width: 8),
            _StatBox(
                label: 'Spare',
                value: '${c.spareTiles}',
                fonts: fonts,
                valueColor: _success),
            pw.SizedBox(width: 8),
            _StatBox(
                label: 'Cut Tiles',
                value: '~${c.estimatedCutTiles}',
                fonts: fonts,
                valueColor: _info),
          ],
        ),
        if (c.spareTiles > 0) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _success.shade(0.08),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                  color: _success.shade(0.3), width: 0.5),
            ),
            child: pw.Text(
              '${c.spareTiles} spare tile${c.spareTiles != 1 ? 's' : ''} left over from full boxes — keep for future repairs.',
              style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 9,
                  color: _success),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Cost breakdown section ───────────────────────────────────────────────────

class _CostBreakdownSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileCalculation calculation;

  _CostBreakdownSection({required this.fonts, required this.calculation});

  @override
  pw.Widget build(pw.Context context) {
    final c = calculation;
    final fmt = (double v) =>
        NumberFormat.currency(symbol: c.currency.symbol, decimalDigits: 2)
            .format(v);

    final rows = [
      ('Tiles (${c.boxesRequired} × ${c.tilesPerBox}/box)', c.tileCost),
      ('Labour', c.laborCost),
      if (c.groutCost > 0) ('Grout', c.groutCost),
      if (c.otherCost > 0) ('Other costs', c.otherCost),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Cost Breakdown', fonts),
        _card(
          highlight: true,
          child: pw.Column(
            children: [
              ...rows.map((r) => _kvRow(r.$1, fmt(r.$2), fonts)),
              pw.SizedBox(height: 6),
              pw.Divider(color: _border, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        font: fonts.extraBold,
                        fontSize: 12,
                        color: _textHigh,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  pw.Text(
                    fmt(c.totalCost),
                    style: pw.TextStyle(
                      font: fonts.extraBold,
                      fontSize: 16,
                      color: _amber,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${fmt(c.totalCost / c.floorArea)} per m²',
                  style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 8,
                      color: _textLow),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Grout section ────────────────────────────────────────────────────────────

class _GroutSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileCalculation calculation;

  _GroutSection({required this.fonts, required this.calculation});

  @override
  pw.Widget build(pw.Context context) {
    final c = calculation;
    int bags = 0;
    if (c.groutBagCoverage != null && c.groutBagCoverage! > 0) {
      bags = (c.floorArea / c.groutBagCoverage!).ceil();
    }
    final fmt = (double v) =>
        NumberFormat.currency(symbol: c.currency.symbol, decimalDigits: 2)
            .format(v);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Grout', fonts),
        _card(
          child: pw.Column(children: [
            if (c.groutColor != null)
              _kvRow('Colour', c.groutColor!, fonts),
            if (bags > 0) _kvRow('Bags needed', '$bags bags', fonts),
            if (c.groutCost > 0)
              _kvRow('Grout cost', fmt(c.groutCost), fonts,
                  valueColor: _amber),
          ]),
        ),
      ],
    );
  }
}

// ─── Wastage section ──────────────────────────────────────────────────────────

class _WastageSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileCalculation calculation;

  _WastageSection({required this.fonts, required this.calculation});

  @override
  pw.Widget build(pw.Context context) {
    final c = calculation;
    final patternFrac =
        (c.patternWastagePercent / 30.0).clamp(0.0, 1.0);
    final totalFrac =
        (c.totalWastagePercent / 30.0).clamp(0.0, 1.0);
    const barH = 6.0;
    const barW = 200.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Wastage', fonts),
        _card(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(children: [
                      _kvRow(
                          'Pattern (${c.layoutPattern.displayName})',
                          '${c.patternWastagePercent.toStringAsFixed(0)}%',
                          fonts),
                      _kvRow('Extra buffer',
                          '+${c.extraBufferPercent.toStringAsFixed(0)}%',
                          fonts),
                    ]),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _amber.shade(0.1),
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(
                            font: fonts.extraBold,
                            fontSize: 8,
                            color: _textLow,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.Text(
                          '${c.totalWastagePercent.toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                            font: fonts.extraBold,
                            fontSize: 20,
                            color: _amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              // Wastage bar
              pw.Stack(
                children: [
                  pw.Container(
                    width: barW,
                    height: barH,
                    decoration: pw.BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3)),
                    ),
                  ),
                  pw.Container(
                    width: barW * totalFrac,
                    height: barH,
                    decoration: pw.BoxDecoration(
                      color: _amber.shade(0.4),
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3)),
                    ),
                  ),
                  pw.Container(
                    width: barW * patternFrac,
                    height: barH,
                    decoration: pw.BoxDecoration(
                      color: _amber,
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3)),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  _LegendDot(color: _amber, label: 'Pattern', fonts: fonts),
                  pw.SizedBox(width: 12),
                  _LegendDot(
                      color: _amber.shade(0.4),
                      label: 'Buffer',
                      fonts: fonts),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Room shape section ───────────────────────────────────────────────────────

class _RoomShapeSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileCalculation calculation;

  _RoomShapeSection({required this.fonts, required this.calculation});

  @override
  pw.Widget build(pw.Context context) {
    final sections = calculation.sections;
    final unit = calculation.roomUnit;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('Room Sections', fonts),
        _card(
          child: pw.Column(
            children: sections.map((s) {
              final lm =
                  unit == RoomUnit.feet ? s.length * 0.3048 : s.length;
              final wm =
                  unit == RoomUnit.feet ? s.width * 0.3048 : s.width;
              final area = lm * wm;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: s.isSubtracted ? _error : _success,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        s.label,
                        style: pw.TextStyle(
                            font: fonts.medium,
                            fontSize: 10,
                            color: _textMid),
                      ),
                    ),
                    pw.Text(
                      '${s.length} × ${s.width} ${unit.label}',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 10,
                          color: s.isSubtracted ? _error : _textHigh),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Text(
                      '${s.isSubtracted ? '−' : ''}${area.toStringAsFixed(2)} m²',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 10,
                        color: s.isSubtracted ? _error : _textMid,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Client section ───────────────────────────────────────────────────────────

class _ClientSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileProject project;

  _ClientSection({required this.fonts, required this.project});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Client', fonts),
          _card(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(children: [
                    if (project.clientName != null)
                      _kvRow('Name', project.clientName!, fonts),
                    if (project.clientPhone != null)
                      _kvRow('Phone', project.clientPhone!, fonts),
                    if (project.clientEmail != null)
                      _kvRow('Email', project.clientEmail!, fonts),
                  ]),
                ),
                if (project.siteAddress != null)
                  pw.Expanded(
                    child: _kvRow(
                        'Site', project.siteAddress!, fonts),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Project summary section ──────────────────────────────────────────────────

class _ProjectSummarySection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileProject project;

  _ProjectSummarySection({required this.fonts, required this.project});

  @override
  pw.Widget build(pw.Context context) {
    final fmt = (double v) => NumberFormat.currency(
          symbol: project.currencySymbol,
          decimalDigits: 2,
        ).format(v);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Project Summary', fonts),
          pw.Row(
            children: [
              _StatBox(
                  label: 'Rooms',
                  value: '${project.roomCount}',
                  fonts: fonts),
              pw.SizedBox(width: 8),
              _StatBox(
                  label: 'Total Area',
                  value: '${project.totalFloorArea.toStringAsFixed(1)}m²',
                  fonts: fonts),
              pw.SizedBox(width: 8),
              _StatBox(
                  label: 'Total Boxes',
                  value: '${project.totalBoxesRequired}',
                  fonts: fonts,
                  valueColor: _amber),
              pw.SizedBox(width: 8),
              _StatBox(
                  label: 'Tile Cost',
                  value: NumberFormat.compactCurrency(
                          symbol: project.currencySymbol)
                      .format(project.totalTileCost),
                  fonts: fonts),
              pw.SizedBox(width: 8),
              _StatBox(
                  label: 'Labour',
                  value: NumberFormat.compactCurrency(
                          symbol: project.currencySymbol)
                      .format(project.totalLaborCost),
                  fonts: fonts),
              pw.SizedBox(width: 8),
              _StatBox(
                  label: 'Grand Total',
                  value: NumberFormat.compactCurrency(
                          symbol: project.currencySymbol)
                      .format(project.grandTotal),
                  fonts: fonts,
                  valueColor: _amber),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Project room list ────────────────────────────────────────────────────────

class _ProjectRoomListSection extends pw.StatelessWidget {
  final _Fonts fonts;
  final TileProject project;

  _ProjectRoomListSection({required this.fonts, required this.project});

  @override
  pw.Widget build(pw.Context context) {
    final sym = project.currencySymbol;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              '${project.roomCount} Room${project.roomCount != 1 ? 's' : ''}',
              fonts),
          _card(
            child: pw.Column(
              children: [
                // Table header
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: _border, width: 0.5)),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    children: [
                      _th('Room', fonts, flex: 3),
                      _th('Area', fonts),
                      _th('Tile', fonts),
                      _th('Boxes', fonts),
                      _th('Total', fonts, align: pw.TextAlign.right),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                // Rows
                ...project.rooms.map((room) {
                  final cost = NumberFormat.currency(
                          symbol: sym, decimalDigits: 2)
                      .format(room.totalCost);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        _td(room.roomName, fonts, flex: 3, bold: true),
                        _td('${room.floorArea.toStringAsFixed(1)} m²',
                            fonts),
                        _td(
                            '${room.tileLength.toStringAsFixed(0)}×${room.tileWidth.toStringAsFixed(0)}${room.tileUnit.label}',
                            fonts),
                        _td('${room.boxesRequired}', fonts),
                        _td(cost, fonts,
                            align: pw.TextAlign.right,
                            color: _amber),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 6),
                pw.Divider(color: _border, thickness: 0.5),
                pw.SizedBox(height: 6),
                // Grand total row
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'GRAND TOTAL',
                        style: pw.TextStyle(
                          font: fonts.extraBold,
                          fontSize: 11,
                          color: _textHigh,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    pw.Text(
                      NumberFormat.currency(
                              symbol: sym, decimalDigits: 2)
                          .format(project.grandTotal),
                      style: pw.TextStyle(
                        font: fonts.extraBold,
                        fontSize: 14,
                        color: _amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _th(String text, _Fonts fonts,
      {int flex = 1, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text.toUpperCase(),
        textAlign: align,
        style: pw.TextStyle(
          font: fonts.extraBold,
          fontSize: 8,
          color: _textLow,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  pw.Widget _td(String text, _Fonts fonts,
      {int flex = 1,
      bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
      PdfColor? color}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: bold ? fonts.bold : fonts.regular,
          fontSize: 10,
          color: color ?? _textHigh,
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends pw.StatelessWidget {
  final _Fonts fonts;
  _Footer({required this.fonts});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.fromLTRB(32, 10, 32, 14),
      child: pw.Row(
        children: [
          pw.Text(
            'Generated by TileMate  ·  ${DateFormat('d MMM yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
                font: fonts.regular, fontSize: 8, color: _textLow),
          ),
          pw.Spacer(),
          pw.Text(
            'Estimates only. Verify quantities before ordering.',
            style: pw.TextStyle(
                font: fonts.regular, fontSize: 8, color: _textLow),
          ),
        ],
      ),
    );
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends pw.StatelessWidget {
  final String label;
  final String value;
  final _Fonts fonts;
  final PdfColor? valueColor;

  _StatBox({
    required this.label,
    required this.value,
    required this.fonts,
    this.valueColor,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _surfaceAlt,
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: _border, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                font: fonts.extraBold,
                fontSize: 7,
                color: _textLow,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.extraBold,
                fontSize: 14,
                color: valueColor ?? _textHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend dot ───────────────────────────────────────────────────────────────

class _LegendDot extends pw.StatelessWidget {
  final PdfColor color;
  final String label;
  final _Fonts fonts;

  _LegendDot({
    required this.color,
    required this.label,
    required this.fonts,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          color: color,
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
              font: fonts.regular, fontSize: 8, color: _textLow),
        ),
      ],
    );
  }
}