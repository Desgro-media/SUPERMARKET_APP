import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../data/models.dart';
import '../../data/sorting.dart';
import '../../state/actions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/pressable.dart';
import '../../widgets/product_art.dart';
import '../../widgets/product_card.dart';
import '../../widgets/ui_bits.dart';

// ------------------------------------------------------------------------------------------------ promo cards + trust bar

/// The two small banners under the hero ("Care & grooming", "Spotless home").
class PromoCards extends ConsumerWidget {
  const PromoCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);

    Widget card({required Color bg, required String eyebrow, required String title, required int photo, required String route, required Map<String, dynamic> args}) {
      final p = cat.byId[photo]!;
      return Pressable(
        onTap: () => AppNav.go(route, args),
        scale: .98,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Eyebrow(context.tr(eyebrow), size: 9.5, color: t.text, ls: .12),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 6),
                      child: Text(context.tr(title), style: ts(14.5, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                    ),
                    LinkMore(context.tr('Shop now'), color: t.text, size: 12, iconSize: 13, gap: 4, onTap: () => AppNav.go(route, args)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Transform.rotate(
                angle: 8 * math.pi / 180,
                child: Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 12))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PhotoOrEmoji(src: p.hasPhoto ? p.imgs[0] : '', emoji: p.emoji, emojiSize: 28, cacheWidth: 200),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: card(
              bg: AppTokens.mix(t.sun, t.dark ? .22 : .52, t.surface),
              eyebrow: 'Care & grooming',
              title: 'Brushes, razors & more',
              photo: 6412,
              route: Routes.shop,
              args: const {'dept': 'beauty'},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: card(
              bg: AppTokens.mix(t.brand, t.dark ? .22 : .14, t.surface),
              eyebrow: 'Spotless home',
              title: 'Cleaning & kitchen',
              photo: 6394,
              route: Routes.shop,
              args: const {'dept': 'home'},
            ),
          ),
        ],
      ),
    );
  }
}

/// The four reasons to shop here: free delivery, express, returns, secure checkout.
class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = [
      ('truck', 'Free delivery', t.brand50, t.brand600),
      ('zap', '60-minute express', t.accent50, t.badgeBg),
      ('refresh', 'Easy returns', t.sun50, t.dark ? t.sun : const Color(0xFF8A6200)),
      ('shield', 'Secure checkout', t.good50, t.good),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, label, bg, fg) in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
                      child: AppIcon(icon, size: 18, color: fg),
                    ),
                    const SizedBox(height: 5),
                    Text(context.tr(label), textAlign: TextAlign.center, style: ts(10.5, w: FontWeight.w700, color: t.text, height: 1.2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ categories

/// "Shop by category": two rows of round-photo tiles that scroll sideways (`.cat-grid`).
class CategoryRail extends ConsumerWidget {
  const CategoryRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cats = ref.watch(catalogueProvider).categories;
    final nameStyle = ts(11, w: FontWeight.w700, color: t.text, height: 1.2);
    const tileW = 78.0;

    // the real height of a name (it can take up to 3 lines, and Bengali / Arabic lines are taller)
    double textHeight(String text) => (TextPainter(
          text: TextSpan(text: text, style: nameStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          textAlign: TextAlign.center,
          maxLines: 4,
        )..layout(maxWidth: tileW - 10))
            .height;

    // CSS grid rows are as tall as their tallest tile
    final names = [for (final c in cats) context.tr(c.name)];
    final rowText = [0.0, 0.0];
    for (var i = 0; i < cats.length; i++) {
      rowText[i % 2] = math.max(rowText[i % 2], textHeight(names[i]));
    }
    // 1 border + 9 top padding + 48 picture + 5 gap + text + 8 bottom padding + 1 border (+1 spare for rounding)
    final rowH = [for (final h in rowText) 1 + 9 + 48 + 5 + h + 8 + 1 + 1];

    Widget tile(int i) {
      final c = cats[i];
      return Pressable(
        onTap: () => AppNav.go(Routes.shop, {'cat': c.id}),
        scale: .97,
        semanticLabel: names[i],
        child: Container(
          width: tileW,
          height: rowH[i % 2],
          padding: const EdgeInsets.fromLTRB(4, 9, 4, 8),
          decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: t.tinted(c.tint), shape: BoxShape.circle),
                child: PhotoOrEmoji(src: c.thumb, emoji: c.emoji, emojiSize: 25, cacheWidth: 160),
              ),
              const SizedBox(height: 5),
              Text(names[i], textAlign: TextAlign.center, maxLines: 4, style: nameStyle),
            ],
          ),
        ),
      );
    }

    final columns = (cats.length / 2).ceil();
    return SizedBox(
      height: rowH[0] + 8 + rowH[1] + 10,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) const SizedBox(width: 8),
              Column(
                children: [
                  tile(c * 2),
                  if (c * 2 + 1 < cats.length) ...[const SizedBox(height: 8), tile(c * 2 + 1)],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ deals

/// Today's deals: the biggest discounts, with a clock counting down to midnight.
class DealsBand extends ConsumerWidget {
  const DealsBand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final deals = sortedStable(cat.products.where((p) => p.off > 0 && p.inStock), (a, b) => b.off.compareTo(a.off)).take(10).toList();
    // (the web band reaches 4px past the page margin; the home page gives this section 8px side margins instead)
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      decoration: BoxDecoration(
        color: t.accent50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.accent.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHead(
            title: context.tr("Today's deals"),
            sub: context.tr('Prices refresh at midnight'),
            icon: 'zap',
            iconColor: t.accent,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Countdown(),
                const SizedBox(width: 8),
                LinkMore(context.tr('View all'), onTap: () => AppNav.go(Routes.shop, {'deal': '1'})),
              ],
            ),
          ),
          ProductScroller(products: deals, padding: const EdgeInsets.only(bottom: 10)),
        ],
      ),
    );
  }
}

