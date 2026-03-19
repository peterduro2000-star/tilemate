import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';
import '../models/models.dart';
import 'pdf_preview_screen.dart';

/// Keys for SharedPreferences branding storage
class _Keys {
  static const companyName  = 'branding_company_name';
  static const companyPhone = 'branding_company_phone';
  static const companyEmail = 'branding_company_email';
}

/// Loads and saves the tiler's company details used in PDF headers.
class BrandingSettings {
  final String? companyName;
  final String? companyPhone;
  final String? companyEmail;

  const BrandingSettings({
    this.companyName,
    this.companyPhone,
    this.companyEmail,
  });

  bool get isEmpty =>
      companyName == null && companyPhone == null && companyEmail == null;

  static Future<BrandingSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString(_Keys.companyName);
    final phone = prefs.getString(_Keys.companyPhone);
    final email = prefs.getString(_Keys.companyEmail);
    return BrandingSettings(
      companyName:  (name?.isEmpty  ?? true) ? null : name,
      companyPhone: (phone?.isEmpty ?? true) ? null : phone,
      companyEmail: (email?.isEmpty ?? true) ? null : email,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    if (companyName != null) {
      await prefs.setString(_Keys.companyName, companyName!);
    } else {
      await prefs.remove(_Keys.companyName);
    }
    if (companyPhone != null) {
      await prefs.setString(_Keys.companyPhone, companyPhone!);
    } else {
      await prefs.remove(_Keys.companyPhone);
    }
    if (companyEmail != null) {
      await prefs.setString(_Keys.companyEmail, companyEmail!);
    } else {
      await prefs.remove(_Keys.companyEmail);
    }
  }
}

/// Screen to edit company branding that appears on PDF quotes.
class BrandingSettingsScreen extends StatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  State<BrandingSettingsScreen> createState() =>
      _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState extends State<BrandingSettingsScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final branding = await BrandingSettings.load();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text  = branding.companyName  ?? '';
      _phoneCtrl.text = branding.companyPhone ?? '';
      _emailCtrl.text = branding.companyEmail ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final branding = BrandingSettings(
      companyName:  _nameCtrl.text.trim().isEmpty  ? null : _nameCtrl.text.trim(),
      companyPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      companyEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );
    await branding.save();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branding saved')),
      );
      Navigator.of(context).pop(branding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Company Branding'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppTheme.amber),
                    ),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.amber),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info card
                TmCard(
                  color: AppTheme.amberGlow,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppTheme.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your company details appear in the header of every PDF quote you generate.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.amber,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const TmSectionLabel('Your Details'),
                TmTextField(
                  label: 'Company / Trading Name',
                  hint: 'e.g. Osei Tiling & Floors',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 12),
                TmTextField(
                  label: 'Phone Number',
                  hint: 'e.g. +254 712 345 678',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TmTextField(
                  label: 'Email Address',
                  hint: 'e.g. info@mytilingbusiness.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Leave blank to generate quotes without company branding.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLow),
                ),
                const SizedBox(height: 32),
                TmAmberButton(
                  label: 'Save Branding',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}

// ─── Convenience helper: open PDF from results or project screen ──────────────

/// Call this from ResultsScreen or ProjectDetailScreen to generate
/// and preview a PDF with the saved company branding.
Future<void> openQuotePdf(
  BuildContext context, {
  TileCalculation? calculation,
  TileProject? project,
}) async {
  assert(calculation != null || project != null,
      'Pass either a calculation or a project');

  final branding = await BrandingSettings.load();

  if (!context.mounted) return;

  if (project != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen.project(
          project: project,
          companyName:  branding.companyName,
          companyPhone: branding.companyPhone,
          companyEmail: branding.companyEmail,
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen.singleRoom(
          calculation: calculation!,
          companyName:  branding.companyName,
          companyPhone: branding.companyPhone,
          companyEmail: branding.companyEmail,
        ),
      ),
    );
  }
}