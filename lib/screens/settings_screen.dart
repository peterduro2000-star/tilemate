import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../repositories/project_repository.dart';
import '../repositories/preset_repository.dart';
import '../repositories/history_repository.dart';
import '../services/tilemate_database.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';
import 'branding_settings_screen.dart';

// ─── Currency preference key ──────────────────────────────────────────────────
const _kCurrency = 'global_currency';

/// Load the globally selected currency (defaults to NGN)
Future<Currency> loadGlobalCurrency() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString(_kCurrency);
  if (name == null) return Currency.ngn;
  return Currency.values.firstWhere((c) => c.name == name,
      orElse: () => Currency.ngn);
}

/// Save the globally selected currency
Future<void> saveGlobalCurrency(Currency currency) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kCurrency, currency.name);
}

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Currency _currency = Currency.ngn;
  bool _loading = true;
  bool _backupBusy = false;
  bool _restoreBusy = false;
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currency = await loadGlobalCurrency();
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_backup_date');
    if (mounted) {
      setState(() {
        _currency = currency;
        _lastBackupDate = lastBackup;
        _loading = false;
      });
    }
  }

  Future<void> _changeCurrency(Currency currency) async {
    await saveGlobalCurrency(currency);
    setState(() => _currency = currency);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            '${currency.displayName} set as default currency')),
      );
    }
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _buildBackupData() async {
    final projects = await ProjectRepository.instance.getAllProjects();
    final presets  = await PresetRepository.instance.getAllPresets();
    final history  = await HistoryRepository.instance.getHistory();
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'currency': _currency.name,
      'projects': projects.map((p) => p.toMap()).toList(),
      'presets':  presets.map((p) => p.toMap()).toList(),
      'history':  history.map((h) => h.toMap()).toList(),
    };
  }

  Future<void> _exportBackup() async {
  setState(() => _backupBusy = true);
  try {
    final data = await _buildBackupData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/tilemate_backup.json');
    await file.writeAsString(json);

    // Save last backup date
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString('last_backup_date', now);
    setState(() => _lastBackupDate = now);

    // Ask user what to do
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Backup Created',
                style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w800, color: AppTheme.textHigh)),
            const SizedBox(height: 6),
            const Text('tilemate_backup.json saved to your device.',
                style: TextStyle(fontSize: 12, color: AppTheme.textLow)),
            const SizedBox(height: 20),
            TmAmberButton(
              label: 'Share via WhatsApp / Gmail',
              icon: Icons.share,
              onPressed: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(file.path)],
                  subject: 'Tilemate Backup',
                  text: 'Tilemate backup — ${DateTime.now().toString().substring(0, 10)}',
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check, color: AppTheme.amber),
                label: const Text('Done — file saved to device',
                    style: TextStyle(color: AppTheme.amber)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.amber),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'),
            backgroundColor: AppTheme.error),
      );
    }
  } finally {
    if (mounted) setState(() => _backupBusy = false);
  }
}

  Future<void> _importBackup() async {
    setState(() => _restoreBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
  type: FileType.any,
);
      if (result == null || result.files.single.path == null) {
        setState(() => _restoreBusy = false);
        return;
      }

      final file    = File(result.files.single.path!);
      final content = await file.readAsString();
      final data    = json.decode(content) as Map<String, dynamic>;

      // Confirm restore
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Restore Backup?',
              style: TextStyle(color: AppTheme.textHigh)),
          content: const Text(
            'This will replace all your current projects, tiles and history with the backup data. This cannot be undone.',
            style: TextStyle(color: AppTheme.textMid),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.amber),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _restoreBusy = false);
        return;
      }

      // Restore currency
      if (data['currency'] != null) {
        final currency = Currency.values.firstWhere(
            (c) => c.name == data['currency'],
            orElse: () => Currency.ngn);
        await saveGlobalCurrency(currency);
        setState(() => _currency = currency);
      }

      // Restore projects
      if (data['projects'] != null) {
        final projects = (data['projects'] as List)
            .map((p) => TileProject.fromMap(p as Map<String, dynamic>))
            .toList();
        final db = await TileMateDatabase.instance.database;
        await db.delete('projects');
        for (final p in projects) {
          await ProjectRepository.instance.saveProject(p);
        }
      }

      // Restore presets
      if (data['presets'] != null) {
        final presets = (data['presets'] as List)
            .map((p) => TilePreset.fromMap(p as Map<String, dynamic>))
            .toList();
        final db = await TileMateDatabase.instance.database;
        await db.delete('tile_presets');
        for (final p in presets) {
          await PresetRepository.instance.savePreset(p);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.amber))),
      );
    }

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
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2, color: AppTheme.amber)),
                  ]),
                  const Text('Settings',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5, color: AppTheme.textHigh)),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Currency ────────────────────────────────────────────
                  const TmSectionLabel('Default Currency'),
                  TmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.payments_outlined,
                              size: 16, color: AppTheme.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currency.displayName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textHigh),
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickCurrency,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.amberGlow,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                    color: AppTheme.amber.withOpacity(0.4)),
                              ),
                              child: const Text('CHANGE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.amber)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        const Text(
                          'Applied to all new calculations and tile presets.',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textLow),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Branding ────────────────────────────────────────────
                  const TmSectionLabel('Company Branding'),
                  TmCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BrandingSettingsScreen())),
                    child: Row(children: [
                      const Icon(Icons.business_outlined,
                          size: 16, color: AppTheme.amber),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Company Details',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textHigh)),
                            SizedBox(height: 2),
                            Text('Name, phone and email on PDF quotes',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textLow)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.textLow),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Backup & Restore ────────────────────────────────────
                  const TmSectionLabel('Backup & Restore'),

                  // Info card
                  TmCard(
                    color: AppTheme.amberGlow,
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: AppTheme.amber),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Export your data as a JSON file and share via WhatsApp to yourself. Import on a new phone to restore everything.',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.amber, height: 1.5),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  if (_lastBackupDate != null) ...[
                    Text(
                      'Last backup: ${_lastBackupDate!.substring(0, 10)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textLow),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Export button
                  TmAmberButton(
                    label: 'Export Backup',
                    icon: Icons.upload_outlined,
                    loading: _backupBusy,
                    onPressed: _exportBackup,
                  ),
                  const SizedBox(height: 10),

                  // Import button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _restoreBusy ? null : _importBackup,
                      icon: _restoreBusy
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppTheme.amber)))
                          : const Icon(Icons.download_outlined,
                              color: AppTheme.amber),
                      label: const Text('Import Backup',
                          style: TextStyle(color: AppTheme.amber)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.amber),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── App Info ────────────────────────────────────────────
                  const TmSectionLabel('About'),
                  TmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.amberGlow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.amber.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.grid_4x4,
                                color: AppTheme.amber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tilemate',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textHigh)),
                              Text('Smart Tiling Assistant · v1.0.0',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textLow)),
                            ],
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency() async {
    final result = await showModalBottomSheet<Currency>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CurrencySheet(selected: _currency),
    );
    if (result != null) await _changeCurrency(result);
  }
}

// ─── Currency picker sheet ────────────────────────────────────────────────────

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
          child: Text('Select Default Currency',
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
                    style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.amber
                            : AppTheme.textHigh)),
                trailing: isSelected
                    ? const Icon(Icons.check,
                        color: AppTheme.amber, size: 18)
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
