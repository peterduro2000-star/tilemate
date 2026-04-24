import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/quote_pdf_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/tm_widgets.dart';

/// Shows a live PDF preview with share, print, and save-to-files actions.
/// Can be opened for a single room OR a full project.
class PdfPreviewScreen extends StatefulWidget {
  /// Pass exactly one of these.
  final TileCalculation? calculation;
  final TileProject? project;

  /// Optional branding shown in the PDF header.
  final String? companyName;
  final String? companyPhone;
  final String? companyEmail;

  const PdfPreviewScreen.singleRoom({
    super.key,
    required TileCalculation calculation,
    this.companyName,
    this.companyPhone,
    this.companyEmail,
  })  : calculation = calculation,
        project = null;

  const PdfPreviewScreen.project({
    super.key,
    required TileProject project,
    this.companyName,
    this.companyPhone,
    this.companyEmail,
  })  : project = project,
        calculation = null;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _generating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  String get _title => widget.project?.name ??
      widget.calculation?.roomName ??
      'Quote';

  String get _filename =>
      'Tilemate_${_title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';

  Future<void> _generatePdf() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final bytes = widget.project != null
          ? await QuotePdfGenerator.project(
              project: widget.project!,
              companyName: widget.companyName,
              companyPhone: widget.companyPhone,
              companyEmail: widget.companyEmail,
            )
          : await QuotePdfGenerator.singleRoom(
              calculation: widget.calculation!,
              companyName: widget.companyName,
              companyPhone: widget.companyPhone,
              companyEmail: widget.companyEmail,
            );
      if (mounted) setState(() {
        _pdfBytes = bytes;
        _generating = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _generating = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    HapticFeedback.mediumImpact();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_filename');
    await file.writeAsBytes(_pdfBytes!);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Tilemate Quote – $_title',
    );
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    HapticFeedback.mediumImpact();
    await Printing.layoutPdf(
      onLayout: (_) async => _pdfBytes!,
      name: _filename,
    );
  }

  Future<void> _saveToFiles() async {
    if (_pdfBytes == null) return;
    HapticFeedback.mediumImpact();
    try {
      // Save to app documents directory (Downloads on Android, Files on iOS)
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      await file.writeAsBytes(_pdfBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: _printPdf,
              tooltip: 'Print',
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveToFiles,
              tooltip: 'Save to files',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _sharePdf,
              tooltip: 'Share PDF',
            ),
          ],
        ],
      ),
      body: _generating
          ? const _GeneratingView()
          : _error != null
              ? _ErrorView(
                  error: _error!,
                  onRetry: _generatePdf,
                )
              : _PdfView(bytes: _pdfBytes!),
      bottomNavigationBar: _pdfBytes != null
          ? _ActionBar(
              onShare: _sharePdf,
              onPrint: _printPdf,
              onSave: _saveToFiles,
            )
          : null,
    );
  }
}

// ─── Generating placeholder ────────────────────────────────────────────────────

class _GeneratingView extends StatefulWidget {
  const _GeneratingView();

  @override
  State<_GeneratingView> createState() => _GeneratingViewState();
}

class _GeneratingViewState extends State<_GeneratingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated tile grid
          RotationTransition(
            turns: _anim,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.amberGlow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.grid_on_rounded,
                size: 30,
                color: AppTheme.amber,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Building your quote…',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textHigh,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Laying tiles one by one',
            style: TextStyle(fontSize: 12, color: AppTheme.textLow),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline,
                  size: 32, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF generation failed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textHigh,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textLow, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TmAmberButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PDF preview (uses printing package's PdfPreview widget) ──────────────────

class _PdfView extends StatelessWidget {
  final Uint8List bytes;

  const _PdfView({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (_) async => bytes,
      allowPrinting: false,       // handled by our own action bar
      allowSharing: false,        // handled by our own action bar
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      pdfPreviewPageDecoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      loadingWidget: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.amber),
        ),
      ),
      scrollViewDecoration: const BoxDecoration(
        color: AppTheme.bg,
      ),
    );
  }
}

// ─── Bottom action bar ────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onPrint;
  final VoidCallback onSave;

  const _ActionBar({
    required this.onShare,
    required this.onPrint,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: onShare,
              primary: true,
            ),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: onPrint,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.save_outlined,
            label: 'Save',
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
