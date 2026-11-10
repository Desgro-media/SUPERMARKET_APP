import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../widgets/app_icon.dart';
import '../widgets/pressable.dart';
import 'logo.dart';

/// The dark footer at the bottom of every page (`.site-footer`).
class SiteFooter extends ConsumerWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final cfg = cat.config;
    final soft = Colors.white.withValues(alpha: .68);

    Widget link(String label, String route, [Map<String, dynamic>? args]) => Pressable(
          onTap: () => AppNav.go(route, args),
          scale: .98,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(context.tr(label), style: ts(13, color: soft, height: 1.5)),
          ),
        );

    Widget column(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(context.tr(title), style: ts(14, w: FontWeight.w800, color: Colors.white, height: 1.15)),
            ),
            ...children,
          ],
        );

    Widget contact(String icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: AppIcon(icon, size: 16, color: t.sun)),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr(text), style: ts(13, color: soft))),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: 32),
      color: t.deep,
      child: DefaultTextStyle(
        style: ts(13, color: Colors.white.withValues(alpha: .8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 26, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NestLogo(onDark: true),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      context.tr('${cfg.tagline}. Groceries, home essentials and personal care — everything in one place, delivered fast.'),
                      style: ts(13, color: soft),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: column('Shop', [
                          for (final d in cat.depts) link(d.name, Routes.shop, {'dept': d.id}),
                          link('Deals & offers', Routes.shop, {'deal': '1'}),
                          link('New arrivals', Routes.shop, {'sort': 'new'}),
                        ]),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: column('My account', [
                          link('Account', Routes.account),
                          link('My orders', Routes.orders),
                          link('Track order', Routes.track),
                          link('Wishlist', Routes.wishlist),
                          link('Cart', Routes.cart),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: column('Help & info', [
                          link('Customer Support', Routes.support),
                          link('Contact Us', Routes.contact),
                          link('Coupon', Routes.coupons),
                          link('About Us', Routes.about),
                          link('Privacy Policy', Routes.privacy),
                          link('Terms & Conditions', Routes.terms),
                        ]),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: column('Contact', [
                          contact('phone', cfg.contact.phone),
                          contact('mail', cfg.contact.email),
                          contact('clock', cfg.contact.hours),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .1)))),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Text(
                    context.tr('© ${DateTime.now().year} ${cfg.name}. Demo store — products, prices and contact details are placeholders.'),
                    style: ts(11.5, color: Colors.white.withValues(alpha: .5)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${context.tr('Prices include VAT ·')} ', style: ts(11.5, color: Colors.white.withValues(alpha: .5))),
                      Pressable(
                        onTap: () => AppNav.go(Routes.credits),
                        child: Text(
                          context.tr('Photo credits'),
                          style: ts(11.5, color: Colors.white.withValues(alpha: .5), decoration: TextDecoration.underline),
                        ),
                      ),
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