/// A sideways row of product cards (`.scroller`): 138dp wide cards on phones.
class ProductScroller extends StatelessWidget {
  const ProductScroller({super.key, required this.products, this.padding = const EdgeInsets.only(bottom: 10)});

  final List<Product> products;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => HScroller(
        gap: 8,
        padding: padding,
        children: [for (final p in products) SizedBox(width: 138, child: ProductCard(p, key: ValueKey(p.id)))],
      );
}

/// Hours, minutes and seconds left until midnight.
class Countdown extends StatefulWidget {
  const Countdown({super.key});

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day + 1);
    final s = end.difference(now).inSeconds;
    String two(int n) => n.toString().padLeft(2, '0');

    Widget cd(String unit, int v) => Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: t.text, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(two(v), style: ts(14, w: FontWeight.w800, color: t.bg, height: 1.1, tabular: true)),
              Text(unit.toUpperCase(), style: ts(8, w: FontWeight.w700, color: t.bg.withValues(alpha: .7), height: 1.1)),
            ],
          ),
        );

    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(':', style: ts(14, w: FontWeight.w800, color: t.muted, height: 1.1)),
    );
    return Semantics(
      label: context.tr("Time left on today's deals"),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [cd('h', s ~/ 3600), sep, cd('m', s % 3600 ~/ 60), sep, cd('s', s % 60)],
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ popular

const Map<String, int> _deptCaps = {'grocery': 4, 'beauty': 3, 'home': 2, 'baby': 1};

/// A balanced "popular" list so the home page shows every department, not just food.
List<Product> balancedPopular(Catalogue cat, int n) {
  final out = <Product>[];
  final count = <String, int>{};
  for (final p in sortedStable(cat.products, (a, b) => b.pop.compareTo(a.pop))) {
    if (out.length < n && (count[p.dept] ?? 0) < (_deptCaps[p.dept] ?? 2)) {
      out.add(p);
      count[p.dept] = (count[p.dept] ?? 0) + 1;
    }
  }
  return out;
}

/// New arrivals, taking one department at a time in rotation.
List<Product> mixedNew(Catalogue cat, int n) {
  final by = <String, List<Product>>{};
  for (final p in cat.products.where((p) => p.isNew)) {
    (by[p.dept] ??= []).add(p);
  }
  final out = <Product>[];
  var more = true;
  while (out.length < n && more) {
    more = false;
    for (final d in cat.depts) {
      final q = by[d.id];
      if (q != null && q.isNotEmpty && out.length < n) {
        out.add(q.removeAt(0));
        more = true;
      }
    }
  }
  return out;
}

/// "Popular right now" with a pill tab per department.
class PopularSection extends ConsumerStatefulWidget {
  const PopularSection({super.key});

  @override
  ConsumerState<PopularSection> createState() => _PopularSectionState();
}

class _PopularSectionState extends ConsumerState<PopularSection> {
  String _dept = '';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final list = _dept.isEmpty
        ? balancedPopular(cat, 10)
        : sortedStable(cat.products.where((p) => p.dept == _dept), (a, b) => b.pop.compareTo(a.pop)).take(10).toList();

    Widget pill(String id, String label) {
      final on = _dept == id;
      return Pressable(
        onTap: () => setState(() => _dept = id),
        scale: .96,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? t.text : t.surface,
            border: Border.all(color: on ? t.text : t.line, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: ts(12.5, w: FontWeight.w700, color: on ? t.bg : t.text, height: 1.2)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(title: context.tr('Popular right now'), sub: context.tr('What your neighbours are adding to their baskets')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              pill('', context.tr('All')),
              for (final d in cat.depts) ...[const SizedBox(width: 6), pill(d.id, context.tr(d.name))],
            ],
          ),
        ),
        const SizedBox(height: 10),
        ProductGrid(products: list),
      ],
    );
  }
}

