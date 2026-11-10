import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/models.dart';
import '../state/actions.dart';
import '../state/store.dart';
import 'app_icon.dart';
import 'pressable.dart';
import 'product_art.dart';
import 'ui_bits.dart';

/// The add-to-cart control of a product card: a round "+" button, then a [-] 2 [+] stepper once it is in the cart
/// (a trash can instead of "-" when only one is left), or a "Sold out" tag.
class QtyControl extends ConsumerWidget {
  const QtyControl(this.product, {super.key, this.listStyle = false});

  final Product product;

  /// The list layout of the shop: a wide brand-coloured "+ Add" button instead of the round white one.
  final bool listStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final q = ref.watch(storeProvider.select((s) => s.cart[product.id] ?? 0));
    final actions = ref.read(actionsProvider);
    final name = context.tr(product.name);

    if (!product.inStock) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: listStyle ? t.surface2 : t.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: listStyle ? null : const [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(context.tr('Sold out'), style: ts(10.5, w: FontWeight.w800, color: t.muted, height: 1)),
      );
    }

    if (q == 0 && listStyle) {
      return Pressable(
        onTap: () => actions.cartAdd(product.id),
        scale: .94,
        semanticLabel: '${context.tr('Add')} $name',
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: t.brand, borderRadius: BorderRadius.circular(999), boxShadow: t.shadowBrand),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon('plus', size: 18, color: t.onBrand, stroke: 2.4),
              const SizedBox(width: 6),
              Text(context.tr('Add'), style: ts(13, w: FontWeight.w800, color: t.onBrand, height: 1.2)),
            ],
          ),
        ),
      );
    }
    if (q == 0) {
      return Pressable(
        onTap: () => actions.cartAdd(product.id),
        scale: .94,
        semanticLabel: '${context.tr('Add')} $name',
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: AppIcon('plus', size: 18, color: t.brand600, stroke: 2.4),
        ),
      );
    }

    Widget stepButton(String icon, VoidCallback onTap, String label) => Pressable(
          onTap: onTap,
          scale: .9,
          semanticLabel: label,
          child: SizedBox(
            width: 29,
            height: 30,
            child: Center(child: AppIcon(icon, size: 14, color: t.onBrand, stroke: 2.2)),
          ),
        );

    return TweenAnimationBuilder<double>(
      key: const ValueKey('stepper'),
      tween: Tween(begin: .92, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        height: 32,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: t.brand,
          borderRadius: BorderRadius.circular(999),
          boxShadow: listStyle ? t.shadowBrand : const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            stepButton(q == 1 ? 'trash' : 'minus', () => actions.cartDec(product.id), q == 1 ? '${context.tr('Remove')} $name' : '${context.tr('Decrease quantity of')} $name'),
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              alignment: Alignment.center,
              child: Text('$q', style: ts(13, w: FontWeight.w800, color: t.onBrand, height: 1.2, tabular: true)),
            ),
            stepButton('plus', () => actions.cartAdd(product.id, quiet: true), '${context.tr('Increase quantity of')} $name'),
          ],
        ),
      ),
    );
  }
}

/// The heart on a product photo. It gives a little "beat" when a product is added to the wishlist.
class WishButton extends ConsumerStatefulWidget {
  const WishButton(this.product, {super.key, this.size = 28, this.iconSize = 15});

  final Product product;
  final double size, iconSize;

  @override
  ConsumerState<WishButton> createState() => _WishButtonState();
}

class _WishButtonState extends ConsumerState<WishButton> with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1), weight: 60),
  ]).animate(CurvedAnimation(parent: _beat, curve: Curves.easeInOut));

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final id = widget.product.id;
    final on = ref.watch(storeProvider.select((s) => s.wish.contains(id)));
    ref.listen(storeProvider.select((s) => s.wish.contains(id)), (prev, next) {
      if (next && prev == false) _beat.forward(from: 0);
    });
    final name = context.tr(widget.product.name);
    return Pressable(
      onTap: () => ref.read(actionsProvider).toggleWish(id),
      scale: .9,
      semanticLabel: on ? '${context.tr('Remove')} $name ${context.tr('from wishlist')}' : '${context.tr('Add')} $name ${context.tr('to wishlist')}',
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.surface,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: ScaleTransition(
          scale: _scale,
          child: AppIcon('heart', size: widget.iconSize, color: on ? t.sale : t.muted, filled: on),
        ),
      ),
    );
  }
}

