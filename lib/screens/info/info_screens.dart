import 'dart:convert';

import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/links.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/page_scroll.dart';
import '../../shell/sheets.dart';
import '../../state/actions.dart';
import '../../state/orders.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../cart/checkout_screen.dart' show kEmailPattern, kPhonePattern;
import 'info_widgets.dart';

// ---------------------------------------------------------------------------------------------------- profile

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController(), _phone = TextEditingController(), _email = TextEditingController();
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    final u = ref.read(storeProvider).user;
    if (u != null) {
      final contact = (u['contact'] as String?) ?? '';
      _name.text = (u['name'] as String?) ?? '';
      _email.text = (u['email'] as String?) ?? (contact.contains('@') ? contact : '');
      _phone.text = (u['phone'] as String?) ?? (contact.isNotEmpty && !contact.contains('@') ? contact : '');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim(), ph = _phone.text.trim(), em = _email.text.trim();
    setState(() {
      _errors['name'] = name.isEmpty ? 'This field is required' : null;
      _errors['phone'] = ph.isNotEmpty && !kPhonePattern.hasMatch(ph) ? 'Enter a valid mobile number' : null;
      _errors['email'] = em.isNotEmpty && !kEmailPattern.hasMatch(em) ? 'Enter a valid email address' : null;
      if (_errors.values.every((e) => e == null) && em.isEmpty && ph.isEmpty) _errors['email'] = 'Add an email or a mobile number';
    });
    if (_errors.values.any((e) => e != null)) return;
    ref.read(storeProvider.notifier).setUser({'name': name, 'contact': em.isNotEmpty ? em : ph, 'email': em, 'phone': ph});
    ref.read(actionsProvider).toast('Profile updated');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final user = ref.watch(storeProvider.select((s) => s.user));
    if (user == null) return const SignInPrompt(title: 'Profile', text: 'Sign in to view and edit your profile.');
    String? e(String k) => _errors[k] == null ? null : context.tr(_errors[k]!);
    final name = (user['name'] as String?) ?? '';
    return InfoPage(
      title: 'Profile',
      lead: 'Keep your details up to date so checkout is quicker.',
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Avatar(name.isEmpty ? '?' : name.characters.first.toUpperCase(), size: 52, fontSize: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: ts(14, w: FontWeight.w700, color: t.text)),
                        Text('${user['contact'] ?? ''}', style: ts(12.5, color: t.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppField(label: context.tr('Full name'), controller: _name, required: true, error: e('name'), textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name]),
              const SizedBox(height: 12),
              AppField(label: context.tr('Mobile number'), controller: _phone, error: e('phone'), keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              AppField(label: context.tr('Email'), controller: _email, error: e('email'), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppButton(label: context.tr('Save changes'), height: 46, horizontal: 12, expand: true, onTap: _save)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: context.tr('Sign out'),
                      icon: 'logout',
                      kind: BtnKind.outline,
                      height: 46,
                      horizontal: 12,
                      expand: true,
                      onTap: () {
                        ref.read(storeProvider.notifier).setUser(null);
                        ref.read(actionsProvider).toast('Signed out');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------- address

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _c = {for (final n in ['name', 'phone', 'street', 'building', 'landmark']) n: TextEditingController()};
  final Map<String, String?> _errors = {};
  late String _area;

  @override
  void initState() {
    super.initState();
    final s = ref.read(storeProvider);
    final cfg = ref.read(catalogueProvider).config;
    final a = s.addr, u = s.user;
    _c['name']!.text = (a?['name'] as String?) ?? (u?['name'] as String?) ?? '';
    _c['phone']!.text = (a?['phone'] as String?) ?? (u?['phone'] as String?) ?? '';
    for (final k in ['street', 'building', 'landmark']) {
      _c[k]!.text = (a?[k] as String?) ?? '';
    }
    _area = (a?['area'] as String?) ?? s.area ?? cfg.areas.first;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String n) => _c[n]!.text.trim();

  void _save() {
    setState(() {
      for (final n in ['name', 'phone', 'street', 'building']) {
        _errors[n] = _v(n).isEmpty ? 'This field is required' : null;
      }
      if (_errors['phone'] == null && !kPhonePattern.hasMatch(_v('phone'))) _errors['phone'] = 'Enter a valid mobile number';
    });
    if (_errors.values.any((e) => e != null)) return;
    final store = ref.read(storeProvider.notifier);
    final old = ref.read(storeProvider).addr;
    store.saveAddress({
      'name': _v('name'),
      'phone': _v('phone'),
      'email': (old?['email'] as String?) ?? '',
      'area': _area,
      'street': _v('street'),
      'building': _v('building'),
      'landmark': _v('landmark'),
    });
    store.setArea(_area);
    ref.read(actionsProvider).toast('Address saved');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cfg = ref.watch(catalogueProvider).config;
    final a = ref.watch(storeProvider.select((s) => s.addr));
    String? e(String k) => _errors[k] == null ? null : context.tr(_errors[k]!);
    return InfoPage(
      title: 'Address',
      lead: 'Your delivery address is filled in automatically at checkout.',
      children: [
        if (a != null)
          CardBox(
            title: 'Saved address',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${a['name']}', style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                    TextSpan(text: ' · ${a['phone']}\n${a['building']}, ${a['street']}, ${context.tr('${a['area']}')}'),
                    if ((a['landmark'] as String? ?? '').isNotEmpty) TextSpan(text: '\n${context.tr('Near ${a['landmark']}')}', style: ts(13, color: t.muted)),
                  ]),
                  style: ts(14, color: t.muted),
                ),
                const SizedBox(height: 8),
                Pressable(
                  onTap: () {
                    ref.read(storeProvider.notifier).saveAddress(null);
                    ref.read(actionsProvider).toast('Address deleted');
                  },
                  child: Text(context.tr('Delete this address'), style: ts(14, w: FontWeight.w700, color: t.danger)),
                ),
              ],
            ),
          ),
        CardBox(
          title: a != null ? 'Edit address' : 'Add an address',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppField(label: context.tr('Full name'), controller: _c['name']!, required: true, error: e('name'), textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name]),
              const SizedBox(height: 12),
              AppField(label: context.tr('Mobile number'), controller: _c['phone']!, required: true, error: e('phone'), keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              SelectField(
                label: context.tr('City'),
                required: true,
                value: context.tr(_area),
                onTap: () async {
                  final pick = await showChoiceSheet<String>(context, title: 'City', options: [for (final x in cfg.areas) (x, x)], current: _area);
                  if (pick != null) setState(() => _area = pick);
                },
              ),
              const SizedBox(height: 12),
              AppField(label: context.tr('Street / neighbourhood'), controller: _c['street']!, required: true, error: e('street'), textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              AppField(label: context.tr('Building, floor & flat'), controller: _c['building']!, required: true, error: e('building'), textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              AppField(label: context.tr('Nearest landmark (optional)'), controller: _c['landmark']!, textInputAction: TextInputAction.done),
              const SizedBox(height: 16),
              AppButton(label: context.tr('Save address'), height: 46, expand: true, onTap: _save),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------- support + contact

const List<(String, String)> kFaq = [
  ('How fast is delivery?', 'Choose a delivery time slot at checkout, or pick express and we aim to deliver within 60 minutes between 7:00 and 21:00.'),
  ('How much does delivery cost?', 'The delivery fee is shown in your cart before you pay, and delivery is free once your basket passes the free-delivery amount.'),
  ('Which payment methods do you accept?', 'Cash or card on delivery. Online card payment is not part of this demo, so no card details are collected.'),
  ('Can I change or cancel my order?', 'Contact customer support as soon as you can. Orders that are already being packed may not be changeable.'),
  ('What if an item is missing or damaged?', 'Tell us within 24 hours and we will replace it or refund you, no questions asked.'),
  ('How do I use a coupon?', 'Enter the code in your cart under Promo code, or tap Apply on the Coupon page.'),
];

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogueProvider).config.contact;
    final user = ref.watch(storeProvider.select((s) => s.user));
    return InfoPage(
      title: 'Customer Support',
      lead: 'We are here to help, every day. Pick the quickest way to reach us.',
      children: [
        HelpCard(icon: 'phone', title: 'Call us', text: c.phone, onTap: () => openLink(phoneUri(c.phone))),
        HelpCard(icon: 'mail', title: 'Email us', text: c.email, onTap: () => openLink(mailUri(c.email))),
        HelpCard(
          icon: 'chat',
          title: 'Live chat',
          text: 'Chat with our team',
          onTap: () => ref.read(actionsProvider).toast('Live chat is not available in this demo — please call or email us.'),
        ),
        CardBox(
          title: 'Frequently asked questions',
          child: Column(children: [for (var i = 0; i < kFaq.length; i++) FaqItem(question: kFaq[i].$1, answer: kFaq[i].$2, last: i == kFaq.length - 1)]),
        ),
        MessageForm(messageLabel: 'How can we help?', name: user?['name'] as String?, contact: user?['contact'] as String?),
      ],
    );
  }
}

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogueProvider).config.contact;
    final user = ref.watch(storeProvider.select((s) => s.user));
    return InfoPage(
      title: 'Contact Us',
      lead: 'Questions, feedback or a special request? Reach out any time.',
      children: [
        HelpCard(icon: 'phone', title: 'Phone', text: c.phone, onTap: () => openLink(phoneUri(c.phone))),
        HelpCard(icon: 'mail', title: 'Email', text: c.email, onTap: () => openLink(mailUri(c.email))),
        HelpCard(icon: 'clock', title: 'Opening hours', text: c.hours),
        HelpCard(icon: 'pin', title: 'Address', text: c.address),
        MessageForm(messageLabel: 'Your message', name: user?['name'] as String?, contact: user?['contact'] as String?),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------- coupons

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  static const Map<String, String> _fine = {'pct': 'Applies to the whole basket', 'flat': 'Minimum basket applies', 'ship': 'Standard delivery fee waived'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final promos = ref.watch(catalogueProvider).config.promos;
    final active = ref.watch(storeProvider.select((s) => s.promo));
    final actions = ref.read(actionsProvider);

    Widget coupon(String code) {
      final p = promos[code]!;
      final on = active == code;
      return DashedBox(
        color: on ? t.brand : AppTokens.mix(t.brand, .45, t.line),
        fill: on ? t.brand50 : t.surface,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.accent50, borderRadius: BorderRadius.circular(14)),
                  child: AppIcon('ticket', size: 22, color: t.badgeBg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(code, style: ts(20, w: FontWeight.w800, color: t.text, height: 1.2, ls: .06)),
                      Text(context.tr(p.label), style: ts(14, w: FontWeight.w600, color: t.text)),
                      Text(context.tr(_fine[p.type] ?? ''), style: ts(12.5, color: t.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.tr('Copy'),
                    icon: 'copy',
                    kind: BtnKind.outline,
                    height: 36,
                    fontSize: 14,
                    horizontal: 14,
                    expand: true,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      actions.toast('Code $code copied');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: context.tr(on ? 'Applied' : 'Apply'),
                    height: 36,
                    fontSize: 14,
                    horizontal: 14,
                    expand: true,
                    onTap: () => actions.toast(ref.read(storeProvider.notifier).applyPromo(code).msg),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InfoPage(
      title: 'Coupon',
      lead: 'Save on your next order with these codes.',
      children: [
        Column(children: [for (final code in promos.keys) Padding(padding: const EdgeInsets.only(bottom: 12), child: coupon(code))]),
        const Hint('Coupons are applied in your cart. Only one coupon can be used per order.'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------- notifications

class _Note {
  const _Note(this.id, this.icon, this.title, this.text, this.ts, [this.orderId]);

  final String id, icon, title, text;
  final int ts;
  final String? orderId;
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final store = ref.watch(storeProvider);
    final notes = <_Note>[
      for (final o in store.orders.take(5))
        _Note('order-${o['id']}', 'box', 'Order placed', 'Your order #${o['id']} is confirmed. Track it any time from the Track Order page.', (o['ts'] as num).toInt(), o['id'] as String),
      const _Note('welcome', 'bell', 'Welcome!', 'Thanks for choosing us. Use code WELCOME25 for SAR 25 off orders over SAR 120.', 0),
      const _Note('free', 'truck', 'Free delivery', 'Spend over the free-delivery amount and we deliver your order for free.', 0),
      const _Note('deals', 'tag', 'New deals every day', "Prices on today's deals refresh at midnight. Check the Deals tab.", 0),
    ];
    final unread = [for (final n in notes) if (!store.notesRead.contains(n.id)) n.id];

    Widget item(_Note n) {
      final isNew = unread.contains(n.id);
      final inner = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: isNew ? t.surface : t.brand50, borderRadius: BorderRadius.circular(14)),
            child: AppIcon(n.icon, size: 20, color: t.brand600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: context.tr(n.title)),
                    if (isNew)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(color: t.sun, borderRadius: BorderRadius.circular(999)),
                          child: Text(context.tr('New'), style: ts(11, w: FontWeight.w700, color: t.ink, height: 1.4)),
                        ),
                      ),
                  ]),
                  style: ts(14, w: FontWeight.w700, color: t.text, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(context.tr(n.text), style: ts(14, color: t.muted)),
                if (n.ts > 0) Text(context.tr(agoText(n.ts)), style: ts(12.5, color: t.muted)),
              ],
            ),
          ),
        ],
      );
      final box = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isNew ? t.brand50 : t.surface,
          border: Border.all(color: isNew ? AppTokens.mix(t.brand, .35, t.line) : t.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: inner,
      );
      return n.orderId == null ? box : Pressable(onTap: () => AppNav.go(Routes.track, {'id': n.orderId}), scale: .99, child: box);
    }

    return InfoPage(
      title: 'Notification',
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(context.tr(unread.isNotEmpty ? '${unread.length} unread' : 'You are all caught up'), style: ts(14, w: FontWeight.w700, color: t.muted)),
            if (unread.isNotEmpty)
              AppButton(
                label: context.tr('Mark all as read'),
                kind: BtnKind.outline,
                height: 36,
                fontSize: 14,
                horizontal: 14,
                onTap: () => ref.read(storeProvider.notifier).readNotes([for (final n in notes) n.id]),
              ),
          ],
        ),
        Column(children: [for (var i = 0; i < notes.length; i++) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 10), child: item(notes[i]))]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------- privacy, terms, about

class DocScreen extends StatelessWidget {
  const DocScreen({super.key, required this.title, required this.lead, required this.sections});

  final String title, lead;
  final List<List<String>> sections;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return InfoPage(
      title: title,
      lead: lead,
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 22),
                Text(context.tr(sections[i][0]), style: ts(18, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                const SizedBox(height: 8),
                for (final p in sections[i].skip(1)) Text(context.tr(p), style: ts(14, color: t.muted)),
              ],
              const SizedBox(height: 22),
              Text(context.tr('This is sample text for the demo store. Have it reviewed before you go live.'), style: ts(12.5, color: t.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => const DocScreen(title: 'Privacy Policy', lead: 'How we look after your information.', sections: [
        ['What we collect', 'Your name, contact details, delivery address and order history, plus anything you type into a form or review.'],
        ['How we use it', 'To deliver your orders, keep you updated about them, answer your questions and make shopping with us easier.'],
        ['Where it is stored', 'In this demo, your details are saved only in your browser on this device. Clearing your browser data removes them.'],
        ['Sharing', 'We never sell your personal information. We share only what a delivery partner needs to bring you your order.'],
        ['Your choices', 'You can edit or delete your profile and address at any time from your account, and ask us to remove your data.'],
        ['Contact us', 'Questions about privacy? Use the Contact Us page and we will be happy to help.'],
      ]);
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const DocScreen(title: 'Terms & Conditions', lead: 'Please read these terms before you place an order.', sections: [
        ['Orders and prices', 'All prices include VAT. We may correct pricing errors, and an order is confirmed once we accept it. Product photos are for illustration.'],
        ['Delivery', 'Delivery times are estimates. You must be available at your chosen time slot, and we may substitute an unavailable item with a similar one if you allow it.'],
        ['Payment', 'Pay by cash or card on delivery. Please have the right amount ready for cash payments.'],
        ['Returns and refunds', 'If something is missing, damaged or not as described, tell us within 24 hours for a replacement or refund. Unopened non-food items can be returned within 14 days.'],
        ['Coupons and promotions', 'Each coupon has its own conditions, only one coupon can be used per order, and coupons have no cash value.'],
        ['Changes', 'We may update these terms from time to time. Continuing to use the store means you accept the updated terms.'],
      ]);
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const features = [
      ('leaf', 'Fresh and carefully chosen', 'Quality-checked produce, halal meat and trusted brands.'),
      ('truck', 'Fast, reliable delivery', 'Pick a time slot, or choose express for delivery in about an hour.'),
      ('shield', 'Easy returns', 'Not happy with something? We replace it or refund you.'),
      ('tag', 'Fair prices every day', 'New deals daily and coupons you can actually use.'),
    ];
    return InfoPage(
      title: 'About Us',
      lead: 'Fresh food and everyday essentials, delivered to your door.',
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('Who we are'), style: ts(18, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
              const SizedBox(height: 8),
              Text(context.tr('We are a neighbourhood supermarket that brings groceries, personal care, household items and baby essentials to your door, fast and at fair prices.'), style: ts(14, color: t.muted)),
              const SizedBox(height: 22),
              Text(context.tr('What we believe'), style: ts(18, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
              const SizedBox(height: 8),
              Text(context.tr('Great shopping should be simple. We choose products carefully, keep prices honest and treat every order like it is for our own family.'), style: ts(14, color: t.muted)),
              const SizedBox(height: 22),
              Text(context.tr('This is sample text for the demo store. Have it reviewed before you go live.'), style: ts(12.5, color: t.muted)),
            ],
          ),
        ),
        for (final (icon, title, text) in features)
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.brand50, borderRadius: BorderRadius.circular(11)),
                  child: AppIcon(icon, size: 18, color: t.brand600),
                ),
                const SizedBox(height: 10),
                Text(context.tr(title), style: ts(14, w: FontWeight.w700, color: t.text)),
                const SizedBox(height: 6),
                Text(context.tr(text), style: ts(13.5, color: t.muted)),
              ],
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            AppButton(label: context.tr('Start shopping'), height: 46, onTap: () => AppNav.go(Routes.shop)),
            AppButton(label: context.tr('Contact us'), kind: BtnKind.outline, height: 46, onTap: () => AppNav.go(Routes.contact)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------- photo credits

final creditsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/credits.json');
  return [for (final r in jsonDecode(raw) as List) Map<String, dynamic>.from(r as Map)];
});

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final credits = ref.watch(creditsProvider);

    Widget link(String text, String url) => Pressable(
          onTap: url.isEmpty ? null : () => openLink(Uri.parse(url)),
          child: Text(text, style: ts(13, w: FontWeight.w600, color: url.isEmpty ? t.muted : t.brand600, decoration: url.isEmpty ? null : TextDecoration.underline)),
        );

    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Crumbs([Crumbs.home, ('Photo credits', null)]),
              const PageTitle('Photo credits'),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('The demo catalogue uses openly licensed photographs from Wikimedia Commons and from Open Food Facts, Open Beauty Facts and Open Products Facts. Each was cropped and resized for this shop; nothing else was changed.'),
                      style: ts(14, color: t.muted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr("Brand names and packaging that appear in the photos belong to their owners and only illustrate the products. NestMart's own brand names are placeholders."),
                      style: ts(14, color: t.muted),
                    ),
                  ],
                ),
              ),
              credits.when(
                data: (rows) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (final r in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset('assets/images/products/t/${r['file']}', width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 120, errorBuilder: (_, _, _) => const SizedBox(width: 44, height: 44)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(context.tr('${r['product']}'), style: ts(13.5, w: FontWeight.w700, color: t.text, height: 1.3)),
                                      Text('${r['author']}', style: ts(12.5, color: t.muted, height: 1.3)),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          link('${(r['licence'] as Map)['text']}', '${(r['licence'] as Map)['url']}'),
                                          link('${(r['source'] as Map)['text']}', '${(r['source'] as Map)['url']}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))),
                error: (_, _) => Padding(padding: const EdgeInsets.all(24), child: Text(context.tr('The credits could not be loaded.'), style: ts(14, color: t.muted))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
