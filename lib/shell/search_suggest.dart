import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../data/search.dart';
import '../state/store.dart';
import '../widgets/app_icon.dart';
import '../widgets/pressable.dart';
import '../widgets/product_art.dart';
import '../widgets/ui_bits.dart';

const List<String> kTrendingSearches = ['Milk', 'Razor', 'Toothbrush', 'Shampoo', 'Batteries', 'Detergent'];

/// The panel that drops down from the search bar: recent and trending searches while it is empty,
/// matching categories and products while typing (`.suggest` in the web app).
class SearchSuggestions extends ConsumerWidget {
  const SearchSuggestions({super.key, required this.query, required this.onDone});

  final String query;

  /// Called after the visitor picks something, so the panel can close.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final store = ref.watch(storeProvider);
    final q = query.trim();
    final maxH = (MediaQuery.sizeOf(context).height * .7).clamp(0.0, 560.0);

    void go(String route, Map<String, dynamic> args) {
      onDone();
      AppNav.go(route, args);
    }

    Widget head(String label, {Widget? action}) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr(label).toUpperCase(), style: ts(12, w: FontWeight.w800, color: t.muted, ls: .08)),
              ?action,
            ],
          ),
        );

    Widget item({required VoidCallback onTap, required Widget icon, required Widget main, Widget? trailing}) => Pressable(
          onTap: onTap,
          scale: .98,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: main),
                if (trailing != null) ...[const SizedBox(width: 12), trailing],
              ],
            ),
          ),
        );

    Widget iconBox({required Widget child, Color? tint, bool round = false}) => Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint == null ? t.surface2 : t.tinted(tint),
            borderRadius: round ? null : BorderRadius.circular(12),
            shape: round ? BoxShape.circle : BoxShape.rectangle,
          ),
          child: child,
        );

    final children = <Widget>[];
    if (q.isEmpty) {
      if (store.searches.isNotEmpty) {
        children.add(head(
          'Recent',
          action: Pressable(
            onTap: () => ref.read(storeProvider.notifier).clearSearches(),
            child: Text(context.tr('Clear'), style: ts(13, w: FontWeight.w700, color: t.brand600)),
          ),
        ));
        for (final r in store.searches) {
          children.add(item(
            onTap: () => go(Routes.shop, {'q': r}),
            icon: iconBox(child: AppIcon('clock', size: 18, color: t.muted)),
            main: Text(r, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, w: FontWeight.w600, color: t.text)),
          ));
        }
      }
      children.add(head('Trending'));
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in kTrendingSearches)
              Pressable(
                onTap: () => go(Routes.shop, {'q': w}),
                scale: .96,
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surface,
                    border: Border.all(color: t.line, width: 1.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(context.tr(w), style: ts(12, w: FontWeight.w600, color: t.text, height: 1.2)),
                ),
              ),
          ],
        ),
      ));
    } else {
      final lower = q.toLowerCase();
      final translate = context.tr;
      final prods = searchProducts(cat, q, limit: 6, translate: translate);
      final cats = cat.categories.where((c) => '${c.name} ${translate(c.name)}'.toLowerCase().contains(lower)).take(2).toList();
      if (prods.isEmpty && cats.isEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          child: Column(
            children: [
              Text(context.tr('No matches for “$q”'), textAlign: TextAlign.center, style: ts(14, w: FontWeight.w700, color: t.text)),
              const SizedBox(height: 4),
              Text(
                context.tr('Check the spelling or try a broader word like “milk” or “bread”.'),
                textAlign: TextAlign.center,
                style: ts(13, color: t.muted),
              ),
            ],
          ),
        ));
      } else {
        for (final c in cats) {
          children.add(item(
            onTap: () => go(Routes.shop, {'cat': c.id}),
            icon: iconBox(tint: c.tint, round: true, child: PhotoOrEmoji(src: c.thumb, emoji: c.emoji, emojiSize: 24)),
            main: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Highlighted(translate(c.name), q),
                Text(context.tr('Category'), maxLines: 1, style: ts(12.5, w: FontWeight.w500, color: t.muted)),
              ],
            ),
          ));
        }
        for (final p in prods) {
          children.add(item(
            onTap: () => go(Routes.product, {'id': p.id}),
            icon: iconBox(
              tint: cat.catById[p.cat]!.tint,
              child: PhotoOrEmoji(src: p.hasPhoto ? p.thumbs[0] : '', emoji: p.emoji, emojiSize: 24),
            ),
            main: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Highlighted(translate(p.name), q),
                Text('${translate(p.brand)} · ${translate(p.unit)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12.5, w: FontWeight.w500, color: t.muted)),
              ],
            ),
            trailing: Money(p.price, size: 14),
          ));
        }
        children.add(item(
          onTap: () => go(Routes.shop, {'q': q}),
          icon: iconBox(child: AppIcon('search', size: 18, color: t.muted)),
          main: Text(context.tr('See all results for “$q”'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, w: FontWeight.w600, color: t.text)),
          trailing: AppIcon('arrow', size: 16, color: t.muted),
        ));
      }
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(22),
        boxShadow: t.shadow2,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

/// A suggestion's name with the first typed word highlighted (`<mark>` in the web app).
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, this.query);

  final String text, query;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final style = ts(14, w: FontWeight.w600, color: t.text);
    final words = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final w = words.isEmpty ? '' : words.first;
    final i = w.isEmpty ? -1 : text.toLowerCase().indexOf(w);
    if (i < 0) return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(text: text.substring(i, i + w.length), style: TextStyle(backgroundColor: t.brand.withValues(alpha: .22))),
          TextSpan(text: text.substring(i + w.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
