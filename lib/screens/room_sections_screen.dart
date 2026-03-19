import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';

/// Full-screen editor for adding/editing room sections (for composite shapes).
class RoomSectionsScreen extends StatefulWidget {
  final List<RoomSection> sections;
  final RoomUnit unit;

  const RoomSectionsScreen({
    super.key,
    required this.sections,
    required this.unit,
  });

  @override
  State<RoomSectionsScreen> createState() => _RoomSectionsScreenState();
}

class _RoomSectionsScreenState extends State<RoomSectionsScreen> {
  static const _uuid = Uuid();
  late List<RoomSection> _sections;
  late RoomUnit _unit;

  @override
  void initState() {
    super.initState();
    _sections = List.from(widget.sections);
    _unit = widget.unit;
    // Ensure at least one section
    if (_sections.isEmpty) {
      _sections.add(RoomSection(
        id: _uuid.v4(),
        label: 'Main area',
        length: 0,
        width: 0,
      ));
    }
  }

  double get _netArea {
    return _sections.fold(0.0, (sum, s) {
      final lm = _unit == RoomUnit.feet ? s.length * 0.3048 : s.length;
      final wm = _unit == RoomUnit.feet ? s.width * 0.3048 : s.width;
      return sum + (s.isSubtracted ? -(lm * wm) : (lm * wm));
    }).clamp(0.0, double.infinity);
  }

  void _addSection({bool subtracted = false}) {
    setState(() {
      _sections.add(RoomSection(
        id: _uuid.v4(),
        label: subtracted ? 'Cut-out ${_sections.length}' : 'Section ${_sections.length + 1}',
        length: 0,
        width: 0,
        isSubtracted: subtracted,
      ));
    });
  }

  void _removeSection(String id) {
    if (_sections.where((s) => !s.isSubtracted).length <= 1 &&
        !_sections.firstWhere((s) => s.id == id).isSubtracted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one main section is required.')),
      );
      return;
    }
    setState(() => _sections.removeWhere((s) => s.id == id));
  }

  void _editSection(RoomSection section) async {
    final result = await showModalBottomSheet<RoomSection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SectionEditSheet(section: section, unit: _unit),
    );
    if (result != null) {
      setState(() {
        final idx = _sections.indexWhere((s) => s.id == result.id);
        if (idx != -1) _sections[idx] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainSections = _sections.where((s) => !s.isSubtracted).toList();
    final subSections = _sections.where((s) => s.isSubtracted).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Room Shape'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_sections),
            child: const Text('DONE'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Net area banner
          Container(
            color: AppTheme.amberGlow,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.grid_4x4, size: 16, color: AppTheme.amber),
                const SizedBox(width: 8),
                Text(
                  'Net floor area: ${_netArea.toStringAsFixed(2)} m²',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.amber,
                  ),
                ),
                const Spacer(),
                // Unit toggle
                _SmallUnitToggle(
                  unit: _unit,
                  onChanged: (u) => setState(() => _unit = u),
                ),
              ],
            ),
          ),

          // Tips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TmCard(
              padding: const EdgeInsets.all(12),
              color: AppTheme.surfaceAlt,
              child: const Text(
                '💡 Build complex rooms by adding sections. Use cut-outs to remove pillars, bathtubs, or kitchen islands.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMid, height: 1.5),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // Main sections
                TmSectionLabel('Main Sections'),
                ...mainSections.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SectionTile(
                    section: s,
                    unit: _unit,
                    onEdit: () => _editSection(s),
                    onDelete: mainSections.length > 1
                        ? () => _removeSection(s.id)
                        : null,
                  ),
                )),
                TextButton.icon(
                  onPressed: () => _addSection(),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add section (L-shape, alcove…)'),
                ),
                const SizedBox(height: 16),

                // Cut-outs
                TmSectionLabel('Cut-outs / Subtractions'),
                if (subSections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No cut-outs. Add one to exclude pillars, bathtubs, etc.',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textLow),
                    ),
                  ),
                ...subSections.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SectionTile(
                    section: s,
                    unit: _unit,
                    onEdit: () => _editSection(s),
                    onDelete: () => _removeSection(s.id),
                    isSubtracted: true,
                  ),
                )),
                TextButton.icon(
                  onPressed: () => _addSection(subtracted: true),
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  label: const Text('Add cut-out'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(_sections),
        label: const Text(
          'SAVE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        icon: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SectionTile extends StatelessWidget {
  final RoomSection section;
  final RoomUnit unit;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final bool isSubtracted;

  const _SectionTile({
    required this.section,
    required this.unit,
    required this.onEdit,
    this.onDelete,
    this.isSubtracted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValues = section.length > 0 && section.width > 0;
    final lm = unit == RoomUnit.feet ? section.length * 0.3048 : section.length;
    final wm = unit == RoomUnit.feet ? section.width * 0.3048 : section.width;
    final area = hasValues ? lm * wm : 0.0;

    return TmCard(
      onTap: onEdit,
      highlight: !hasValues,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSubtracted
                  ? AppTheme.error.withOpacity(0.1)
                  : AppTheme.amberGlow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSubtracted ? Icons.remove : Icons.add,
              size: 18,
              color: isSubtracted ? AppTheme.error : AppTheme.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textHigh,
                  ),
                ),
                Text(
                  hasValues
                      ? '${section.length} × ${section.width} ${unit.label}  ·  ${area.toStringAsFixed(2)} m²'
                      : 'Tap to set dimensions',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasValues ? AppTheme.textMid : AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textLow),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  size: 18, color: AppTheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionEditSheet extends StatefulWidget {
  final RoomSection section;
  final RoomUnit unit;

  const _SectionEditSheet({required this.section, required this.unit});

  @override
  State<_SectionEditSheet> createState() => _SectionEditSheetState();
}

class _SectionEditSheetState extends State<_SectionEditSheet> {
  late TextEditingController _labelCtrl;
  late TextEditingController _lengthCtrl;
  late TextEditingController _widthCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.section.label);
    _lengthCtrl = TextEditingController(
      text: widget.section.length > 0
          ? widget.section.length.toString()
          : '',
    );
    _widthCtrl = TextEditingController(
      text: widget.section.width > 0
          ? widget.section.width.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  color: widget.section.isSubtracted
                      ? AppTheme.error
                      : AppTheme.amber,
                  margin: const EdgeInsets.only(right: 10),
                ),
                Text(
                  widget.section.isSubtracted
                      ? 'Edit Cut-out'
                      : 'Edit Section',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textHigh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TmTextField(
              label: 'Label',
              controller: _labelCtrl,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TmNumericField(
                    label: 'Length',
                    unit: widget.unit.label,
                    controller: _lengthCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TmNumericField(
                    label: 'Width',
                    unit: widget.unit.label,
                    controller: _widthCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TmAmberButton(
              label: 'Save Section',
              icon: Icons.check,
              onPressed: () {
                final l = double.tryParse(_lengthCtrl.text) ?? 0;
                final w = double.tryParse(_widthCtrl.text) ?? 0;
                Navigator.of(context).pop(
                  widget.section.copyWith(
                    label: _labelCtrl.text.trim().isEmpty
                        ? widget.section.label
                        : _labelCtrl.text.trim(),
                    length: l,
                    width: w,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallUnitToggle extends StatelessWidget {
  final RoomUnit unit;
  final void Function(RoomUnit) onChanged;

  const _SmallUnitToggle({required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(
        unit == RoomUnit.meters ? RoomUnit.feet : RoomUnit.meters,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          unit == RoomUnit.meters ? 'metres' : 'feet',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.amber,
          ),
        ),
      ),
    );
  }
}