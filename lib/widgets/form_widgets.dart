import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../core/i18n.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// A labelled text field with an error line (`.field` in the web app): a 12px-rounded box that gets a brand-coloured
/// ring when focused and a red one when it has an error.
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.required = false,
    this.maxLines = 1,
    this.hint,
    this.onBlur,
    this.minLines,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;

  /// Shown under the field in red; also turns the border red.
  final String? error;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted, onChanged;
  final bool required;
  final int maxLines;
  final int? minLines, maxLength;
  final String? hint;

  /// Called when the field loses focus (the web app validates a field as you leave it).
  final VoidCallback? onBlur;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final FocusNode _focus = FocusNode();
  bool _hadFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_hadFocus && !_focus.hasFocus) widget.onBlur?.call();
      _hadFocus = _focus.hasFocus;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text.rich(
            TextSpan(
              text: widget.label,
              children: [if (widget.required) TextSpan(text: ' *', style: TextStyle(color: t.danger))],
            ),
            style: ts(13, w: FontWeight.w700, color: t.text),
          ),
          const SizedBox(height: 4),
        ],
        ListenableBuilder(
          listenable: _focus,
          builder: (context, _) {
            final focus = _focus.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              alignment: AlignmentDirectional.centerStart,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasError ? t.danger : (focus ? t.brand : t.line), width: 1.5),
                boxShadow: hasError
                    ? [BoxShadow(color: t.danger.withValues(alpha: .14), spreadRadius: 4)]
                    : (focus ? [BoxShadow(color: t.brand50, spreadRadius: 4)] : null),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: widget.keyboardType,
                autofillHints: widget.autofillHints,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted,
                onChanged: widget.onChanged,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                cursorColor: t.brand,
                style: ts(16, color: t.text, height: 1.3),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: ts(16, color: t.muted, height: 1.3),
                ),
              ),
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.error!, style: ts(13, w: FontWeight.w600, color: t.danger, height: 1.4)),
          ),
      ],
    );
  }
}

/// `.seg`: a pill holding two or three choices, the chosen one raised on a white chip.
class SegButtons<T> extends StatelessWidget {
  const SegButtons({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Pressable(
              onTap: () => onChanged(options[i].$1),
              scale: .96,
              semanticLabel: options[i].$2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: options[i].$1 == value ? t.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: options[i].$1 == value ? t.shadow1 : null,
                ),
                child: Text(
                  options[i].$2,
                  style: ts(13.5, w: FontWeight.w700, color: options[i].$1 == value ? t.text : t.muted, height: 1.2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// A select-like field (the web's <select>): a label and a boxed value with a chevron. Tapping it calls [onTap],
/// which normally opens a choice sheet.
class SelectField extends StatelessWidget {
  const SelectField({super.key, required this.label, required this.value, required this.onTap, this.required = false});

  final String label, value;
  final VoidCallback onTap;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(text: label, children: [if (required) TextSpan(text: ' *', style: TextStyle(color: t.danger))]),
          style: ts(13, w: FontWeight.w700, color: t.text),
        ),
        const SizedBox(height: 4),
        Pressable(
          onTap: onTap,
          scale: .99,
          semanticLabel: label,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: Text(value, style: ts(16, color: t.text, height: 1.3))),
                AppIcon('down', size: 16, color: t.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `.opt-card`: a big radio choice with a title and a small description.
class OptCard extends StatelessWidget {
  const OptCard({super.key, required this.title, required this.subtitle, required this.selected, required this.onTap, this.enabled = true, this.titleIcon});

  final String title, subtitle;
  final bool selected, enabled;
  final VoidCallback onTap;
  final Widget? titleIcon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Pressable(
        onTap: enabled ? onTap : null,
        scale: .99,
        semanticLabel: title,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(46, 12, 14, 12),
          decoration: BoxDecoration(
            color: selected ? t.brand50 : t.surface,
            border: Border.all(color: selected ? t.brand : t.line, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(context.tr(title), style: ts(14, w: FontWeight.w700, color: t.text))),
                      if (titleIcon != null) ...[const SizedBox(width: 6), titleIcon!],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(context.tr(subtitle), style: ts(13, color: t.muted)),
                ],
              ),
              PositionedDirectional(
                start: -31,
                top: 3,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? t.brand : t.muted.withValues(alpha: .6), width: 2),
                    color: selected ? t.brand : Colors.transparent,
                  ),
                  child: selected ? Container(width: 6, height: 6, decoration: BoxDecoration(color: t.onBrand, shape: BoxShape.circle)) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.opt` / `.switch`: a row in the filter sheet with a checkbox, radio or switch.
enum ToggleStyle { checkbox, radio, toggle }

class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.label, required this.value, required this.onChanged, this.style = ToggleStyle.checkbox, this.count});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ToggleStyle style;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final Widget mark = switch (style) {
      ToggleStyle.toggle => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 24,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: value ? t.brand : t.muted.withValues(alpha: .4), borderRadius: BorderRadius.circular(999)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1))]),
            ),
          ),
        ),
      _ => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value ? t.brand : Colors.transparent,
            shape: style == ToggleStyle.radio ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: style == ToggleStyle.radio ? null : BorderRadius.circular(6),
            border: Border.all(color: value ? t.brand : t.muted.withValues(alpha: .6), width: 2),
          ),
          child: !value
              ? null
              : (style == ToggleStyle.radio
                  ? Container(width: 8, height: 8, decoration: BoxDecoration(color: t.onBrand, shape: BoxShape.circle))
                  : AppIcon('check', size: 13, color: t.onBrand, stroke: 3.2)),
        ),
    };
    final text = Text(label, style: ts(14, w: value && style != ToggleStyle.toggle ? FontWeight.w700 : (style == ToggleStyle.toggle ? FontWeight.w600 : FontWeight.w500), color: t.text, height: 1.4));
    return Pressable(
      onTap: () => onChanged(!value),
      scale: .99,
      semanticLabel: label,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: style == ToggleStyle.toggle ? 7 : 7, horizontal: 0),
        child: Row(
          children: [
            if (style != ToggleStyle.toggle) ...[mark, const SizedBox(width: 10)],
            Expanded(child: text),
            if (count != null) Text('$count', style: ts(12.5, color: t.muted, tabular: true)),
            if (style == ToggleStyle.toggle) mark,
          ],
        ),
      ),
    );
  }
}