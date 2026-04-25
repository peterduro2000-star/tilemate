import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../repositories/preset_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';
import 'settings_screen.dart';

class PresetsScreen extends StatefulWidget {
  final bool pickMode;
  const PresetsScreen({super.key, this.pickMode = false});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  final _repo = PresetRepository.instance;
  List<TilePreset> _presets = [];
  bool _loading = true;
  String? _error;
  Currency _currency = Currency.ngn;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.getAllPresets();
      final currency = await loadGlobalCurrency();
      if (mounted) {
        setState(() {
          _presets = p;
          _currency = currency;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bg,
            expandedHeight: 100,
            leading: widget.pickMode
                ? IconButton(icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop())
                : null,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.pickMode)
                    Row(children: [
                      Container(width: 6, height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                              color: AppTheme.amber, shape: BoxShape.circle)),
                      const Text('TILEMATE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              letterSpacing: 2, color: AppTheme.amber)),
                    ]),
                  Text(widget.pickMode ? 'Select a Tile' : 'My Tiles',
                      style: Theme.of(context)
                          .textTheme.headlineMedium?.copyWith(fontSize: 20)),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.add), onPressed: _addPreset),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(child: Center(child:
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.amber))))
          else if (_error != null)
            SliverFillRemaining(child: TmEmptyState(
              icon: Icons.error_outline, title: 'Could not load tiles',
              subtitle: _error!, actionLabel: 'Retry', onAction: _load))
          else if (_presets.isEmpty)
            SliverFillRemaining(child: TmEmptyState(
              icon: Icons.style_outlined, title: 'No tile presets',
              subtitle: 'Save your go-to tiles — sizes, prices, and box counts.',
              actionLabel: 'Add Tile', onAction: _addPreset))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PresetCard(
                      preset: _presets[i],
                      currency: _currency,
                      pickMode: widget.pickMode,
                      onTap: () => widget.pickMode
                          ? Navigator.of(context).pop(_presets[i])
                          : _editPreset(_presets[i]),
                      onDelete: () => _deletePreset(_presets[i]),
                    ),
                  ),
                  childCount: _presets.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPreset,
        backgroundColor: AppTheme.amber,
        foregroundColor: AppTheme.bg,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('ADD TILE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _addPreset() async {
    final currency = await loadGlobalCurrency();
    if (!mounted) return;
    final result = await showModalBottomSheet<TilePreset>(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PresetEditSheet(currency: currency),
    );
    if (result != null) { await _repo.savePreset(result); await _load(); }
  }

  Future<void> _editPreset(TilePreset preset) async {
    final currency = await loadGlobalCurrency();
    if (!mounted) return;
    final result = await showModalBottomSheet<TilePreset>(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PresetEditSheet(existing: preset, currency: currency),
    );
    if (result != null) { await _repo.savePreset(result); await _load(); }
  }

  Future<void> _deletePreset(TilePreset preset) async {
    await _repo.deletePreset(preset.id);
    await _load();
  }
}

class _PresetCard extends StatelessWidget {
  final TilePreset preset;
  final Currency currency;
  final bool pickMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PresetCard({required this.preset, required this.currency,
      required this.pickMode, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return TmCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppTheme.amberGlow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3))),
          child: Center(child: AspectRatio(
            aspectRatio: (preset.tileLength / preset.tileWidth).clamp(0.3, 3.0),
            child: Container(margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.amber.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2))),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preset.name, style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: AppTheme.textHigh)),
            const SizedBox(height: 2),
            Text('${preset.tileLength.toStringAsFixed(0)}×'
                '${preset.tileWidth.toStringAsFixed(0)} ${preset.tileUnit.label}'
                '  ·  ${preset.tilesPerBox}/box',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            if (preset.brand != null)
              Text(preset.brand!, style: const TextStyle(fontSize: 11, color: AppTheme.textLow)),
          ],
        )),
        if (pickMode)
          const Icon(Icons.chevron_right, color: AppTheme.amber)
        else
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${currency.symbol}${preset.effectivePricePerTile.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: AppTheme.amber)),
            const Text('per tile', style: TextStyle(fontSize: 10, color: AppTheme.textLow)),
            const SizedBox(height: 6),
            GestureDetector(onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textLow)),
          ]),
      ]),
    );
  }
}

