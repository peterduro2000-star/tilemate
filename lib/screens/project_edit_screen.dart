import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';

class ProjectEditScreen extends StatefulWidget {
  final TileProject? existing;

  const ProjectEditScreen({super.key, this.existing});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _clientCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  Currency _currency = Currency.usd;
  ProjectStatus _status = ProjectStatus.draft;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl    = TextEditingController(text: e?.name ?? '');
    _clientCtrl  = TextEditingController(text: e?.clientName ?? '');
    _phoneCtrl   = TextEditingController(text: e?.clientPhone ?? '');
    _emailCtrl   = TextEditingController(text: e?.clientEmail ?? '');
    _addressCtrl = TextEditingController(text: e?.siteAddress ?? '');
    _notesCtrl   = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _currency = e.currency;
      _status   = e.status;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final project = TileProject(
      id:          widget.existing?.id ?? 'proj_${now.millisecondsSinceEpoch}',
      name:        _nameCtrl.text.trim(),
      clientName:  _clientCtrl.text.trim().isEmpty ? null : _clientCtrl.text.trim(),
      clientPhone: _phoneCtrl.text.trim().isEmpty  ? null : _phoneCtrl.text.trim(),
      clientEmail: _emailCtrl.text.trim().isEmpty  ? null : _emailCtrl.text.trim(),
      siteAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes:       _notesCtrl.text.trim().isEmpty  ? null : _notesCtrl.text.trim(),
      createdAt:   widget.existing?.createdAt ?? now,
      currency:    _currency,
      rooms:       widget.existing?.rooms ?? [],
      status:      _status,
    );
    Navigator.of(context).pop(project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Project' : 'Edit Project'),
        actions: [
          TextButton(onPressed: _save, child: const Text('SAVE')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            const TmSectionLabel('Project'),
            TmTextField(
              label: 'Project Name',
              hint: 'e.g. Johnson Bathroom Reno',
              controller: _nameCtrl,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Name required' : null,
            ),
            const SizedBox(height: 20),

            const TmSectionLabel('Client (optional)'),
            TmTextField(label: 'Client Name', controller: _clientCtrl),
            const SizedBox(height: 12),
            TmTextField(
              label: 'Phone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TmTextField(
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TmTextField(
              label: 'Site Address',
              controller: _addressCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            const TmSectionLabel('Settings'),
            DropdownButtonFormField<Currency>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              dropdownColor: AppTheme.surface,
              style: const TextStyle(color: AppTheme.textHigh, fontSize: 14),
              items: Currency.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.displayName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProjectStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              dropdownColor: AppTheme.surface,
              style: const TextStyle(color: AppTheme.textHigh, fontSize: 14),
              items: ProjectStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.displayName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 20),

            const TmSectionLabel('Notes (optional)'),
            TmTextField(
              label: 'Notes',
              controller: _notesCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            TmAmberButton(
              label: widget.existing == null ? 'Create Project' : 'Save Changes',
              icon: Icons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
