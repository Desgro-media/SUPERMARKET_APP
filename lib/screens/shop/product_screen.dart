import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_nav.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../data/models.dart';
import '../../data/sorting.dart';
import '../../shell/chrome_scope.dart';
import '../../shell/page_scroll.dart';
import '../../state/actions.dart';
import '../../state/orders.dart';
import '../../state/reviews.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/product_art.dart';
import '../../widgets/ui_bits.dart';
import '../home/home_sections.dart' show ProductScroller;
import '../not_found_screen.dart';

/// The product page: photos, price and add-to-cart, delivery perks, description / details / reviews tabs, related products
/// and (on phones) a sticky "Add to cart" bar above the bottom navigation.
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int _qty = 1, _view = 0, _tab = 0, _stars = 0;
  final _tabsKey = GlobalKey();
  final _reviewName = TextEditingController(), _reviewText = TextEditingController();
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    final u = ref.read(storeProvider).user;
    if (u != null) _reviewName.text = (u['name'] as String?) ?? '';
    // remember that this product was looked at ("Recently viewed"), once the page is on screen
    Future.microtask(() {
      if (mounted && ref.read(catalogueProvider).byId.containsKey(widget.productId)) ref.read(storeProvider.notifier).pushRecent(widget.productId);
    });
  }

  @override
  void dispose() {
    _reviewName.dispose();
    _reviewText.dispose();
    super.dispose();
  }

  void _add(Product p, {bool goCheckout = false}) {
    final store = ref.read(storeProvider.notifier);
    final actions = ref.read(actionsProvider);
    final have = store.qty(p.id), max = store.maxQty(p);
    if (have >= max) {
      actions.toast('You already have the maximum available ($max)');
      return;
    }
    final next = (have + _qty) > max ? max : have + _qty;
    store.setQty(p.id, next);
    ref.read(cartBumpProvider.notifier).bump();
    setState(() => _qty = 1);
    if (goCheckout) {
      AppNav.go(Routes.checkout);
      return;
    }
    actions.toast('${next - have} × ${p.name} added', action: 'View cart', onAction: actions.openCart);
  }

  Future<void> _share(Product p, String storeName) async {
    try {
      await SharePlus.instance.share(ShareParams(text: '${p.name} — $storeName', subject: p.name));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '${p.name} — $storeName'));
      ref.read(actionsProvider).toast('Link copied to clipboard');
    }
  }

  void _submitReview(Product p) {
    final name = _reviewName.text.trim(), text = _reviewText.text.trim();
    String? msg;
    if (_stars == 0) {
      msg = 'Please choose a star rating.';
    } else if (name.isEmpty) {
      msg = 'Please enter your name.';
    } else if (text.length < 5) {
      msg = 'Please write a few words about the product.';
    }
    setState(() => _reviewError = msg);
    if (msg != null) return;
    ref.read(storeProvider.notifier).addReview(p.id, {'name': name, 'text': text, 'stars': _stars, 'ts': DateTime.now().millisecondsSinceEpoch, 'title': ''});
    _reviewText.clear();
    FocusScope.of(context).unfocus();
    setState(() => _stars = 0);
    ref.read(actionsProvider).toast('Thanks for your review!');
  }

  void _gotoReviews() {
    setState(() => _tab = 2);
    final ctx = _tabsKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final cfg = cat.config;
    final p = cat.byId[widget.productId];
    if (p == null) return const NotFoundScreen();
    final category = cat.catById[p.cat]!;
    final dept = cat.deptById[p.dept]!;
    final store = ref.watch(storeProvider);
    final inCart = store.cart[p.id] ?? 0;
    final max = ref.read(storeProvider.notifier).maxQty(p);
    final wished = store.wish.contains(p.id);

    final related = sortedStable(cat.products.where((x) => x.cat == p.cat && x.id != p.id), (a, b) => b.pop.compareTo(a.pop)).take(10).toList();
    final sameBrand = cat.products.where((x) => x.brand == p.brand && x.cat != p.cat && x.id != p.id).take(6).toList();
    final recent = [for (final id in store.recent) if (id != p.id && cat.byId[id] != null) cat.byId[id]!].take(8).toList();

    // ---------- gallery ----------
    final views = p.imgs.isEmpty ? 3 : p.imgs.length;
    Widget gallery() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductArt(p, variant: _view, aspectRatio: 1 / .74, radius: 18),
            if (views >= 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    for (var v = 0; v < views; v++)
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 8),
                        child: Pressable(
                          onTap: () => setState(() => _view = v),
                          scale: .95,
                          semanticLabel: '${context.tr('View image')} ${v + 1}',
                          child: Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(border: Border.all(color: _view == v ? t.brand : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(12)),
                            child: ProductArt(p, variant: v, small: true, radius: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );

    // ---------- price, stock and buttons ----------
    final save = p.was > 0 ? p.was - p.price : 0.0;
    final stockColor = !p.inStock ? t.danger : (p.stock < 15 ? (t.dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)) : t.good);
    final stockText = !p.inStock ? 'Currently sold out' : (p.stock < 15 ? 'Only ${p.stock} left — order soon' : 'In stock');

    Widget addLabel({required bool withTotal}) => DefaultTextStyle(
          style: ts(15, w: FontWeight.w700, color: t.onBrand, height: 1.2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon('cart', size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: context.tr('Add to cart')),
                    if (withTotal) TextSpan(text: ' · ${context.tr(moneyText(p.price * _qty, cfg.currency))}'),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

    Widget bigButton({required Widget child, required VoidCallback? onTap, required double height, double horizontal = 20, bool primary = true}) => Pressable(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? .5 : 1,
            child: Container(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? t.brand : t.surface,
                border: Border.all(color: primary ? Colors.transparent : t.line, width: 1.5),
                borderRadius: BorderRadius.circular(999),
                boxShadow: primary && onTap != null ? t.shadowBrand : null,
              ),
              child: child,
            ),
          ),
        );

    Widget stepperLarge() => Container(
          height: 44,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Pressable(
                onTap: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                scale: .9,
                semanticLabel: context.tr('Decrease quantity'),
                child: SizedBox(width: 42, height: 40, child: Center(child: AppIcon('minus', size: 17, color: t.text, stroke: 2.2))),
              ),
              Text('$_qty', style: ts(16, w: FontWeight.w800, color: t.text, height: 1.2, tabular: true)),
              Pressable(
                onTap: () {
                  if (_qty < max) {
                    setState(() => _qty++);
                  } else {
                    ref.read(actionsProvider).toast('Maximum $max per order');
                  }
                },
                scale: .9,
                semanticLabel: context.tr('Increase quantity'),
                child: SizedBox(width: 42, height: 40, child: Center(child: AppIcon('plus', size: 17, color: t.text, stroke: 2.2))),
              ),
            ],
          ),
        );

    Widget wishBig() => Pressable(
          onTap: () => ref.read(actionsProvider).toggleWish(p.id),
          scale: .92,
          semanticLabel: context.tr(wished ? 'Remove from wishlist' : 'Add to wishlist'),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.surface, shape: BoxShape.circle, border: Border.all(color: t.line, width: 1.5)),
            child: AppIcon('heart', size: 22, color: wished ? t.sale : t.muted, filled: wished),
          ),
        );

    final now = DateTime.now();
    final h = now.hour + now.minute / 60;
    final etaBold = TextStyle(fontWeight: FontWeight.w700, color: t.text);
    final Widget eta = Text.rich(
      h >= 7 && h < 21
          ? TextSpan(children: [
              TextSpan(text: '${context.tr('Order within')} '),
              TextSpan(text: '${(21 * 60 - (now.hour * 60 + now.minute)) ~/ 60}h ${(21 * 60 - (now.hour * 60 + now.minute)) % 60}m', style: etaBold),
              TextSpan(text: ' ${context.tr('for same-day delivery')}'),
            ])
          : TextSpan(children: [
              TextSpan(text: '${context.tr('Order now for delivery')} '),
              TextSpan(text: context.tr('tomorrow from 8:00'), style: etaBold),
            ]),
      style: ts(13, color: t.muted),
    );

    final buybox = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(20), boxShadow: t.shadow1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Money(p.price, size: 28, ls: -.03),
              if (p.was > 0) ...[
                Text(fmt2(p.was), style: ts(15, color: t.muted, height: 1.16, decoration: TextDecoration.lineThrough, tabular: true).copyWith(decorationThickness: 1.5)),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.sale, borderRadius: BorderRadius.circular(999)),
                  child: Text(context.tr('Save ${moneyText(save, cfg.currency)} · ${p.off}%'), style: ts(12, w: FontWeight.w800, color: t.dark ? const Color(0xFF230304) : Colors.white, height: 1)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(context.tr('${p.unit} · VAT included'), style: ts(13, w: FontWeight.w600, color: t.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(context.tr(stockText), style: ts(13, w: FontWeight.w700, color: stockColor))),
            ],
          ),
          const SizedBox(height: 8),
          if (p.inStock) ...[
            Row(children: [Expanded(child: stepperLarge()), const SizedBox(width: 8), wishBig()]),
            const SizedBox(height: 8),
            bigButton(onTap: () => _add(p), height: 46, child: addLabel(withTotal: true)),
            const SizedBox(height: 8),
            Row(
              children: [
                AppButton(label: context.tr('Buy now'), kind: BtnKind.outline, height: 38, fontSize: 14, horizontal: 20, onTap: () => _add(p, goCheckout: true)),
                const SizedBox(width: 8),
                Pressable(
                  onTap: () => _share(p, cfg.name),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [AppIcon('share', size: 18, color: t.text), const SizedBox(width: 8), Text(context.tr('Share'), style: ts(14, w: FontWeight.w700, color: t.text, height: 1.2))]),
                  ),
                ),
              ],
            ),
            if (inCart > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: t.brand50, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      AppIcon('check', size: 18, color: t.brand600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: context.tr('$inCart in your cart · ')),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: Pressable(onTap: ref.read(actionsProvider).openCart, child: Text(context.tr('View cart'), style: ts(13, w: FontWeight.w700, color: t.brand600, decoration: TextDecoration.underline))),
                            ),
                          ]),
                          style: ts(13, w: FontWeight.w700, color: t.brand600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            Row(children: [Expanded(child: AppButton(label: context.tr('Sold out'), kind: BtnKind.outline, height: 46, expand: true, onTap: null)), const SizedBox(width: 8), wishBig()]),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: t.brand50, borderRadius: BorderRadius.circular(14)),
                child: Text(context.tr("Save it to your wishlist and we'll keep it handy for when it's back."), style: ts(13, w: FontWeight.w700, color: t.brand600)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DashedLine(color: t.line),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [AppIcon('clock', size: 20, color: t.brand600), const SizedBox(width: 10), Expanded(child: eta)]),
        ],
      ),
    );

    Widget perk(String icon, String title, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.brand50, borderRadius: BorderRadius.circular(11)),
                child: AppIcon(icon, size: 18, color: t.brand600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(title), style: ts(13.5, w: FontWeight.w700, color: t.text, height: 1.3)),
                    Text(context.tr(text), style: ts(12, color: t.muted, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        );

    // ---------- tabs ----------
    Widget tabButton(int i, String label, {int? count}) => Pressable(
          onTap: () => setState(() => _tab = i),
          scale: .98,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == i ? t.brand : Colors.transparent, width: 3))),
            child: Row(
              children: [
                Text(context.tr(label), style: ts(13.5, w: FontWeight.w700, color: _tab == i ? t.brand600 : t.muted, height: 1.3)),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
                    child: Text('$count', style: ts(10, w: FontWeight.w800, color: t.muted, height: 1)),
                  ),
                ],
              ],
            ),
          ),
        );

    Widget description() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('${p.blurb} Supplied by ${p.brand} and quality-checked at our fulfilment centre before it reaches you.'), style: ts(14, color: t.muted)),
            const SizedBox(height: 12),
            Text(context.tr(category.note), style: ts(14, color: t.muted)),
            const SizedBox(height: 8),
            for (final tick in ['Quality checked before dispatch', 'Packed securely for delivery', 'Covered by our quality guarantee'])
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: t.brand, shape: BoxShape.circle), child: AppIcon('check', size: 12, color: Colors.white, stroke: 3.5)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.tr(tick), style: ts(14, w: FontWeight.w600, color: t.text))),
                  ],
                ),
              ),
          ],
        );

    Widget details() {
      final rows = [
        ['Brand', p.brand],
        ['Pack size', p.unit],
        ['Department', dept.name],
        ['Category', category.name],
        ['Product code', '${p.id}'],
        ...category.spec,
      ];
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: t.surface2, border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: t.line))),
                          child: Text(context.tr(rows[i][0]), style: ts(13.5, w: FontWeight.w600, color: t.muted)),
                        ),
                      ),
                      Expanded(
                        flex: 58,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: t.line))),
                          child: Text(context.tr(rows[i][1]), style: ts(13.5, color: t.text)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget reviews() {
      final bars = ratingBars(p.rating);
      final mine = [for (final r in store.reviews['${p.id}'] ?? const <Map<String, dynamic>>[]) r];
      Widget reviewCard({required String name, required bool verified, required int ts0, required int stars, required String title, required String text}) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(name.isEmpty ? '?' : name.characters.first, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: ts(14, w: FontWeight.w700, color: t.text, height: 1.25)),
                          Text(context.tr(verified ? 'Verified buyer' : 'Your review'), style: ts(12.5, w: FontWeight.w700, color: t.good, height: 1.25)),
                        ],
                      ),
                    ),
                    Text(context.tr(agoText(ts0)), style: ts(13, color: t.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                StarRating(stars.toDouble(), size: 14),
                if (title.isNotEmpty) ...[const SizedBox(height: 8), Text(context.tr(title), style: ts(15.5, w: FontWeight.w800, color: t.text, height: 1.2))],
                const SizedBox(height: 8),
                Text(context.tr(text), style: ts(14, color: t.text)),
              ],
            ),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.rating.toStringAsFixed(1), style: ts(44, w: FontWeight.w800, color: t.text, height: 1, ls: -.04, tabular: true)),
                      const SizedBox(height: 4),
                      StarRating(p.rating, size: 14),
                      const SizedBox(height: 4),
                      Text(context.tr('${p.reviews} ratings'), style: ts(13, color: t.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < bars.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text('${5 - i}★', style: ts(13, w: FontWeight.w700, color: t.text))),
                        const SizedBox(width: 10),
                        Expanded(child: ProgressBar(bars[i].toDouble(), color: t.star, height: 6)),
                        const SizedBox(width: 10),
                        SizedBox(width: 40, child: Text('${bars[i]}%', textAlign: TextAlign.end, style: ts(13, w: FontWeight.w700, color: t.muted, tabular: true))),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // write a review
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.tr('Write a review'), style: ts(17, w: FontWeight.w800, color: t.text, height: 1.15)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var n = 1; n <= 5; n++)
                            Pressable(
                              onTap: () => setState(() => _stars = n),
                              scale: .85,
                              semanticLabel: '$n ${context.tr(n > 1 ? 'stars' : 'star')}',
                              child: Padding(padding: const EdgeInsets.all(2), child: Text('★', style: ts(30, color: n <= _stars ? t.star : t.line, height: 1))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppField(label: context.tr('Your name'), controller: _reviewName, textInputAction: TextInputAction.next, maxLength: 40, autofillHints: const [AutofillHints.name]),
                      const SizedBox(height: 12),
                      AppField(label: context.tr('Your review'), controller: _reviewText, maxLines: 3, minLines: 3, maxLength: 500, keyboardType: TextInputType.multiline),
                      if (_reviewError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(context.tr(_reviewError!), style: ts(14, w: FontWeight.w700, color: t.danger))),
                      const SizedBox(height: 12),
                      AppButton(label: context.tr('Submit review'), onTap: () => _submitReview(p)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final r in mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: reviewCard(name: '${r['name']}', verified: false, ts0: (r['ts'] as num).toInt(), stars: r['stars'] as int, title: '${r['title'] ?? ''}', text: '${r['text']}'),
            ),
          for (final r in sampleReviews(p))
            Padding(padding: const EdgeInsets.only(bottom: 14), child: reviewCard(name: r.name, verified: true, ts0: r.ts, stars: r.stars, title: r.title, text: r.text)),
        ],
      );
    }

    final scope = ChromeScope.of(context);
    return Stack(
      children: [
        PageScroll(
          activeNav: dept.id,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Crumbs([
                    Crumbs.home,
                    (dept.name, () => AppNav.go(Routes.shop, {'dept': dept.id})),
                    (category.name, () => AppNav.go(Routes.shop, {'cat': category.id})),
                    (p.name, null),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        gallery(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Pressable(
                            onTap: () => AppNav.go(Routes.shop, {'cat': category.id}),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: t.brand50, borderRadius: BorderRadius.circular(999)),
                              child: Text(context.tr(category.name), style: ts(12, w: FontWeight.w700, color: t.brand600)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(context.tr(p.name), style: ts(22, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.03)),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Pressable(onTap: () => AppNav.go(Routes.shop, {'brand': p.brand}), child: Text(context.tr(p.brand), style: ts(12.5, w: FontWeight.w700, color: t.brand600))),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: t.muted.withValues(alpha: .5), shape: BoxShape.circle)),
                            StarRating(p.rating, size: 14),
                            Text(p.rating.toStringAsFixed(1), style: ts(12.5, w: FontWeight.w700, color: t.text)),
                            Pressable(onTap: _gotoReviews, child: Text(context.tr('${p.reviews} reviews'), style: ts(12.5, w: FontWeight.w700, color: t.brand600))),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: t.muted.withValues(alpha: .5), shape: BoxShape.circle)),
                            Text(context.tr('SKU ${p.id}'), style: ts(12.5, w: FontWeight.w600, color: t.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(context.tr(p.blurb), style: ts(14, color: t.muted)),
                        const SizedBox(height: 8),
                        buybox,
                        const SizedBox(height: 8),
                        perk('truck', 'Free delivery over ${moneyText(cfg.freeDeliveryAt, cfg.currency)}', 'Or ${moneyText(cfg.deliveryFee, cfg.currency)} flat rate below that'),
                        perk('shield', 'Quality guarantee', 'Replacement or refund, no questions asked'),
                        p.dept == 'grocery'
                            ? perk('refresh', 'Easy substitutions', 'Tell us what you prefer in the order notes')
                            : perk('refresh', 'Easy returns', 'Return unopened items within 14 days'),
                        // tabs
                        Padding(
                          key: _tabsKey,
                          padding: const EdgeInsets.only(top: 24),
                          child: Container(
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line, width: 1.5))),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Row(children: [tabButton(0, 'Description'), const SizedBox(width: 6), tabButton(1, 'Details'), const SizedBox(width: 6), tabButton(2, 'Reviews', count: p.reviews)]),
                            ),
                          ),
                        ),
                        Padding(padding: const EdgeInsets.only(top: 14), child: _tab == 0 ? description() : (_tab == 1 ? details() : reviews())),
                        if (related.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionHead(
                            title: context.tr('You might also like'),
                            sub: context.tr('More from ${category.name}'),
                            trailing: LinkMore(context.tr('View all'), onTap: () => AppNav.go(Routes.shop, {'cat': category.id})),
                          ),
                          ProductScroller(products: related),
                        ],
                        if (sameBrand.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionHead(title: context.tr('More from ${p.brand}')),
                          ProductScroller(products: sameBrand),
                        ],
                        if (recent.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionHead(title: context.tr('Recently viewed')),
                          ProductScroller(products: recent),
                        ],
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // sticky "Add to cart" bar above the bottom navigation
        if (p.inStock)
          Positioned(
            left: 0,
            right: 0,
            bottom: scope.bottom - 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: t.surface.withValues(alpha: .96), border: Border(top: BorderSide(color: t.line))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Money(p.price, size: 16, ls: -.02),
                        Text(context.tr(p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, color: t.muted, height: 1.2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  bigButton(onTap: () => _add(p), height: 40, horizontal: 18, child: addLabel(withTotal: false)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