class _PresetEditSheet extends StatefulWidget {
  final TilePreset? existing;
  final Currency currency;
  const _PresetEditSheet({this.existing, this.currency = Currency.ngn});

  @override
  State<_PresetEditSheet> createState() => _PresetEditSheetState();
}

class _PresetEditSheetState extends State<_PresetEditSheet> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl, _lengthCtrl, _widthCtrl,
      _priceCtrl, _boxCountCtrl, _boxPriceCtrl, _brandCtrl, _codeCtrl;
  TileUnit _tileUnit = TileUnit.centimeters;
  bool _useBoxPrice = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl     = TextEditingController(text: e?.name ?? '');
    _lengthCtrl   = TextEditingController(text: e != null ? e.tileLength.toString() : '');
    _widthCtrl    = TextEditingController(text: e != null ? e.tileWidth.toString() : '');
    _priceCtrl    = TextEditingController(text: e != null ? e.pricePerTile.toString() : '');
    _boxCountCtrl = TextEditingController(text: e?.tilesPerBox.toString() ?? '1');
    _boxPriceCtrl = TextEditingController(text: e?.boxPrice?.toString() ?? '');
    _brandCtrl    = TextEditingController(text: e?.brand ?? '');
    _codeCtrl     = TextEditingController(text: e?.productCode ?? '');
    if (e != null) { _tileUnit = e.tileUnit; _useBoxPrice = e.boxPrice != null; }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _lengthCtrl, _widthCtrl, _priceCtrl,
        _boxCountCtrl, _boxPriceCtrl, _brandCtrl, _codeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(TilePreset(
      id:           widget.existing?.id ?? _uuid.v4(),
      name:         _nameCtrl.text.trim(),
      tileLength:   double.tryParse(_lengthCtrl.text) ?? 0,
      tileWidth:    double.tryParse(_widthCtrl.text) ?? 0,
      tileUnit:     _tileUnit,
      pricePerTile: double.tryParse(_priceCtrl.text) ?? 0,
      tilesPerBox:  int.tryParse(_boxCountCtrl.text) ?? 1,
      boxPrice:     _useBoxPrice && _boxPriceCtrl.text.isNotEmpty
                      ? double.tryParse(_boxPriceCtrl.text) : null,
      brand:        _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      productCode:  _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      createdAt:    widget.existing?.createdAt ?? DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.currency.symbol;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.existing == null ? 'New Tile Preset' : 'Edit Preset',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppTheme.textHigh)),
            const SizedBox(height: 16),
            TmTextField(label: 'Name', hint: 'e.g. 600×600 Porcelain Matt',
                controller: _nameCtrl,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TmNumericField(label: 'Length', unit: _tileUnit.label,
                  controller: _lengthCtrl,
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null)),
              const SizedBox(width: 10),
              Expanded(child: TmNumericField(label: 'Width', unit: _tileUnit.label,
                  controller: _widthCtrl,
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null)),
              const SizedBox(width: 10),
              Container(
                height: 52,
                decoration: BoxDecoration(color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [TileUnit.centimeters, TileUnit.inches].map((u) {
                    final sel = _tileUnit == u;
                    return GestureDetector(
                      onTap: () => setState(() => _tileUnit = u),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(u.label, style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: sel ? AppTheme.amber : AppTheme.textLow))),
                    );
                  }).toList(),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TmNumericField(
                  label: 'Price / Tile', unit: sym, controller: _priceCtrl)),
              const SizedBox(width: 10),
              Expanded(child: TmNumericField(
                  label: 'Tiles / Box', controller: _boxCountCtrl, allowDecimal: false)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Checkbox(value: _useBoxPrice, activeColor: AppTheme.amber,
                  onChanged: (v) => setState(() => _useBoxPrice = v!)),
              const Text('Box price', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
              if (_useBoxPrice) ...[
                const SizedBox(width: 12),
                Expanded(child: TmNumericField(
                    label: 'Box Price', unit: sym, controller: _boxPriceCtrl)),
              ],
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TmTextField(label: 'Brand (optional)', controller: _brandCtrl)),
              const SizedBox(width: 10),
              Expanded(child: TmTextField(label: 'Product Code', controller: _codeCtrl)),
            ]),
            const SizedBox(height: 20),
            TmAmberButton(
              label: widget.existing == null ? 'Save Preset' : 'Update',
              icon: Icons.check, onPressed: _save),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
