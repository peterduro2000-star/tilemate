import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';
import 'results_screen.dart';
import 'room_sections_screen.dart';
import 'presets_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final TileCalculation? existing;

  const CalculatorScreen({super.key, this.existing});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Room
  final _roomNameCtrl = TextEditingController(text: 'Room');
  List<RoomSection> _sections = [
    const RoomSection(id: 'main', label: 'Main area', length: 0, width: 0),
  ];
  RoomUnit _roomUnit = RoomUnit.meters;

  // Tile
  final _tileLengthCtrl = TextEditingController();
  final _tileWidthCtrl = TextEditingController();
  TileUnit _tileUnit = TileUnit.centimeters;
  double _groutMm = 3.0;
  LayoutPattern _pattern = LayoutPattern.straight;

  // Pricing
  final _pricePerTileCtrl = TextEditingController();
  final _tilesPerBoxCtrl = TextEditingController(text: '1');
  final _boxPriceCtrl = TextEditingController();
  final _laborPerM2Ctrl = TextEditingController(text: '0');
  final _laborFlatCtrl = TextEditingController(text: '0');
  final _otherCostCtrl = TextEditingController(text: '0');
  Currency _currency = Currency.ngn;
  bool _useBoxPrice = false;

  // Wastage
  double _extraBuffer = 0.0;

  // Grout
  final _groutColorCtrl = TextEditingController();
  final _groutCoverageCtrl = TextEditingController();
  final _groutBagPriceCtrl = TextEditingController();
  bool _showGroutSection = false;

  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    if (widget.existing != null) _prefill(widget.existing!);
  }

  void _prefill(TileCalculation c) {
    _roomNameCtrl.text = c.roomName;
    _sections = List.from(c.sections);
    _roomUnit = c.roomUnit;
    _tileLengthCtrl.text = c.tileLength.toString();
    _tileWidthCtrl.text = c.tileWidth.toString();
    _tileUnit = c.tileUnit;
    _groutMm = c.groutJointMm;
    _pattern = c.layoutPattern;
    _pricePerTileCtrl.text = c.pricePerTile.toString();
    _tilesPerBoxCtrl.text = c.tilesPerBox.toString();
    _currency = c.currency;
    _laborPerM2Ctrl.text = c.laborCostPerM2.toString();
    _laborFlatCtrl.text = c.laborFlatCost.toString();
    _otherCostCtrl.text = c.otherCost.toString();
    _extraBuffer = c.extraBufferPercent;
    if (c.groutColor != null) {
      _groutColorCtrl.text = c.groutColor!;
      _showGroutSection = true;
    }
  }

  /// Called when the tiler picks a preset from the Tiles tab.
  void _applyPreset(TilePreset preset) {
    setState(() {
      _tileLengthCtrl.text = preset.tileLength.toString();
      _tileWidthCtrl.text  = preset.tileWidth.toString();
      _tileUnit            = preset.tileUnit;
      _pricePerTileCtrl.text = preset.pricePerTile.toString();
      _tilesPerBoxCtrl.text  = preset.tilesPerBox.toString();
      if (preset.boxPrice != null) {
        _useBoxPrice       = true;
        _boxPriceCtrl.text = preset.boxPrice!.toString();
      } else {
        _useBoxPrice = false;
        _boxPriceCtrl.clear();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${preset.name} applied')),
    );
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _roomNameCtrl.dispose();
    _tileLengthCtrl.dispose();
    _tileWidthCtrl.dispose();
    _pricePerTileCtrl.dispose();
    _tilesPerBoxCtrl.dispose();
    _boxPriceCtrl.dispose();
    _laborPerM2Ctrl.dispose();
    _laborFlatCtrl.dispose();
    _otherCostCtrl.dispose();
    _groutColorCtrl.dispose();
    _groutCoverageCtrl.dispose();
    _groutBagPriceCtrl.dispose();
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text) ?? 0.0;
  int _i(TextEditingController c) => int.tryParse(c.text) ?? 1;

  bool get _sectionsValid =>
      _sections.every((s) => s.length > 0 && s.width > 0) &&
      _sections.any((s) => !s.isSubtracted);

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (!_sectionsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set room dimensions first.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final input = TileCalculatorInput(
      roomName: _roomNameCtrl.text.trim().isEmpty
          ? 'Room'
          : _roomNameCtrl.text.trim(),
      sections: _sections,
      roomUnit: _roomUnit,
      tileLength: _d(_tileLengthCtrl),
      tileWidth: _d(_tileWidthCtrl),
      tileUnit: _tileUnit,
      groutJointMm: _groutMm,
      layoutPattern: _pattern,
      pricePerTile: _d(_pricePerTileCtrl),
      tilesPerBox: _i(_tilesPerBoxCtrl),
      boxPrice: _useBoxPrice && _boxPriceCtrl.text.isNotEmpty
          ? _d(_boxPriceCtrl)
          : null,
      laborCostPerM2: _d(_laborPerM2Ctrl),
      laborFlatCost: _d(_laborFlatCtrl),
      otherCost: _d(_otherCostCtrl),
      currency: _currency,
      extraBufferPercent: _extraBuffer,
      groutColor: _groutColorCtrl.text.trim().isEmpty
          ? null
          : _groutColorCtrl.text.trim(),
      groutBagCoverage: _groutCoverageCtrl.text.isEmpty
          ? null
          : _d(_groutCoverageCtrl),
      groutBagPrice: _groutBagPriceCtrl.text.isEmpty
          ? null
          : _d(_groutBagPriceCtrl),
    );

    final result = TileCalculator.calculate(input: input);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultsScreen(calculation: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bg,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                          color: AppTheme.amber, shape: BoxShape.circle),
                    ),
                    const Text('TILEMATE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            letterSpacing: 2, color: AppTheme.amber)),
                  ]),
                  const Text('New Calculation',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                          letterSpacing: -0.5, color: AppTheme.textHigh)),
                ],
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Room name
                    TmTextField(
                      label: 'Room Name',
                      hint: 'e.g. Master Bathroom',
                      controller: _roomNameCtrl,
                    ),
                    const SizedBox(height: 20),

                    // ── Room Dimensions ────────────────────────────────────
                    TmSectionLabel(
                      'Room Dimensions',
                      trailing: _UnitToggle<RoomUnit>(
                        options: const {RoomUnit.meters: 'm', RoomUnit.feet: 'ft'},
                        selected: _roomUnit,
                        onChanged: (v) => setState(() => _roomUnit = v),
                      ),
                    ),
                    _RoomSectionsPreview(
                      sections: _sections,
                      unit: _roomUnit,
                      onEdit: () async {
                        final result =
                            await Navigator.of(context).push<List<RoomSection>>(
                          MaterialPageRoute(
                            builder: (_) => RoomSectionsScreen(
                              sections: _sections,
                              unit: _roomUnit,
                            ),
                          ),
                        );
                        if (result != null) setState(() => _sections = result);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Tile Size ──────────────────────────────────────────
                    TmSectionLabel(
                      'Tile Size',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ← PRESET AUTOFILL BUTTON
                          GestureDetector(
                            onTap: () async {
                              final preset =
                                  await Navigator.of(context).push<TilePreset>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PresetsScreen(pickMode: true),
                                ),
                              );
                              if (preset != null) _applyPreset(preset);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.amberGlow,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppTheme.amber.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.style_outlined,
                                      size: 12, color: AppTheme.amber),
                                  SizedBox(width: 4),
                                  Text('USE PRESET',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.amber,
                                          letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _UnitToggle<TileUnit>(
                            options: const {
                              TileUnit.centimeters: 'cm',
                              TileUnit.inches: 'in'
                            },
                            selected: _tileUnit,
                            onChanged: (v) => setState(() => _tileUnit = v),
                          ),
                        ],
                      ),
                    ),
                    Row(children: [
                      Expanded(
                        child: TmNumericField(
                          label: 'Length',
                          unit: _tileUnit.label,
                          controller: _tileLengthCtrl,
                          validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TmNumericField(
                          label: 'Width',
                          unit: _tileUnit.label,
                          controller: _tileWidthCtrl,
                          validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Grout Joint ────────────────────────────────────────
                    TmSectionLabel('Grout Joint'),
                    Row(children: [
                      Expanded(
                        child: Slider(
                          value: _groutMm,
                          min: 0,
                          max: 15,
                          divisions: 30,
                          onChanged: (v) => setState(() => _groutMm = v),
                        ),
                      ),
                      Container(
                        width: 58,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          '${_groutMm.toStringAsFixed(1)}mm',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700, color: AppTheme.amber),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Laying Pattern ─────────────────────────────────────
                    TmSectionLabel('Laying Pattern'),
                    TmPatternSelector(
                      selected: _pattern,
                      onChanged: (pattern) =>
                          setState(() => _pattern = pattern),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pattern.description,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textLow),
                    ),
                    const SizedBox(height: 20),

                    // ── Extra Wastage Buffer ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabelInline('Extra Buffer'),
                        Text(
                          '+${_extraBuffer.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: AppTheme.amber),
                        ),
                      ],
                    ),
                    Slider(
                      value: _extraBuffer,
                      min: 0,
                      max: 20,
                      divisions: 20,
                      onChanged: (v) => setState(() => _extraBuffer = v),
                    ),
                    Text(
                      'Pattern: ${_pattern.baseWastagePercent.toStringAsFixed(0)}%'
                      ' + buffer: ${_extraBuffer.toStringAsFixed(0)}%'
                      ' = ${(_pattern.baseWastagePercent + _extraBuffer).toStringAsFixed(0)}% total waste',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textLow),
                    ),
                    const SizedBox(height: 24),

                    // ── Pricing ────────────────────────────────────────────
                    TmSectionLabel(
                      'Pricing',
                      trailing: _CurrencyPicker(
                        selected: _currency,
                        onChanged: (c) => setState(() => _currency = c),
                      ),
                    ),
                    Row(children: [
                      Expanded(
                        child: TmNumericField(
                          label: 'Price / Tile',
                          unit: _currency.symbol,
                          controller: _pricePerTileCtrl,
                          validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) < 0
                                  ? 'Invalid'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TmNumericField(
                          label: 'Tiles / Box',
                          controller: _tilesPerBoxCtrl,
                          allowDecimal: false,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    _ToggleRow(
                      label: 'Enter box price instead',
                      value: _useBoxPrice,
                      onChanged: (v) => setState(() => _useBoxPrice = v),
                    ),
                    if (_useBoxPrice) ...[
                      const SizedBox(height: 10),
                      TmNumericField(
                        label: 'Box Price',
                        unit: _currency.symbol,
                        controller: _boxPriceCtrl,
                      ),
                    ],
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                        child: TmNumericField(
                          label: 'Labour / m²',
                          unit: _currency.symbol,
                          controller: _laborPerM2Ctrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TmNumericField(
                          label: 'Flat Labour',
                          unit: _currency.symbol,
                          controller: _laborFlatCtrl,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TmNumericField(
                      label: 'Other Costs (adhesive, delivery…)',
                      unit: _currency.symbol,
                      controller: _otherCostCtrl,
                    ),
                    const SizedBox(height: 24),

                    // ── Grout (optional) ───────────────────────────────────
                    _ToggleRow(
                      label: 'Add grout details',
                      value: _showGroutSection,
                      onChanged: (v) =>
                          setState(() => _showGroutSection = v),
                    ),
                    if (_showGroutSection) ...[
                      const SizedBox(height: 12),
                      TmTextField(
                        label: 'Grout Colour',
                        hint: 'e.g. Ivory, Charcoal',
                        controller: _groutColorCtrl,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TmNumericField(
                            label: 'Coverage / Bag',
                            unit: 'm²',
                            controller: _groutCoverageCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TmNumericField(
                            label: 'Bag Price',
                            unit: _currency.symbol,
                            controller: _groutBagPriceCtrl,
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Calculate FAB ────────────────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: SizedBox(
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: _calculate,
            backgroundColor: AppTheme.amber,
            foregroundColor: AppTheme.bg,
            icon: const Icon(Icons.calculate_rounded, size: 20),
            label: const Text(
              'CALCULATE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                  letterSpacing: 1),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Room Sections Preview Card ───────────────────────────────────────────────

class _RoomSectionsPreview extends StatelessWidget {
  final List<RoomSection> sections;
  final RoomUnit unit;
  final VoidCallback onEdit;

  const _RoomSectionsPreview({
    required this.sections,
    required this.unit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final mainSections = sections.where((s) => !s.isSubtracted).toList();
    final subSections  = sections.where((s) => s.isSubtracted).toList();
    final totalArea = sections.fold(0.0, (sum, s) {
      final l = unit == RoomUnit.feet ? s.length * 0.3048 : s.length;
      final w = unit == RoomUnit.feet ? s.width  * 0.3048 : s.width;
      return sum + (s.isSubtracted ? -(l * w) : (l * w));
    }).clamp(0.0, double.infinity);

    return TmCard(
      onTap: onEdit,
      highlight: sections.any((s) => s.length == 0 || s.width == 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grid_4x4, size: 16, color: AppTheme.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${sections.length} section${sections.length != 1 ? 's' : ''}'
                ' · ${totalArea.toStringAsFixed(2)} m²',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppTheme.textHigh),
              ),
            ),
            const Text('EDIT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    letterSpacing: 0.8, color: AppTheme.amber)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 16, color: AppTheme.amber),
          ]),
          if (sections.any((s) => s.length > 0)) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...mainSections.map((s) => _SectionRow(s, unit, false)),
            if (subSections.isNotEmpty)
              ...subSections.map((s) => _SectionRow(s, unit, true)),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Tap to set room dimensions',
                style: TextStyle(fontSize: 12, color: AppTheme.textLow)),
          ],
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final RoomSection section;
  final RoomUnit unit;
  final bool subtracted;

  const _SectionRow(this.section, this.unit, this.subtracted);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(
          subtracted ? Icons.remove_circle_outline : Icons.add_circle_outline,
          size: 12,
          color: subtracted ? AppTheme.error : AppTheme.success,
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(section.label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMid))),
        Text(
          '${section.length} × ${section.width} ${unit.label}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: subtracted ? AppTheme.error : AppTheme.textHigh),
        ),
      ]),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _SectionLabelInline extends StatelessWidget {
  final String text;
  const _SectionLabelInline(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            letterSpacing: 1.2, color: AppTheme.textLow));
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36, height: 20,
          decoration: BoxDecoration(
            color: value ? AppTheme.amber : AppTheme.border,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16, height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
      ]),
    );
  }
}

class _UnitToggle<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final void Function(T) onChanged;

  const _UnitToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((entry) {
          final isSelected = entry.key == selected;
          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(entry.value,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: isSelected ? AppTheme.bg : AppTheme.textMid,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  final Currency selected;
  final void Function(Currency) onChanged;

  const _CurrencyPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<Currency>(
          context: context,
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _CurrencySheet(selected: selected),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${selected.symbol} ${selected.code}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppTheme.amber)),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 14, color: AppTheme.textLow),
        ]),
      ),
    );
  }
}

class _CurrencySheet extends StatelessWidget {
  final Currency selected;
  const _CurrencySheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppTheme.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Select Currency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppTheme.textHigh)),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: Currency.values.map((c) {
              final isSelected = c == selected;
              return ListTile(
                dense: true,
                title: Text(c.displayName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.amber : AppTheme.textHigh)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.amber, size: 18)
                    : null,
                onTap: () => Navigator.of(context).pop(c),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