/// A product in a list or grid: photo with badges, wishlist heart, rating and add control, then name, size and price.
/// This is the compact phone card of the web app (`.pcard` at 560px and below).
class ProductCard extends ConsumerWidget {
  const ProductCard(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final p = product;
    return Pressable(
      onTap: () => AppNav.go(Routes.product, {'id': p.id}),
      scale: 1,
      semanticLabel: context.tr(p.name),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1 / .84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductArt(p, aspectRatio: 1 / .84, radius: 10),
                  PositionedDirectional(
                    start: 5,
                    top: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.off > 0) TagBadge('−${p.off}%', bg: t.sale, fg: t.dark ? const Color(0xFF230304) : Colors.white),
                        if (p.isNew) ...[
                          if (p.off > 0) const SizedBox(height: 3),
                          TagBadge(context.tr('New'), bg: t.sun, fg: t.ink),
                        ],
                        if (!p.inStock) ...[
                          if (p.off > 0 || p.isNew) const SizedBox(height: 3),
                          TagBadge(context.tr('Sold out'), bg: const Color(0xFF36413A), fg: Colors.white),
                        ],
                      ],
                    ),
                  ),
                  PositionedDirectional(end: 5, top: 5, child: WishButton(p)),
                  PositionedDirectional(start: 6, bottom: 6, child: _RatingChip(p.rating)),
                  PositionedDirectional(end: 6, bottom: 6, child: QtyControl(p)),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                context.tr(p.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ts(12.5, w: FontWeight.w700, color: t.text, height: 1.25, ls: -.01),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(context.tr(p.unit), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, color: t.muted, height: 1.2)),
            ),
            const Spacer(),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Money(p.price),
                  if (p.was > 0) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _plain(p.was),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: ts(11, color: t.muted, height: 1.16, decoration: TextDecoration.lineThrough, tabular: true).copyWith(decorationThickness: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _plain(double v) => v.toStringAsFixed(2);
}

class _RatingChip extends StatelessWidget {
  const _RatingChip(this.rating);

  final double rating;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 2, 6, 2),
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon('star', size: 10, color: t.star, filled: true),
          const SizedBox(width: 2),
          Text(rating.toStringAsFixed(1), style: ts(10.5, w: FontWeight.w700, color: t.text, height: 1.2)),
        ],
      ),
    );
  }
}

/// Products in equal-height rows (`.pgrid`): 2 across on phones, more on wider screens.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.gap = 8});

  final List<Product> products;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => EqualHeightGrid(
          columns: box.maxWidth < 560 ? 2 : (box.maxWidth < 820 ? 3 : 4),
          gap: gap,
          children: [for (final p in products) ProductCard(p, key: ValueKey(p.id))],
        ),
      );
}


/// The list layout of the shop (`.pgrid.list` on phones): a small picture on the left; name, size, rating and the price with
/// the add button on the right.
class ProductListCard extends ConsumerWidget {
  const ProductListCard(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final p = product;
    return Pressable(
      onTap: () => AppNav.go(Routes.product, {'id': p.id}),
      scale: 1,
      semanticLabel: context.tr(p.name),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductArt(p, radius: 10),
                  PositionedDirectional(
                    start: 5,
                    top: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.off > 0) TagBadge('\u2212${p.off}%', bg: t.sale, fg: t.dark ? const Color(0xFF230304) : Colors.white),
                        if (p.isNew) ...[if (p.off > 0) const SizedBox(height: 3), TagBadge(context.tr('New'), bg: t.sun, fg: t.ink)],
                      ],
                    ),
                  ),
                  PositionedDirectional(end: 5, top: 5, child: WishButton(p)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(p.name), maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(12.5, w: FontWeight.w700, color: t.text, height: 1.25, ls: -.01)),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(context.tr(p.unit), style: ts(11, color: t.muted, height: 1.2)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon('star', size: 12, color: t.star, filled: true),
                          const SizedBox(width: 2),
                          Text(p.rating.toStringAsFixed(1), style: ts(11.5, w: FontWeight.w700, color: t.text, height: 1.2)),
                          Text(' (${p.reviews})', style: ts(11.5, color: t.muted, height: 1.2)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Money(p.price),
                            if (p.was > 0) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  p.was.toStringAsFixed(2),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: ts(11, color: t.muted, height: 1.16, decoration: TextDecoration.lineThrough, tabular: true).copyWith(decorationThickness: 1.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      QtyControl(p, listStyle: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}