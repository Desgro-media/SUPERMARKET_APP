import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../state/store.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/pressable.dart';
import 'chrome_scope.dart';
import 'sheets.dart';

/// Which bottom-bar item a route belongs to (`markActive` in the web app's router).
String? navTabFor(String? route) => switch (route) {
      Routes.home || null => 'home',
      Routes.cart || Routes.checkout => 'cart',
      Routes.account ||
      Routes.orders ||
      Routes.track ||
      Routes.profile ||
      Routes.address ||
      Routes.support ||
      Routes.coupons ||
      Routes.notifications ||
      Routes.contact ||
      Routes.privacy ||
      Routes.terms ||
      Routes.about =>
        'account',
      _ => null,
    };

/// The five-button bar at the bottom: Home, Categories, Search, Cart and Account.
class BottomNav extends ConsumerWidget {
  const BottomNav({super.key, required this.activeTab, required this.onSearch});

  final String? activeTab;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    final count = ref.watch(totalsProvider.select((x) => x.count));

    Widget item({required String id, required String icon, required String label, required VoidCallback onTap, int badge = 0}) {
      final on = activeTab == id;
      final color = on ? t.brand600 : t.muted;
      return Expanded(
        child: Pressable(
          onTap: onTap,
          scale: .94,
          semanticLabel: label,
          child: SizedBox(
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavIcon(icon: icon, color: color, stroke: on ? 2.3 : 1.8, badge: badge, bump: id == 'cart'),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(10.5, w: FontWeight.w700, color: color, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: ChromeMetrics.navH + safe,
          padding: EdgeInsets.fromLTRB(2, 4, 2, 4 + safe),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: .94),
            border: Border(top: BorderSide(color: t.line)),
          ),
          child: Row(
            children: [
              item(id: 'home', icon: 'home', label: context.tr('Home'), onTap: AppNav.goHome),
              item(id: 'categories', icon: 'grid', label: context.tr('Categories'), onTap: () => showCategorySheet(context)),
              item(id: 'search', icon: 'search', label: context.tr('Search'), onTap: onSearch),
              item(id: 'cart', icon: 'cart', label: context.tr('Cart'), badge: count, onTap: () => AppNav.go(Routes.cart)),
              item(id: 'account', icon: 'user', label: context.tr('Account'), onTap: () => AppNav.go(Routes.account)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom-bar icon with the optional count badge; the cart's plays the web app's little "bump" when something is added.
class _NavIcon extends ConsumerStatefulWidget {
  const _NavIcon({required this.icon, required this.color, required this.stroke, required this.badge, required this.bump});

  final String icon;
  final Color color;
  final double stroke;
  final int badge;
  final bool bump;

  @override
  ConsumerState<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends ConsumerState<_NavIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.14), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.14, end: 1), weight: 65),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bump) {
      ref.listen(cartBumpProvider, (_, _) => _c.forward(from: 0));
    }
    final t = context.t;
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppIcon(widget.icon, size: 22, color: widget.color, stroke: widget.stroke),
            if (widget.badge > 0)
              PositionedDirectional(top: -5, end: -8, child: CountBadge(widget.badge, border: t.surface)),
          ],
        ),
      ),
    );
  }
}
