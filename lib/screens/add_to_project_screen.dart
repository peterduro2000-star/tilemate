import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../repositories/project_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';
import 'project_edit_screen.dart';
import 'project_detail_screen.dart';

/// Lets the tiler attach a finished calculation to an existing project,
/// or create a new project on the spot.
class AddToProjectScreen extends StatefulWidget {
  final TileCalculation calculation;
  const AddToProjectScreen({super.key, required this.calculation});

  @override
  State<AddToProjectScreen> createState() => _AddToProjectScreenState();
}

class _AddToProjectScreenState extends State<AddToProjectScreen> {
  final _repo = ProjectRepository.instance;
  List<TileProject> _projects = [];
  bool _loading = true;
  bool _saving  = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.getAllProjects();
      if (mounted) setState(() { _projects = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _addToProject(TileProject project) async {
    setState(() => _saving = true);
    try {
      // Stamp the room with this project's id
      final room = _stampedRoom(project.id);
      await _repo.addRoomToProject(project.id, room);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to "${project.name}"')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _createAndAdd() async {
    final project = await Navigator.of(context).push<TileProject>(
      MaterialPageRoute(builder: (_) => ProjectEditScreen()),
    );
    if (project == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final room = _stampedRoom(project.id);
      final projectWithRoom = project.addRoom(room);
      await _repo.saveProject(projectWithRoom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to new project "${project.name}"')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  /// Returns the calculation with its projectId stamped in.
  TileCalculation _stampedRoom(String projectId) {
    // TileCalculation is immutable — rebuild with updated projectId via toMap/fromMap
    final map = widget.calculation.toMap();
    map['projectId'] = projectId;
    return TileCalculation.fromMap(map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Save to Project')),
      body: _saving
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.amber)))
          : _loading
              ? const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.amber)))
              : _error != null
                  ? TmEmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load projects',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    )
                  : _Body(
                      calculation: widget.calculation,
                      projects: _projects,
                      onPick: _addToProject,
                      onCreateNew: _createAndAdd,
                    ),
    );
  }
}

class _Body extends StatelessWidget {
  final TileCalculation calculation;
  final List<TileProject> projects;
  final void Function(TileProject) onPick;
  final VoidCallback onCreateNew;

  const _Body({
    required this.calculation,
    required this.projects,
    required this.onPick,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room summary chip
                TmCard(
                  highlight: true,
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: AppTheme.amberGlow,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.grid_on, size: 18, color: AppTheme.amber),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(calculation.roomName,
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: AppTheme.textHigh)),
                        Text('${calculation.floorArea.toStringAsFixed(2)} m²  ·  '
                            '${calculation.boxesRequired} boxes  ·  '
                            '${calculation.currency.symbol}${calculation.totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                      ],
                    )),
                  ]),
                ),

                const SizedBox(height: 20),

                // Create new project
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                    label: const Text('Create New Project & Add'),
                  ),
                ),

                if (projects.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const TmSectionLabel('Add to Existing Project'),
                ],
              ],
            ),
          ),
        ),

        if (projects.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final p = projects[i];
                  final total = NumberFormat.currency(
                      symbol: p.currencySymbol, decimalDigits: 2)
                      .format(p.grandTotal);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TmCard(
                      onTap: () => onPick(p),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.folder_outlined,
                              size: 18, color: AppTheme.textMid),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppTheme.textHigh)),
                            Text('${p.roomCount} room${p.roomCount != 1 ? 's' : ''}  ·  $total',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                          ],
                        )),
                        TmStatusBadge.fromStatus(p.status.name),
                        const SizedBox(width: 8),
                        const Icon(Icons.add_circle_outline,
                            size: 20, color: AppTheme.amber),
                      ]),
                    ),
                  );
                },
                childCount: projects.length,
              ),
            ),
          ),

        if (projects.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off_outlined,
                      size: 40, color: AppTheme.textLow),
                  const SizedBox(height: 12),
                  const Text('No existing projects',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMid)),
                  const SizedBox(height: 4),
                  const Text('Use the button above to create one.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLow)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}