// ------------------------------------------------------------------------------------------------ baby banner

class WidePromo extends ConsumerWidget {
  const WidePromo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);

    Widget tile(int id, {double degrees = 0, double dy = 0}) {
      final p = cat.byId[id]!;
      return Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(
          angle: degrees * math.pi / 180,
          child: Container(
            width: 65,
            height: 65,
            padding: const EdgeInsets.all(2.3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.4),
              boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 14, offset: Offset(0, 14))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PhotoOrEmoji(src: p.hasPhoto ? p.imgs[0] : '', emoji: p.emoji, emojiSize: 40, cacheWidth: 240),
            ),
          ),
        ),
      );
    }

    return Pressable(
      onTap: () => AppNav.go(Routes.shop, {'dept': 'baby'}),
      scale: .99,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(color: t.wide, borderRadius: BorderRadius.circular(20)),
        child: DefaultTextStyle(
          style: ts(14, color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [tile(6451, degrees: -9), const SizedBox(width: 8), tile(6452, dy: -10), const SizedBox(width: 8), tile(6450, degrees: 9)],
                ),
              ),
              const SizedBox(height: 6),
              Eyebrow(context.tr('Baby & kids'), size: 12, color: Colors.white, ls: .12),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text(context.tr('Everything for little ones'), style: ts(20, w: FontWeight.w800, color: Colors.white, height: 1.15, ls: -.02)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  context.tr('Nappies, wipes, feeding essentials and toys — gentle, safe and delivered fast.'),
                  style: ts(13, color: Colors.white.withValues(alpha: .9)),
                ),
              ),
              AppButton(
                label: context.tr('Shop baby & kids'),
                kind: BtnKind.light,
                trailingIcon: 'arrow',
                height: 36,
                fontSize: 13,
                horizontal: 14,
                onTap: () => AppNav.go(Routes.shop, {'dept': 'baby'}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ brands + newsletter

class BrandRow extends ConsumerWidget {
  const BrandRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final brands = ref.watch(catalogueProvider).brands;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final b in brands)
          Pressable(
            onTap: () => AppNav.go(Routes.shop, {'brand': b}),
            scale: .96,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(11)),
              child: Text(context.tr(b), style: ts(12.5, w: FontWeight.w700, color: t.text, height: 1.5)),
            ),
          ),
      ],
    );
  }
}

class NewsletterBox extends ConsumerStatefulWidget {
  const NewsletterBox({super.key});

  @override
  ConsumerState<NewsletterBox> createState() => _NewsletterBoxState();
}

class _NewsletterBoxState extends ConsumerState<NewsletterBox> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final actions = ref.read(actionsProvider);
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim())) {
      actions.toast('Please enter a valid email address');
      return;
    }
    _email.clear();
    FocusScope.of(context).unfocus();
    actions.toast("Thanks! You're on the list.");
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: t.brand50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.brand.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('Deals in your inbox'), style: ts(18, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
          const SizedBox(height: 4),
          Text(context.tr('Weekly offers across every department. No spam, unsubscribe any time.'), style: ts(12.5, color: t.muted)),
          const SizedBox(height: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(999)),
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submit(),
              cursorColor: t.brand,
              style: ts(16, color: t.text, height: 1.2),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'you@example.com',
                hintStyle: ts(16, color: t.muted, height: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(label: context.tr('Subscribe'), height: 42, expand: true, onTap: _submit),
        ],
      ),
    );
  }
}
