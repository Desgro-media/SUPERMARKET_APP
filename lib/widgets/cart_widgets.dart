import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../data/models.dart';
import '../state/actions.dart';
import '../state/store.dart';
import 'app_icon.dart';
import 'page_widgets.dart';
import 'pressable.dart';
import 'product_art.dart';
import 'ui_bits.dart';

/// The quantity pill of a cart line: [-] 2 [+] (a trash can instead of "-" when only one is left).
class CartStepper extends ConsumerWidget {
  const CartStepper(this.product, {super.key, this.large = false});

  final Product product;

  /// The big one of the product page (`.stepper-lg`).
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final q = ref.watch(storeProvider.select((s) => s.cart[product.id] ?? 0));
    final actions = ref.read(actionsProvider);
    final name = context.tr(product.name);
    Widget button(String icon, VoidCallback onTap, String label) => Pressable(
          onTap: onTap,
          scale: .9,
          semanticLabel: label,
          child: SizedBox(width: 28, height: 28, child: Center(child: AppIcon(icon, size: 15, color: t.text, stroke: 2.2))),
        );
    return Container(
      height: 30,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(q <= 1 ? 'trash' : 'minus', () => actions.cartDec(product.id), q <= 1 ? '${context.tr('Remove')} $name' : '${context.tr('Decrease quantity of')} $name'),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            alignment: Alignment.center,
            child: Text('$q', style: ts(13, w: FontWeight.w800, color: t.text, height: 1.2, tabular: true)),
          ),
          button('plus', () => actions.cartAdd(product.id, quiet: true), '${context.tr('Increase quantity of')} $name'),
        ],
      ),
    );
  }
}

/// One product in the cart: picture, name, "unit · SAR x each", quantity and the line total with a remove button.
class CartLineTile extends ConsumerWidget {
  const CartLineTile(this.line, {super.key, this.onDark = false});

  final CartLine line;

  /// In the cart sheet the tile sits on the page colour without a border (`.dr-body .cart-line`).
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final p = line.p;
    return Pressable(
      onTap: () => AppNav.go(Routes.product, {'id': p.id}),
      scale: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onDark ? t.bg : t.surface,
          border: onDark ? null : Border.all(color: t.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(width: 58, child: ProductArt(p, small: true, radius: 10)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(p.name), maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(13.5, w: FontWeight.w700, color: t.text, height: 1.3)),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${context.tr(p.unit)} · ', style: ts(11.5, color: t.muted)),
                      Money(p.price, size: 11.5, weight: FontWeight.w400, color: t.muted, ls: 0),
                      Text(' ${context.tr('each')}', style: ts(11.5, color: t.muted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CartStepper(p),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Money(line.total, size: 14),
                const SizedBox(height: 6),
                Pressable(
                  onTap: () => ref.read(actionsProvider).cartRemove(p.id),
                  scale: .9,
                  semanticLabel: '${context.tr('Remove')} ${context.tr(p.name)} ${context.tr('from cart')}',
                  child: SizedBox(width: 36, height: 36, child: Center(child: AppIcon('trash', size: 18, color: t.muted))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Spend SAR x more for free delivery" with a progress bar, or the green "You've unlocked free delivery!" (`.meter`).
class ShipMeter extends ConsumerWidget {
  const ShipMeter(this.totals, {super.key});

  final Totals totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totals.count == 0) return const SizedBox.shrink();
    final t = context.t;
    final cfg = ref.watch(catalogueProvider).config;
    final ok = totals.freeShip || totals.toFree <= 0;
    final fg = ok ? t.good : t.accent;
    final style = ts(12.5, color: t.text);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: ok ? t.good50 : t.accent50, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon('truck', size: 20, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: ok
                    ? Text(context.tr("You've unlocked free delivery!"), style: style.copyWith(fontWeight: FontWeight.w700))
                    // the web app translates this in pieces: "Spend", the amount, "more for", "free delivery"
                    : Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${context.tr('Spend')} '),
                          TextSpan(text: context.tr(moneyText(totals.toFree, cfg.currency)), style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: ' ${context.tr('more for')} '),
                          TextSpan(text: context.tr('free delivery'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                        style: style,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(ok ? 100 : (totals.subtotal / cfg.freeDeliveryAt * 100).roundToDouble(), color: fg, track: t.dark ? Colors.white.withValues(alpha: .1) : Colors.black.withValues(alpha: .08), height: 6),
        ],
      ),
    );
  }
}

/// The money lines of an order: subtotal, promo, delivery, express, total and "you're saving" (`rows()` in the web app).
class SummaryRows extends ConsumerWidget {
  const SummaryRows(this.totals, {super.key});

  final Totals totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cfg = ref.watch(catalogueProvider).config;

    Widget row(String label, Widget value, {Color? color, bool bold = false}) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: ts(13.5, w: FontWeight.w600, color: color ?? t.muted))),
            const SizedBox(width: 12),
            value,
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(context.tr('Subtotal (${totals.count} item${totals.count == 1 ? '' : 's'})'), Money(totals.subtotal, size: 13.5, weight: FontWeight.w700)),
        if (totals.discount > 0) ...[
          const SizedBox(height: 8),
          row(context.tr('Promo ${totals.promoCode}'), Money(totals.discount, size: 13.5, weight: FontWeight.w700, color: t.good, prefix: '\u2212'), color: t.good),
        ],
        const SizedBox(height: 8),
        row(
          context.tr('Delivery'),
          totals.delivery > 0
              ? Money(totals.delivery, size: 13.5, weight: FontWeight.w700)
              : Text(context.tr('Free'), style: ts(13.5, w: FontWeight.w800, color: t.good)),
        ),
        if (totals.express > 0) ...[
          const SizedBox(height: 8),
          row(context.tr('Express 60-min'), Money(totals.express, size: 13.5, weight: FontWeight.w700)),
        ],
        const SizedBox(height: 10),
        DashedLine(color: t.line),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('Total'), style: ts(15, w: FontWeight.w800, color: t.text)),
            Money(totals.total, size: 20, ls: -.02),
          ],
        ),
        if (totals.savings > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: t.good50, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                AppIcon('tag', size: 16, color: t.good),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr("You're saving ${moneyText(totals.savings + totals.discount, cfg.currency)} on this order"),
                    style: ts(12.5, w: FontWeight.w700, color: t.good),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
