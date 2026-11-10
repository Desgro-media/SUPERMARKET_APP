import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/page_scroll.dart';
import '../../shell/sheets.dart';
import '../../state/actions.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ui_bits.dart';
import 'sign_in_sheet.dart';

/// "My account": the profile banner, the tiles that lead to orders, help and policies, and the Preferences card with
/// Appearance (light / dark / match device), Language, Colour theme and Delivery city.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _AccountHero(),
                SizedBox(height: 10),
                _AccountTiles(),
                SizedBox(height: 14),
                _Preferences(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountHero extends ConsumerWidget {
  const _AccountHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final user = ref.watch(storeProvider.select((s) => s.user));
    final name = user?['name'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
        boxShadow: t.shadow1,
      ),
      child: Stack(
        children: [
          // the gradient banner
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [t.hero1, t.hero4]),
            ),
          ),
          // the avatar and name overlap the banner by 34dp
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 38, 14, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.brand50,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.surface, width: 4),
                    boxShadow: t.shadow1,
                  ),
                  child: name == null || name.isEmpty
                      ? AppIcon('user', size: 36, color: t.brand600)
                      : Text(name.characters.first.toUpperCase(), style: ts(28, w: FontWeight.w800, color: t.brand600, height: 1.2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name ?? context.tr('Guest'), style: ts(19, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                        const SizedBox(height: 2),
                        Text(
                          user == null ? context.tr('Sign in to check out faster and keep your orders together.') : '${user['contact']}',
                          style: ts(12.5, color: t.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTiles extends ConsumerWidget {
  const _AccountTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final signedIn = ref.watch(storeProvider.select((s) => s.user != null));

    Widget tile(String icon, String label, VoidCallback onTap) => Pressable(
          onTap: onTap,
          scale: .97,
          semanticLabel: context.tr(label),
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.brand50, borderRadius: BorderRadius.circular(13)),
                  child: AppIcon(icon, size: 21, color: t.brand600),
                ),
                const SizedBox(height: 8),
                Text(context.tr(label), textAlign: TextAlign.center, style: ts(12, w: FontWeight.w700, color: t.text, height: 1.3)),
              ],
            ),
          ),
        );

    return EqualHeightGrid(
      columns: 3,
      children: [
        tile('orders', 'My Orders', () => AppNav.go(Routes.orders)),
        tile('track', 'Track Order', () => AppNav.go(Routes.track)),
        tile('profile', 'Profile', () => AppNav.go(Routes.profile)),
        tile('address', 'Address', () => AppNav.go(Routes.address)),
        tile('headset', 'Customer Support', () => AppNav.go(Routes.support)),
        tile('ticket', 'Coupon', () => AppNav.go(Routes.coupons)),
        tile('bell', 'Notification', () => AppNav.go(Routes.notifications)),
        tile('mail', 'Contact Us', () => AppNav.go(Routes.contact)),
        tile('policy', 'Privacy Policy', () => AppNav.go(Routes.privacy)),
        tile('terms', 'Terms & Conditions', () => AppNav.go(Routes.terms)),
        tile('info', 'About Us', () => AppNav.go(Routes.about)),
        if (signedIn)
          tile('logout', 'Logout', () {
            ref.read(storeProvider.notifier).setUser(null);
            ref.read(actionsProvider).toast('Signed out');
          })
        else
          tile('login', 'Login', () => showSignInSheet(context)),
      ],
    );
  }
}

class _Preferences extends ConsumerWidget {
  const _Preferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final cfg = cat.config;
    final store = ref.watch(storeProvider);
    final notifier = ref.read(storeProvider.notifier);
    final area = store.area ?? cfg.areas.first;

    Widget row(String label, Widget control) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(context.tr(label), style: ts(14, w: FontWeight.w600, color: t.text)),
              control,
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(18), boxShadow: t.shadow1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(context.tr('Preferences'), style: ts(16, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
          ),
          row(
            'Appearance',
            SegButtons<String>(
              options: [('light', context.tr('Light')), ('dark', context.tr('Dark')), ('auto', context.tr('Match device'))],
              value: store.theme,
              onChanged: notifier.setTheme,
            ),
          ),
          row(
            'Language',
            SegButtons<String>(
              // language names are always shown in their own language
              options: [for (final l in kLanguages) (l.id, l.name)],
              value: store.lang,
              onChanged: notifier.setLang,
            ),
          ),
          if (cfg.paletteSwitcher)
            row(
              'Colour theme',
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in cfg.palettes)
                    _Swatch(
                      color: Color(0xFF000000 | int.parse(p.color.substring(1), radix: 16)),
                      name: context.tr(p.name),
                      selected: store.palette == p.id,
                      onTap: () => notifier.setPalette(p.id),
                    ),
                ],
              ),
            ),
          row(
            'Delivery city',
            Pressable(
              onTap: () => showAreaSheet(context),
              scale: .98,
              semanticLabel: context.tr('Delivery city'),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr(area), style: ts(14, w: FontWeight.w600, color: t.text, height: 1.2)),
                    const SizedBox(width: 10),
                    AppIcon('down', size: 16, color: t.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One round colour dot of the colour-theme picker; the chosen one gets a dark ring and a tick.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.name, required this.selected, required this.onTap});

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Pressable(
      onTap: onTap,
      scale: .9,
      semanticLabel: name,
      child: Tooltip(
        message: name,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: t.surface, spreadRadius: 2),
              BoxShadow(color: selected ? t.text : t.line, spreadRadius: 4),
            ],
          ),
          child: selected ? const AppIcon('check', size: 18, color: Colors.white, stroke: 3) : null,
        ),
      ),
    );
  }
}
