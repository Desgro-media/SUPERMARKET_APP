import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../data/models.dart';
import '../../data/sorting.dart';
import '../../shell/page_scroll.dart';
import '../../state/actions.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cart_widgets.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ui_bits.dart';
import '../home/home_sections.dart' show ProductScroller;

/// "Complete your basket": the most popular products that are not in the cart yet.
List<Product> basketSuggestions(Catalogue cat, Map<int, int> cart, int n) =>
    sortedStable(cat.products.where((p) => !cart.containsKey(p.id) && p.inStock), (a, b) => b.pop.compareTo(a.pop)).take(n).toList();

/// The empty-cart message with a "Start shopping" button, shared by the page and the sheet.
class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key, this.onStart, this.tall = true, this.text = 'Add a few things you need to get started — your basket is saved on this device.', this.title = 'Your cart is empty'});

  final VoidCallback? onStart;
  final bool tall;
  final String text, title;

  @override
  Widget build(BuildContext context) => EmptyState(
        emoji: '\u{1F6D2}',
        title: title,
        text: text,
        tall: tall,
        actions: [AppButton(label: context.tr('Start shopping'), height: 46, onTap: onStart ?? () => AppNav.go(Routes.shop))],
      );
}

/// The promo-code box of the cart: an input and Apply, or the applied code with Remove.
class PromoBox extends ConsumerStatefulWidget {
  const PromoBox(this.totals, {super.key});

  final Totals totals;

  @override
  ConsumerState<PromoBox> createState() => _PromoBoxState();
}

class _PromoBoxState extends ConsumerState<PromoBox> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final totals = widget.totals;
    if (totals.promoCode != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: t.good50, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                AppIcon('tag', size: 18, color: t.good),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: totals.promoCode, style: const TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: ' ${context.tr('applied')}'),
                    ]),
                    style: ts(14, w: FontWeight.w600, color: t.good),
                  ),
                ),
                Pressable(
                  onTap: () => ref.read(storeProvider.notifier).removePromo(),
                  child: Text(context.tr('Remove'), style: ts(14, w: FontWeight.w700, color: t.good)),
                ),
              ],
            ),
          ),
          if (totals.promoNote.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(context.tr(totals.promoNote), style: ts(13, w: FontWeight.w700, color: t.badgeBg))),
        ],
      );
    }
    void apply() {
      final r = ref.read(storeProvider.notifier).applyPromo(_code.text);
      ref.read(actionsProvider).toast(r.msg);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(999)),
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onSubmitted: (_) => apply(),
                  cursorColor: t.brand,
                  style: ts(16, color: t.text, height: 1.2),
                  decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: context.tr('Promo code'), hintStyle: ts(16, color: t.muted, height: 1.2)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppButton(label: context.tr('Apply'), kind: BtnKind.outline, height: 40, onTap: apply),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text('${context.tr('Try')} ', style: ts(13, color: t.muted)),
              Pressable(
                onTap: () => _code.text = 'SAVE10',
                child: Text('SAVE10', style: ts(13, w: FontWeight.w700, color: t.brand600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The cart page: lines, free-delivery meter, order summary with promo code, and "Complete your basket".
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final totals = ref.watch(totalsProvider);
    final cart = ref.watch(storeProvider.select((s) => s.cart));
    final actions = ref.read(actionsProvider);

    Widget summary() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(20), boxShadow: t.shadow1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('Order summary'), style: ts(17, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
              const SizedBox(height: 12),
              PromoBox(totals),
              const SizedBox(height: 12),
              SummaryRows(totals),
              const SizedBox(height: 12),
              AppButton(label: context.tr('Go to checkout'), trailingIcon: 'arrow', height: 46, expand: true, onTap: () => AppNav.go(Routes.checkout)),
              const SizedBox(height: 12),
              for (final (icon, text) in [('shield', 'Pay on delivery — cash or card'), ('refresh', 'Easy returns on every order')])
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [AppIcon(icon, size: 16, color: t.brand600), const SizedBox(width: 8), Expanded(child: Text(context.tr(text), style: ts(13, w: FontWeight.w600, color: t.muted)))]),
                ),
            ],
          ),
        );

    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle('Your cart'),
              if (totals.count == 0)
                const EmptyCart()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShipMeter(totals),
                      for (var i = 0; i < totals.items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        CartLineTile(totals.items[i], key: ValueKey(totals.items[i].p.id)),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Pressable(
                              onTap: () => AppNav.go(Routes.shop),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                AppIcon('left', size: 16, color: t.brand600),
                                const SizedBox(width: 6),
                                Text(context.tr('Continue shopping'), style: ts(14, w: FontWeight.w700, color: t.brand600)),
                              ]),
                            ),
                            Pressable(onTap: actions.clearCart, child: Text(context.tr('Clear cart'), style: ts(14, w: FontWeight.w700, color: t.danger))),
                          ],
                        ),
                      ),
                      summary(),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHead(title: context.tr('Complete your basket'), sub: context.tr('Popular picks to go with your order')),
                    ProductScroller(products: basketSuggestions(cat, cart, 8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
