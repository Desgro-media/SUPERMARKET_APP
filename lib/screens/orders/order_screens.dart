
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/page_scroll.dart';
import '../../state/actions.dart';
import '../../state/orders.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ui_bits.dart';
import '../info/info_widgets.dart';
import '../not_found_screen.dart';
import 'order_widgets.dart';

/// "Thank you, Aisha!": the page shown right after placing an order, with live tracking and the order details.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final order = ref.read(storeProvider.notifier).order(orderId);
    if (order == null) return const NotFoundScreen();
    final customer = order['customer'] as Map;
    final first = (customer['name'] as String).split(' ').first;
    final email = customer['email'] as String? ?? '';

    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: .3, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: const Cubic(.3, 1.5, .5, 1),
                        builder: (context, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: v, child: child)),
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: t.good, shape: BoxShape.circle, boxShadow: [BoxShadow(color: t.good50, spreadRadius: 10)]),
                          child: AppIcon('check', size: 34, color: t.dark ? const Color(0xFF06210F) : Colors.white, stroke: 2.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(context.tr('Thank you, $first!'), textAlign: TextAlign.center, style: ts(24, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${context.tr('Order')} '),
                          TextSpan(text: '#${order['id']}', style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                          TextSpan(text: context.tr(' is confirmed. ${email.isNotEmpty ? 'A receipt is on its way to $email.' : ''}')),
                        ]),
                        textAlign: TextAlign.center,
                        style: ts(14, color: t.muted),
                      ),
                    ],
                  ),
                ),
                CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LiveTracker(order: order),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(context.tr('Tracking in this demo advances automatically over a couple of minutes.'), textAlign: TextAlign.center, style: ts(12.5, color: t.muted)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OrderBody(order: order),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppButton(label: context.tr('Continue shopping'), height: 46, onTap: () => AppNav.go(Routes.shop)),
                    AppButton(label: context.tr('All my orders'), kind: BtnKind.outline, height: 46, onTap: () => AppNav.go(Routes.orders)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "My orders": every order placed on this phone, with Reorder and View.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final orders = ref.watch(storeProvider.select((s) => s.orders));

    void reorder(Map<String, dynamic> o) {
      final store = ref.read(storeProvider.notifier);
      var added = 0;
      for (final i in o['items'] as List) {
        final p = cat.byId[(i as Map)['id'] as int];
        if (p != null && p.inStock) {
          final have = store.qty(p.id), want = i['qty'] as int;
          store.setQty(p.id, have > want ? have : want);
          added++;
        }
      }
      final actions = ref.read(actionsProvider);
      if (added > 0) {
        ref.read(cartBumpProvider.notifier).bump();
        actions.toast('$added item${added == 1 ? '' : 's'} added to your cart', action: 'View cart', onAction: actions.openCart);
      } else {
        actions.toast('Those items are currently unavailable');
      }
    }

    Widget card(Map<String, dynamic> o) {
      final st = orderStage(o), n = orderItemCount(o);
      final items = [for (final i in o['items'] as List) i as Map];
      return CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${o['id']}', style: ts(14, w: FontWeight.w700, color: t.text)),
                    Text('${context.tr(agoText((o['ts'] as num).toInt()))} · ${context.tr('$n item${n == 1 ? '' : 's'}')}', style: ts(12.5, color: t.muted)),
                  ],
                ),
                StatusPill(kOrderStages[st].$1, delivered: st == 3),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in items.take(8)) ItemPic(id: i['id'] as int, emoji: i['emoji'] as String? ?? '', size: 44, radius: 12, emojiSize: 24),
                if (items.length > 8)
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(12)),
                    child: Text('+${items.length - 8}', style: ts(13, w: FontWeight.w800, color: t.muted)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Money((o['totals'] as Map)['total'] is num ? ((o['totals'] as Map)['total'] as num).toDouble() : 0, size: 17, ls: -.02),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(label: context.tr('Reorder'), icon: 'refresh', kind: BtnKind.outline, height: 36, fontSize: 14, horizontal: 14, onTap: () => reorder(o)),
                    const SizedBox(width: 8),
                    AppButton(label: context.tr('View'), height: 36, fontSize: 14, horizontal: 14, onTap: () => AppNav.go(Routes.order, {'id': o['id']})),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle('My orders'),
              if (orders.isEmpty)
                EmptyState(
                  emoji: '\u{1F4E6}',
                  title: 'No orders yet',
                  text: 'When you place an order it will show up here, ready to reorder in one tap.',
                  tall: true,
                  actions: [AppButton(label: context.tr('Start shopping'), height: 46, onTap: () => AppNav.go(Routes.shop))],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(children: [for (var i = 0; i < orders.length; i++) ...[if (i > 0) const SizedBox(height: 14), card(orders[i])]]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Track Order": look an order up by its ID and watch it move through the four steps.
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  final _id = TextEditingController();
  Map<String, dynamic>? _order;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      // looked up after the first frame, when the store can be read safely
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(widget.orderId!));
    }
  }

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  void _show(String raw) {
    final o = ref.read(storeProvider.notifier).order(raw.trim().toUpperCase());
    setState(() {
      if (o == null) {
        _order = null;
        _error = "We couldn't find that order on this device. Check the ID and try again.";
      } else {
        _error = null;
        _order = o;
        _id.text = o['id'] as String;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final recent = ref.watch(storeProvider.select((s) => s.orders)).take(6).toList();
    final o = _order;
    return InfoPage(
      title: 'Track Order',
      lead: 'Enter your order ID to see where your order is right now.',
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('Order ID'), style: ts(13, w: FontWeight.w700, color: t.text)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      alignment: AlignmentDirectional.centerStart,
                      decoration: BoxDecoration(color: t.surface, border: Border.all(color: _error != null ? t.danger : t.line, width: 1.5), borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: _id,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _show,
                        cursorColor: t.brand,
                        style: ts(16, color: t.text, height: 1.3),
                        decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: context.tr('e.g. FN-ABC123'), hintStyle: ts(16, color: t.muted, height: 1.3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(label: context.tr('Track'), height: 44, onTap: () => _show(_id.text)),
                ],
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(context.tr(_error!), style: ts(13, w: FontWeight.w600, color: t.danger, height: 1.4))),
            ],
          ),
        ),
        if (o != null) ...[
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${context.tr('Order')} #${o['id']}', style: ts(16, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                ),
                LiveTracker(order: o),
                Padding(padding: const EdgeInsets.only(top: 12), child: Text(context.tr(o['slot'] as String), textAlign: TextAlign.center, style: ts(12.5, color: t.muted))),
              ],
            ),
          ),
          OrderBody(order: o),
        ],
        if (recent.isNotEmpty)
          CardBox(
            title: 'Your recent orders',
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: i == recent.length - 1 ? null : Border(bottom: BorderSide(color: t.line))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Pressable(
                          onTap: () => _show(recent[i]['id'] as String),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('#${recent[i]['id']}', style: ts(14, w: FontWeight.w700, color: t.text)),
                              Text(context.tr(agoText((recent[i]['ts'] as num).toInt())), style: ts(12.5, color: t.muted)),
                            ],
                          ),
                        ),
                        StatusPill(kOrderStages[orderStage(recent[i])].$1, delivered: orderStage(recent[i]) == 3),
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
