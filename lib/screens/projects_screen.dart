import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../repositories/project_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';
import 'project_detail_screen.dart';
import 'project_edit_screen.dart';


class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _repo = ProjectRepository.instance;

  List<TileProject> _projects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final projects = await _repo.getAllProjects();
      if (mounted) setState(() { _projects = projects; _loading = false; });
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
                  Text('Projects',
                      style: Theme.of(context)
                          .textTheme.headlineMedium?.copyWith(fontSize: 20)),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.amber))),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: TmEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load projects',
                subtitle: _error!,
                actionLabel: 'Retry',
                onAction: _load,
              ),
            )
          else if (_projects.isEmpty)
            SliverFillRemaining(
              child: TmEmptyState(
                icon: Icons.folder_outlined,
                title: 'No projects yet',
                subtitle:
                    'Group your room calculations into a project to generate a full quote for a client.',
                actionLabel: 'New Project',
                onAction: _createProject,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProjectCard(
                      project: _projects[i],
                      onTap: () => _openProject(_projects[i]),
                      onDelete: () => _deleteProject(_projects[i]),
                    ),
                  ),
                  childCount: _projects.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        backgroundColor: AppTheme.amber,
        foregroundColor: AppTheme.bg,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('NEW PROJECT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _createProject() async {
    final project = await Navigator.of(context).push<TileProject>(
      MaterialPageRoute(builder: (_) => const ProjectEditScreen()),
    );
    if (project != null) {
      await _repo.saveProject(project);
      await _load();
    }
  }

  Future<void> _openProject(TileProject project) async {
    final updated = await Navigator.of(context).push<TileProject>(
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
    );
    if (updated != null) {
      await _repo.saveProject(updated);
      await _load();
    }
  }

  Future<void> _deleteProject(TileProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete "${project.name}"?',
            style: const TextStyle(color: AppTheme.textHigh)),
        content: Text(
          project.roomCount > 0
              ? 'This will permanently delete the project and ${project.roomCount} room${project.roomCount != 1 ? 's' : ''}.'
              : 'This cannot be undone.',
          style: const TextStyle(color: AppTheme.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.deleteProject(project.id);
      await _load();
    }
  }
}

class _ProjectCard extends StatelessWidget {
  final TileProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectCard({required this.project, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(project.createdAt);
    final total = NumberFormat.currency(
        symbol: project.currencySymbol, decimalDigits: 2)
        .format(project.grandTotal);

    return TmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(project.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppTheme.textHigh, letterSpacing: -0.3))),
            TmStatusBadge.fromStatus(project.status.name),
            const SizedBox(width: 8),
            GestureDetector(onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textLow)),
          ]),
          if (project.clientName != null) ...[
            const SizedBox(height: 4),
            Text(project.clientName!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            _Mini('Rooms', '${project.roomCount}'),
            const SizedBox(width: 20),
            _Mini('Area', '${project.totalFloorArea.toStringAsFixed(1)} m²'),
            const SizedBox(width: 20),
            _Mini('Boxes', '${project.totalBoxesRequired}'),
            const Spacer(),
            Text(total, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                letterSpacing: -0.5, color: AppTheme.amber)),
          ]),
          const SizedBox(height: 6),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textLow)),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
            color: AppTheme.textHigh)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLow)),
      ],
    );
  }
}