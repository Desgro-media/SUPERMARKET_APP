import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import 'app_icon.dart';
import 'pressable.dart';

enum BtnKind { primary, outline, light, dark }

/// The web app's `.btn`: a pill with an optional icon. [height]/[fontSize]/[horizontal] default to the standard 44px button.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.kind = BtnKind.primary,
    this.icon,
    this.trailingIcon,
    this.height = 44,
    this.fontSize = 15,
    this.horizontal = 20,
    this.expand = false,
    this.iconSize = 18,
  });

  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final String? icon, trailingIcon;
  final double height, fontSize, horizontal, iconSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (Color bg, Color fg, Color border, List<BoxShadow> shadow) = switch (kind) {
      BtnKind.primary => (t.brand, t.onBrand, Colors.transparent, t.shadowBrand),
      BtnKind.outline => (t.surface, t.text, t.line, const <BoxShadow>[]),
      BtnKind.light => (Colors.white, const Color(0xFF13201A), Colors.transparent, const <BoxShadow>[]),
      BtnKind.dark => (t.ink, Colors.white, Colors.transparent, const <BoxShadow>[]),
    };
    final enabled = onTap != null;
    final body = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1.5),
        boxShadow: enabled ? shadow : null,
      ),
      child: DefaultTextStyle(
        style: ts(fontSize, w: FontWeight.w700, color: fg, height: 1.2),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[AppIcon(icon!, size: iconSize), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (trailingIcon != null) ...[const SizedBox(width: 8), AppIcon(trailingIcon!, size: iconSize)],
          ],
        ),
      ),
    );
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Opacity(opacity: enabled ? 1 : .5, child: body),
    );
  }
}

/// `.icon-btn`: a round tap target with an icon and an optional count badge.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 36,
    this.iconSize = 20,
    this.badge = 0,
    this.dot = false,
    this.color,
  });

  final String icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size, iconSize;
  final int badge;
  final bool dot;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      scale: .92,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AppIcon(icon, size: iconSize, color: color ?? t.text),
            if (badge > 0) PositionedDirectional(top: 1, end: 0, child: CountBadge(badge)),
            if (dot)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: t.brand, shape: BoxShape.circle, border: Border.all(color: t.surface, width: 2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.count`: the small round number on the cart and wishlist icons.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.bg, this.fg, this.border});

  final int count;
  final Color? bg, fg, border;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? t.badgeBg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: ts(10, w: FontWeight.w800, color: fg ?? t.badgeFg, height: 1),
      ),
    );
  }
}
