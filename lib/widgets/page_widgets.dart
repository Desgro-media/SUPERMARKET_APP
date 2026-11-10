import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import 'app_icon.dart';
import 'pressable.dart';

/// `.crumbs`: "Home > Account > Profile". Items with a callback are tappable; the last one is the current page.
class Crumbs extends StatelessWidget {
  const Crumbs(this.items, {super.key});

  final List<(String, VoidCallback?)> items;

  /// The usual start of the trail.
  static (String, VoidCallback?) get home => ('Home', AppNav.goHome);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) AppIcon('right', size: 14, color: t.muted),
            items[i].$2 == null
                ? Text(context.tr(items[i].$1), style: ts(12, w: FontWeight.w600, color: t.text))
                : Pressable(
                    onTap: items[i].$2,
                    scale: .97,
                    child: Text(context.tr(items[i].$1), style: ts(12, w: FontWeight.w600, color: t.muted)),
                  ),
          ],
        ],
      ),
    );
  }
}

/// `.page-title`: the big heading of a page.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(12, 14, 12, 12)});

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(context.tr(text), style: ts(24, w: FontWeight.w800, color: context.t.text, height: 1.15, ls: -.02)),
      );
}

/// `.card-box`: a white rounded card with a thin border and soft shadow, optionally with a heading.
class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.title, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(18), boxShadow: t.shadow1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(context.tr(title!), style: ts(16, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
            ),
          child,
        ],
      ),
    );
  }
}

/// `.empty`: a big emoji, a title, a sentence and one or two buttons, centred.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, this.text, this.actions = const [], this.tall = false});

  final String emoji, title;
  final String? text;
  final List<Widget> actions;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: tall ? 56 : 36),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48, height: 1)),
          const SizedBox(height: 16),
          Text(context.tr(title), textAlign: TextAlign.center, style: ts(20, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
          if (text != null) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(context.tr(text!), textAlign: TextAlign.center, style: ts(14, color: t.muted)),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 22),
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}

/// `.stars`: five stars filled up to [rating] (4.6 fills four stars and 60% of the fifth).
class StarRating extends StatelessWidget {
  const StarRating(this.rating, {super.key, this.size = 14});

  final double rating, size;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final r = (rating / 5).clamp(0.0, 1.0);
    return Semantics(
      label: context.tr('Rated ${rating.toStringAsFixed(1)} out of 5'),
      child: ExcludeSemantics(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [t.star, t.star, t.line, t.line],
            stops: [0, r, r, 1],
          ).createShader(rect),
          child: Text('★★★★★', style: ts(size, color: Colors.white, height: 1, ls: 1 / size)),
        ),
      ),
    );
  }
}

/// `.bar`: a thin progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar(this.percent, {super.key, required this.color, this.track, this.height = 6});

  final double percent; // 0..100
  final Color color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track ?? context.t.surface2)),
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: (percent / 100).clamp(0.0, 1.0),
                  child: ColoredBox(color: color),
                ),
              ),
            ],
          ),
        ),
      );
}

/// `.avatar`: a round badge with a letter.
class Avatar extends StatelessWidget {
  const Avatar(this.letter, {super.key, this.size = 42, this.fontSize = 16});

  final String letter;
  final double size, fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.brand50, shape: BoxShape.circle),
      child: Text(letter, style: ts(fontSize, w: FontWeight.w800, color: t.brand600, height: 1.2)),
    );
  }
}

/// `.status`: the small pill with an order's progress ("Packing"); the delivered one is green.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.delivered});

  final String label;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: delivered ? t.good50 : t.accent50, borderRadius: BorderRadius.circular(999)),
      child: Text(
        context.tr(label),
        style: ts(13, w: FontWeight.w800, color: delivered ? t.good : (t.dark ? t.accent : t.badgeBg), height: 1.3),
      ),
    );
  }
}

/// `.hint`: a small grey note under a form or list.
class Hint extends StatelessWidget {
  const Hint(this.text, {super.key, this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(context.tr(text), textAlign: align, style: ts(13, color: context.t.muted)),
      );
}

/// A thin dashed line (the dotted separators in totals and tracker rows).
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _DashPainter(color)));
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset((x + 3).clamp(0, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
