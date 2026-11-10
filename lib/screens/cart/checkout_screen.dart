import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/page_scroll.dart';
import '../../shell/sheets.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cart_widgets.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/product_art.dart';
import '../../widgets/ui_bits.dart';
import 'cart_screen.dart' show EmptyCart;

final RegExp kPhonePattern = RegExp(r'^[+\d][\d\s-]{7,16}$');
final RegExp kEmailPattern = RegExp(r'^\S+@\S+\.\S+$');

/// Is a delivery slot like "10:00 – 12:00" still bookable? Tomorrow always is; today needs one hour's notice.
bool slotAvailable(String slot, String day, DateTime now) {
  if (day == 'tomorrow') return true;
  final hour = int.tryParse(RegExp(r'^\d+').firstMatch(slot)?.group(0) ?? '') ?? 0;
  return hour * 60 >= now.hour * 60 + now.minute + 60;
}

/// Express delivery is offered between 7:00 and 21:00.
bool expressOpen(DateTime now) => now.hour >= 7 && now.hour < 21;

/// A numbered white card of the checkout form ("1  Contact").
class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.number, required this.title, required this.child, this.note});

  final int number;
  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.brand, shape: BoxShape.circle),
                child: Text('$number', style: ts(13, w: FontWeight.w800, color: t.onBrand, height: 1.2)),
              ),
              const SizedBox(width: 10),
              Text(context.tr(title), style: ts(16, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
              if (note != null) ...[const SizedBox(width: 6), Text(context.tr(note!), style: ts(14, w: FontWeight.w600, color: t.muted))],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _c = {for (final n in ['name', 'phone', 'email', 'street', 'building', 'landmark', 'notes']) n: TextEditingController()};
  final Map<String, String?> _errors = {};
  late String _area;
  String _dtype = 'slot', _day = 'today', _pay = 'Cash on delivery';
  String? _slot;
  String? _formError;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(storeProvider);
    final cfg = ref.read(catalogueProvider).config;
    final u = s.user, a = s.addr ?? const <String, dynamic>{};
    final contact = (u?['contact'] as String?) ?? '';
    if (u != null) _c['name']!.text = u['name'] as String;
    if (u != null && contact.contains('@')) _c['email']!.text = contact;
    if (u != null && contact.isNotEmpty && !contact.contains('@')) _c['phone']!.text = contact;
    for (final k in ['name', 'phone', 'email', 'street', 'building', 'landmark']) {
      final v = a[k] as String?;
      if (v != null && v.isNotEmpty) _c[k]!.text = v;
    }
    _area = (a['area'] as String?) ?? s.area ?? cfg.areas.first;
    final now = DateTime.now();
    _day = cfg.slots.any((x) => slotAvailable(x, 'today', now)) ? 'today' : 'tomorrow';
    _pickFirstSlot();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _pickFirstSlot() {
    final cfg = ref.read(catalogueProvider).config;
    final now = DateTime.now();
    _slot = null;
    for (final s in cfg.slots) {
      if (slotAvailable(s, _day, now)) {
        _slot = s;
        break;
      }
    }
  }

  String _v(String n) => _c[n]!.text.trim();

  bool _check(String name) {
    final val = _v(name);
    String? msg;
    const required = {'name', 'phone', 'street', 'building'};
    if (required.contains(name) && val.isEmpty) {
      msg = 'This field is required';
    } else if (name == 'phone' && !kPhonePattern.hasMatch(val)) {
      msg = 'Enter a valid mobile number';
    } else if (name == 'email' && val.isNotEmpty && !kEmailPattern.hasMatch(val)) {
      msg = 'Enter a valid email address';
    }
    setState(() => _errors[name] = msg);
    return msg == null;
  }

  void _submit() {
    final bad = [for (final n in ['name', 'phone', 'email', 'street', 'building']) if (!_check(n)) n];
    if (bad.isNotEmpty) {
      setState(() => _formError = 'Please fix the highlighted fields.');
      return;
    }
    final express = _dtype == 'express';
    if (!express && _slot == null) {
      setState(() => _formError = 'Please choose a delivery time slot.');
      return;
    }
    setState(() => _formError = null);
    final addr = {
      'name': _v('name'),
      'phone': _v('phone'),
      'email': _v('email'),
      'area': _area,
      'street': _v('street'),
      'building': _v('building'),
      'landmark': _v('landmark'),
    };
    final store = ref.read(storeProvider.notifier);
    store.saveAddress(addr);
    _placed = true; // stops the "cart is empty, go back to the cart" redirect
    final order = store.placeOrder(
      express: express,
      customer: {'name': addr['name'], 'phone': addr['phone'], 'email': addr['email']},
      address: {'area': addr['area'], 'street': addr['street'], 'building': addr['building'], 'landmark': addr['landmark']},
      slot: express ? 'Express · within 60 minutes' : '${_day == 'today' ? 'Today' : 'Tomorrow'}, $_slot',
      payment: _pay,
      notes: _v('notes'),
    );
    AppNav.replace(Routes.order, {'id': order['id']});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final cfg = cat.config;
    final express = _dtype == 'express';
    final totals = computeTotals(ref.watch(storeProvider), cat, express: express);
    // if the cart empties while this page is open (everything removed elsewhere), go back to the cart
    ref.listen(totalsProvider.select((x) => x.count), (prev, next) {
      if (next == 0 && !_placed) AppNav.replace(Routes.cart);
    });

    if (totals.count == 0) {
      return PageScroll(
        slivers: [
          SliverToBoxAdapter(
            child: EmptyCart(title: 'Nothing to check out yet', text: 'Your cart is empty. Add a few items and come back.'),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final todayOk = cfg.slots.any((s) => slotAvailable(s, 'today', now));
    final expressOk = expressOpen(now);

    Widget field(String id, String label, {bool req = false, TextInputType? type, Iterable<String>? hints, TextInputAction? action}) => AppField(
          label: context.tr(label),
          controller: _c[id]!,
          required: req,
          error: _errors[id] == null ? null : context.tr(_errors[id]!),
          keyboardType: type,
          autofillHints: hints,
          textInputAction: action ?? TextInputAction.next,
          onBlur: id == 'landmark' ? null : () => _check(id),
          onChanged: (_) {
            if (_errors[id] != null) _check(id);
          },
        );

    const gap = SizedBox(height: 12);
    final steps = <Widget>[
      StepCard(
        number: 1,
        title: 'Contact',
        child: Column(children: [
          field('name', 'Full name', req: true, hints: const [AutofillHints.name]),
          gap,
          field('phone', 'Mobile number', req: true, type: TextInputType.phone, hints: const [AutofillHints.telephoneNumber]),
          gap,
          field('email', 'Email (for your receipt)', type: TextInputType.emailAddress, hints: const [AutofillHints.email]),
        ]),
      ),
      StepCard(
        number: 2,
        title: 'Delivery address',
        child: Column(children: [
          SelectField(
            label: context.tr('City'),
            required: true,
            value: context.tr(_area),
            onTap: () async {
              final pick = await showChoiceSheet<String>(context, title: 'City', options: [for (final a in cfg.areas) (a, a)], current: _area);
              if (pick != null) setState(() => _area = pick);
            },
          ),
          gap,
          field('street', 'Street / neighbourhood', req: true, hints: const [AutofillHints.streetAddressLine1]),
          gap,
          field('building', 'Building, floor & flat', req: true, hints: const [AutofillHints.streetAddressLine2]),
          gap,
          field('landmark', 'Nearest landmark (optional)'),
        ]),
      ),
      StepCard(
        number: 3,
        title: 'Delivery time',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OptCard(
              title: 'Scheduled',
              subtitle: 'Pick a time that suits you · ${totals.delivery > 0 ? moneyText(totals.delivery, cfg.currency) : 'Free'}',
              selected: !express,
              onTap: () => setState(() => _dtype = 'slot'),
            ),
            const SizedBox(height: 8),
            OptCard(
              title: 'Express',
              titleIcon: AppIcon('zap', size: 16, color: t.accent),
              subtitle: expressOk ? 'Within 60 minutes · +${moneyText(cfg.expressFee, cfg.currency)}' : 'Available 7:00 – 21:00',
              selected: express,
              enabled: expressOk,
              onTap: () => setState(() => _dtype = 'express'),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: express ? .4 : 1,
              child: IgnorePointer(
                ignoring: express,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (id, label, ok) in [('today', 'Today', todayOk), ('tomorrow', 'Tomorrow', true)])
                            Pressable(
                              onTap: ok ? () => setState(() { _day = id; _pickFirstSlot(); }) : null,
                              scale: .96,
                              child: Opacity(
                                opacity: ok ? 1 : .4,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _day == id ? t.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: _day == id ? t.shadow1 : null,
                                  ),
                                  child: Text(context.tr(label), style: ts(14, w: FontWeight.w700, color: _day == id ? t.text : t.muted, height: 1.2)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EqualHeightGrid(
                      columns: 2,
                      children: [
                        for (final s in cfg.slots)
                          Builder(builder: (context) {
                            final ok = slotAvailable(s, _day, now), on = _slot == s;
                            return Opacity(
                              opacity: ok ? 1 : .4,
                              child: Pressable(
                                onTap: ok ? () => setState(() => _slot = s) : null,
                                scale: .97,
                                semanticLabel: s,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: on ? t.brand : Colors.transparent,
                                    border: Border.all(color: on ? t.brand : t.line, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    s,
                                    style: ts(13, w: FontWeight.w700, color: on ? t.onBrand : t.text, height: 1.3, tabular: true, decoration: ok ? null : TextDecoration.lineThrough),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      StepCard(
        number: 4,
        title: 'Payment',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OptCard(title: 'Cash on delivery', subtitle: 'Pay the driver when your order arrives', selected: _pay == 'Cash on delivery', onTap: () => setState(() => _pay = 'Cash on delivery')),
            const SizedBox(height: 8),
            OptCard(title: 'Card on delivery', subtitle: 'Driver brings a card machine', selected: _pay == 'Card on delivery', onTap: () => setState(() => _pay = 'Card on delivery')),
            const Hint("Online card payment isn't part of this demo, so no card details are collected."),
          ],
        ),
      ),
      StepCard(
        number: 5,
        title: 'Notes',
        note: '(optional)',
        child: AppField(
          label: '',
          controller: _c['notes']!,
          hint: context.tr('Substitution preferences, gate code, ring the bell…'),
          maxLines: 3,
          minLines: 3,
          maxLength: 300,
          keyboardType: TextInputType.multiline,
        ),
      ),
    ];

    final summary = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(20), boxShadow: t.shadow1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('Order summary'), style: ts(17, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [
                for (final l in totals.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(10)),
                          child: PhotoOrEmoji(src: l.p.hasPhoto ? l.p.thumbs[0] : '', emoji: l.p.emoji, emojiSize: 20, cacheWidth: 120),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr(l.p.name), maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(13, w: FontWeight.w600, color: t.text, height: 1.3)),
                              Text('${l.qty} × ${context.tr(l.p.unit)}', style: ts(12.5, w: FontWeight.w500, color: t.muted, height: 1.3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Money(l.total, size: 13.5, weight: FontWeight.w700),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SummaryRows(totals),
          if (_formError != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(context.tr(_formError!), style: ts(14, w: FontWeight.w700, color: t.danger))),
          const SizedBox(height: 12),
          AppButton(label: context.tr('Place order'), height: 46, expand: true, onTap: _submit),
          const SizedBox(height: 12),
          Text(context.tr('By placing your order you agree to our terms. Prices include VAT.'), textAlign: TextAlign.center, style: ts(12.5, color: t.muted)),
        ],
      ),
    );

    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Crumbs([('Cart', () => AppNav.back()), ('Checkout', null)]),
              const PageTitle('Checkout'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[if (i > 0) const SizedBox(height: 10), steps[i]],
                    const SizedBox(height: 14),
                    summary,
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
