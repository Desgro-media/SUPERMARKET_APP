import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// `.badge`: the small coloured tag on a product photo ("-21%", "New", "Sold out").
class TagBadge extends StatelessWidget {
  const TagBadge(this.text, {super.key, required this.bg, required this.fg});

  final String text;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: ts(10, w: FontWeight.w800, color: fg, height: 1, ls: .01)),
      );
}

/// A price: the currency in small faded type and the amount in bold ("SAR 14.95").
class Money extends ConsumerWidget {
  const Money(this.amount, {super.key, this.size = 14.5, this.weight = FontWeight.w800, this.color, this.ls = -.02, this.prefix = ''});

  final double amount;

  /// Shown before the currency, e.g. "−" for a discount.
  final String prefix;
  final double size;
  final FontWeight weight;
  final Color? color;
  final double ls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cur = context.tr(ref.watch(catalogueProvider).config.currency);
    final c = color ?? context.t.text;
    return Text.rich(
      TextSpan(
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          TextSpan(
            text: cur,
            style: ts(size * .66, w: FontWeight.w700, color: c.withValues(alpha: .6), height: 1.16),
          ),
          TextSpan(text: ' ${fmt2(amount)}'),
        ],
      ),
      style: ts(size, w: weight, color: c, height: 1.16, ls: ls, tabular: true),
      maxLines: 1,
      softWrap: false,
    );
  }
}

/// `.eyebrow`: small spaced-out capitals above a heading.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.size = 10, this.color, this.opacity = .85, this.ls = .1});

  final String text;
  final double size, opacity, ls;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: ts(size, w: FontWeight.w800, color: (color ?? DefaultTextStyle.of(context).style.color)?.withValues(alpha: opacity), ls: ls),
      );
}

/// `.link-more`: "View all ->" in the brand colour.
class LinkMore extends StatelessWidget {
  const LinkMore(this.label, {super.key, required this.onTap, this.color, this.size = 12.5, this.iconSize = 16, this.gap = 6});

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double size, iconSize, gap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.t.brand600;
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: DefaultTextStyle(
        style: ts(size, w: FontWeight.w700, color: c),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, maxLines: 1, softWrap: false)),
            SizedBox(width: gap),
            AppIcon('arrow', size: iconSize),
          ],
        ),
      ),
    );
  }
}

/// `.section-head`: a heading with an optional sub-line and a right-hand link.
class SectionHead extends StatelessWidget {
  const SectionHead({super.key, required this.title, this.sub, this.trailing, this.icon, this.iconColor});

  final String title;
  final String? sub;
  final Widget? trailing;
  final String? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 12,
        runSpacing: 4,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[AppIcon(icon!, size: 20, color: iconColor ?? t.text), const SizedBox(width: 6)],
                  Text(title, style: ts(18, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                ],
              ),
              if (sub != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(sub!, style: ts(12, color: t.muted)),
                ),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Children laid out in rows of [columns], every cell as tall as the tallest cell of its row (a CSS grid with auto rows).
class EqualHeightGrid extends StatelessWidget {
  const EqualHeightGrid({super.key, required this.children, required this.columns, this.gap = 8});

  final List<Widget> children;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) cells.add(SizedBox(width: gap));
        final k = i + c;
        cells.add(Expanded(child: k < children.length ? children[k] : const SizedBox.shrink()));
      }
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)),
      ));
    }
    return Column(children: rows);
  }
}

/// A row of fixed-width cards that scrolls sideways; all cards share the height of the tallest (`.scroller`).
class HScroller extends StatelessWidget {
  const HScroller({super.key, required this.children, this.gap = 8, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final double gap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: padding,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                children[i],
              ],
            ],
          ),
        ),
      );
}
