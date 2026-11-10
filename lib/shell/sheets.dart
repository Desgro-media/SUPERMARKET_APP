import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../data/models.dart';
import '../state/actions.dart';
import '../state/store.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/pressable.dart';
import '../widgets/product_art.dart';
import '../widgets/ui_bits.dart';

/// Slides a sheet up from the bottom over everything, with the web app's dark scrim.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      // the app's root navigator, so the sheet and its dark scrim cover the header and bottom bar too
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: const Color(0x8C08120C),
      builder: builder,
    );

/// The white card of a sheet: rounded top corners, a close button, scrolls when it is taller than 88% of the screen (`.modal-card`).
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final media = MediaQuery.of(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: media.size.height * .88),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: t.shadow2,
      ),
      child: Stack(
        children: [
          // shrinkWrap: the sheet is as tall as its content, and scrolls only when that is more than 88% of the screen
          ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18, 22, 18, 22 + media.viewPadding.bottom),
            children: [child],
          ),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: IconCircleButton(
              icon: 'x',
              size: 44,
              iconSize: 20,
              semanticLabel: context.tr('Close'),
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sheetTitle(BuildContext context, String text) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 32),
      child: Text(context.tr(text), style: ts(20, w: FontWeight.w800, color: context.t.text, height: 1.15, ls: -.02)),
    );

// ---------------------------------------------------------------------------------------------------- a list of choices

/// A sheet with a title and a list of options with the current one ticked; returns the chosen value
/// (used for the sort order, the delivery city in forms ...).
Future<T?> showChoiceSheet<T>(BuildContext context, {required String title, required List<(T, String)> options, required T current}) =>
    showAppSheet<T>(context, (sheetContext) {
      final t = sheetContext.t;
      return SheetFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTitle(sheetContext, title),
            const SizedBox(height: 14),
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Pressable(
                onTap: () => Navigator.of(sheetContext).pop(options[i].$1),
                scale: .98,
                semanticLabel: options[i].$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: options[i].$1 == current ? t.brand50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: options[i].$1 == current ? t.brand : t.line, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(sheetContext.tr(options[i].$2), style: ts(14, w: FontWeight.w700, color: t.text))),
                      if (options[i].$1 == current) AppIcon('check', size: 18, color: t.brand600),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });

// ---------------------------------------------------------------------------------------------------- delivery city

Future<void> showAreaSheet(BuildContext context) => showAppSheet<void>(context, (_) => const _AreaSheet());

class _AreaSheet extends ConsumerWidget {
  const _AreaSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cfg = ref.watch(catalogueProvider).config;
    final cur = ref.watch(storeProvider.select((s) => s.area)) ?? cfg.areas.first;
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetTitle(context, 'Where should we deliver?'),
          const SizedBox(height: 14),
          Text(context.tr('Delivery times and availability depend on your city.'), style: ts(14, color: t.muted)),
          const SizedBox(height: 14),
          for (final a in cfg.areas) ...[
            Pressable(
              onTap: () {
                ref.read(storeProvider.notifier).setArea(a);
                Navigator.of(context).pop();
                ref.read(actionsProvider).toast('Delivering to $a');
              },
              scale: .98,
              semanticLabel: a,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: a == cur ? t.brand50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a == cur ? t.brand : t.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    AppIcon('pin', size: 18, color: a == cur ? t.brand600 : t.muted),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.tr(a), style: ts(14, w: FontWeight.w700, color: t.text))),
                    if (a == cur) AppIcon('check', size: 18, color: t.brand600),
                  ],
                ),
              ),
            ),
            if (a != cfg.areas.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------- categories

Future<void> showCategorySheet(BuildContext context) => showAppSheet<void>(context, (_) => const _CategorySheet());

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);

    void open(String route, Map<String, dynamic> args) {
      Navigator.of(context).pop();
      AppNav.go(route, args);
    }

    Widget tile({required Color tint, required Widget icon, required String label, required VoidCallback onTap}) => Pressable(
          onTap: onTap,
          scale: .96,
          semanticLabel: label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(color: t.tinted(tint), borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: ts(12, w: FontWeight.w700, color: t.text, height: 1.25)),
              ],
            ),
          ),
        );

    Widget emojiIcon(String e) => SizedBox(
          height: 58,
          child: Center(child: Text(e, style: const TextStyle(fontSize: 26, height: 1))),
        );

    Widget photoIcon(Category c) => Container(
          width: 58,
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: PhotoOrEmoji(src: c.thumb, emoji: c.emoji, emojiSize: 30),
        );

    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetTitle(context, 'Shop by category'),
          const SizedBox(height: 14),
          EqualHeightGrid(
            columns: 3,
            children: [
              tile(tint: const Color(0xFFFFE1C9), icon: emojiIcon('\u{1F525}'), label: context.tr('Deals'), onTap: () => open(Routes.shop, {'deal': '1'})),
              tile(tint: const Color(0xFFFFF0B8), icon: emojiIcon('✨'), label: context.tr('New arrivals'), onTap: () => open(Routes.shop, {'sort': 'new'})),
            ],
          ),
          for (final d in cat.depts) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr(d.name).toUpperCase(), style: ts(13, w: FontWeight.w800, color: t.muted, ls: .05)),
                Pressable(
                  onTap: () => open(Routes.shop, {'dept': d.id}),
                  child: Text(context.tr('See all'), style: ts(13, w: FontWeight.w700, color: t.brand600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EqualHeightGrid(
              columns: 3,
              children: [
                for (final c in cat.categories.where((c) => c.dept == d.id))
                  tile(tint: c.tint, icon: photoIcon(c), label: context.tr(c.name), onTap: () => open(Routes.shop, {'cat': c.id})),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
