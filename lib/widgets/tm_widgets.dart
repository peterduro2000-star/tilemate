import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ─── TmCard ───────────────────────────────────────────────────────────────────

class TmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool highlight;

  const TmCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppTheme.amber : AppTheme.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }
}

// ─── TmSectionLabel ───────────────────────────────────────────────────────────

class TmSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const TmSectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.textLow,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(height: 1)),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ─── TmTextField ─────────────────────────────────────────────────────────────

class TmTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefix;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final int? maxLines;
  final FocusNode? focusNode;

  const TmTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.suffix,
    this.prefix,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      maxLines: maxLines,
      focusNode: focusNode,
      style: const TextStyle(
        color: AppTheme.textHigh,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        prefixIcon: prefix,
      ),
    );
  }
}

// ─── TmNumericField ───────────────────────────────────────────────────────────

class TmNumericField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? unit;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool allowDecimal;

  const TmNumericField({
    super.key,
    required this.label,
    this.hint,
    this.unit,
    this.controller,
    this.validator,
    this.onChanged,
    this.allowDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return TmTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      validator: validator,
      onChanged: onChanged,
      suffix: unit != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                unit!,
                style: const TextStyle(
                  color: AppTheme.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
    );
  }
}

// ─── TmStatChip ──────────────────────────────────────────────────────────────

class TmStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const TmStatChip({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textLow,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: valueColor ?? AppTheme.amber),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: valueColor ?? AppTheme.textHigh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TmAmberButton ────────────────────────────────────────────────────────────

class TmAmberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const TmAmberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppTheme.bg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ─── TmPatternSelector ───────────────────────────────────────────────────────
// FIX: now strongly typed — receives and emits LayoutPattern directly.
// No more String key comparison that was silently failing.

class TmPatternSelector extends StatelessWidget {
  final LayoutPattern selected;
  final void Function(LayoutPattern) onChanged;

  const TmPatternSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _symbols = <LayoutPattern, String>{
    LayoutPattern.straight:    '▦',
    LayoutPattern.diagonal:    '◈',
    LayoutPattern.herringbone: '⟫',
    LayoutPattern.brick:       '▬',
    LayoutPattern.versailles:  '✦',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LayoutPattern.values.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final pattern = LayoutPattern.values[i];
          final isSelected = selected == pattern;
          final symbol = _symbols[pattern] ?? '▦';

          return GestureDetector(
            onTap: () => onChanged(pattern),  // ← passes LayoutPattern directly
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 82,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.amberGlow : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.amber : AppTheme.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 20,
                      color: isSelected ? AppTheme.amber : AppTheme.textMid,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pattern.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.amber : AppTheme.textMid,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '~${pattern.baseWastagePercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 9, color: AppTheme.textLow),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── TmDivider ────────────────────────────────────────────────────────────────

class TmDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const TmDivider({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: AppTheme.border,
    );
  }
}

// ─── TmEmptyState ─────────────────────────────────────────────────────────────

class TmEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, size: 32, color: AppTheme.textLow),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              TmAmberButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── TmStatusBadge ────────────────────────────────────────────────────────────

class TmStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const TmStatusBadge({super.key, required this.label, required this.color});

  factory TmStatusBadge.fromStatus(String statusName) {
    final (label, color) = switch (statusName) {
      'draft'      => ('Draft', AppTheme.textLow),
      'quoted'     => ('Quoted', AppTheme.info),
      'accepted'   => ('Accepted', AppTheme.success),
      'inProgress' => ('In Progress', AppTheme.amber),
      'completed'  => ('Completed', AppTheme.success),
      'cancelled'  => ('Cancelled', AppTheme.error),
      _            => ('Unknown', AppTheme.textLow),
    };
    return TmStatusBadge(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
