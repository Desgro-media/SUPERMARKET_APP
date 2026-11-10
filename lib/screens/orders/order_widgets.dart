import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../state/orders.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/product_art.dart';
import '../../widgets/ui_bits.dart';

/// The four-step progress of an order, drawn top to bottom (`.tracker` on phones). The step you are on pulses.
class OrderTracker extends StatefulWidget {
  const OrderTracker({super.key, required this.stage});

  final int stage;

  @override
  State<OrderTracker> createState() => _OrderTrackerState();
}

class _OrderTrackerState extends State<OrderTracker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final stage = widget.stage;
    return Semantics(
      label: context.tr('Order progress'),
      child: Column(
        children: [
          for (var i = 0; i < kOrderStages.length; i++) ...[
            if (i > 0)
              // the line joining this step to the one above it
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16.5),
                  child: Container(width: 3, height: 18, color: i <= stage ? t.brand : t.line),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Dot(index: i, stage: stage, pulse: _pulse),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(kOrderStages[i].$1), style: ts(14, w: FontWeight.w700, color: t.text, height: 1.3)),
                      Text(context.tr(kOrderStages[i].$2), style: ts(12, color: t.muted, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index, required this.stage, required this.pulse});

  final int index, stage;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final done = index < stage || stage == 3;
    final now = index == stage && stage != 3;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? t.brand : t.surface,
          border: Border.all(color: done || now ? t.brand : t.line, width: 3),
          boxShadow: now ? [BoxShadow(color: t.brand50, spreadRadius: 6 + 4 * pulse.value)] : null,
        ),
        child: done
            ? AppIcon('check', size: 18, color: t.onBrand, stroke: 3)
            : Text('${index + 1}', style: ts(14, w: FontWeight.w800, color: now ? t.brand600 : t.muted, height: 1.2)),
      ),
    );
  }
}

/// Re-reads the order's stage every three seconds and shows the tracker (the demo has no courier, see [orderStage]).
class LiveTracker extends StatefulWidget {
  const LiveTracker({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  State<LiveTracker> createState() => _LiveTrackerState();
}

class _LiveTrackerState extends State<LiveTracker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {});
      if (orderStage(widget.order) == 3) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OrderTracker(stage: orderStage(widget.order));
}

/// A small product picture for an order line: the photo of the product if it is still in the catalogue, else its emoji.
class ItemPic extends ConsumerWidget {
  const ItemPic({super.key, required this.id, required this.emoji, this.size = 38, this.radius = 10, this.emojiSize = 20});

  final int id;
  final String emoji;
  final double size, radius, emojiSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(catalogueProvider).byId[id];
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: context.t.surface2, borderRadius: BorderRadius.circular(radius)),
      child: PhotoOrEmoji(src: p != null && p.hasPhoto ? p.thumbs[0] : '', emoji: p?.emoji ?? (emoji.isEmpty ? '\u{1F6D2}' : emoji), emojiSize: emojiSize, cacheWidth: 120),
    );
  }
}

/// The "Items" and "Delivery" cards of an order (`orderBody` in the web app).
class OrderBody extends StatelessWidget {
  const OrderBody({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final totals = order['totals'] as Map;
    final address = order['address'] as Map;
    final customer = order['customer'] as Map;
    final items = [for (final i in order['items'] as List) i as Map];
    final notes = order['notes'] as String? ?? '';
    final landmark = address['landmark'] as String? ?? '';

    Widget kv(String k, Widget v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 70, child: Text(context.tr(k), style: ts(13.5, w: FontWeight.w600, color: t.muted))),
              const SizedBox(width: 10),
              Expanded(child: v),
            ],
          ),
        );
    final value = ts(13.5, w: FontWeight.w600, color: t.text);

    Widget line(String label, Widget amount, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: ts(13.5, w: FontWeight.w600, color: color ?? t.muted)), amount]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardBox(
          title: 'Items',
          child: Column(
            children: [
              for (final i in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      ItemPic(id: i['id'] as int, emoji: i['emoji'] as String? ?? ''),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr(i['name'] as String), style: ts(13, w: FontWeight.w600, color: t.text, height: 1.3)),
                            Text('${i['qty']} × ${context.tr(i['unit'] as String)}', style: ts(12.5, w: FontWeight.w500, color: t.muted, height: 1.3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Money((i['price'] as num).toDouble() * (i['qty'] as int), size: 13.5, weight: FontWeight.w700),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CardBox(
          title: 'Delivery',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              kv('When', Text(context.tr(order['slot'] as String), style: value)),
              kv(
                'Address',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${address['building']}, ${address['street']}, ${context.tr(address['area'] as String)}', style: value),
                    if (landmark.isNotEmpty) Text(context.tr('Near $landmark'), style: ts(13, color: t.muted)),
                  ],
                ),
              ),
              kv('Contact', Text('${customer['name']} · ${customer['phone']}', style: value)),
              kv('Payment', Text(context.tr(order['payment'] as String), style: value)),
              if (notes.isNotEmpty) kv('Notes', Text(notes, style: value)),
              const SizedBox(height: 10),
              line(context.tr('Subtotal'), Money((totals['subtotal'] as num).toDouble(), size: 13.5, weight: FontWeight.w700)),
              if ((totals['discount'] as num) > 0)
                line(context.tr('Promo ${totals['promo']}'), Money((totals['discount'] as num).toDouble(), size: 13.5, weight: FontWeight.w700, color: t.good, prefix: '−'), color: t.good),
              line(
                context.tr('Delivery'),
                (totals['delivery'] as num) > 0
                    ? Money((totals['delivery'] as num).toDouble(), size: 13.5, weight: FontWeight.w700)
                    : Text(context.tr('Free'), style: ts(13.5, w: FontWeight.w800, color: t.good)),
              ),
              if ((totals['express'] as num) > 0) line(context.tr('Express'), Money((totals['express'] as num).toDouble(), size: 13.5, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              DashedLine(color: t.line),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Total'), style: ts(15, w: FontWeight.w800, color: t.text)),
                  Money((totals['total'] as num).toDouble(), size: 20, ls: -.02),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
