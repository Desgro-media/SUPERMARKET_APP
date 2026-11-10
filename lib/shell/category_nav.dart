import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../widgets/pressable.dart';
import 'chrome_scope.dart';

/// Which chip of the row a shop page highlights (`markActive` in the web app): 'deals', a department id or 'new'.
String? activeNavKey(Catalogue cat, Map<String, dynamic> args) {
  final c = args['cat'] as String?;
  if (args['deal'] == '1') return 'deals';
  final dept = args['dept'] as String?;
  if (args['sort'] == 'new' && c == null && dept == null) return 'new';
  return dept ?? (c != null && cat.catById[c] != null ? cat.catById[c]!.dept : null);
}

/// The scrolling row of chips under the header: Deals, the four departments and New arrivals (`.cat-nav`).
class CategoryNav extends ConsumerWidget {
  const CategoryNav({super.key, this.active});

  final String? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);

    Widget chip(String key, String label, VoidCallback onTap, {bool deals = false}) {
      final on = active == key;
      return Pressable(
        onTap: onTap,
        scale: .96,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: on ? t.brand50 : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: ts(13, w: deals ? FontWeight.w800 : FontWeight.w600, color: on ? t.brand600 : (deals ? t.sale : t.muted)),
          ),
        ),
      );
    }

    final chips = <Widget>[
      chip('deals', '\u{1F525} ${context.tr('Deals')}', () => AppNav.go(Routes.shop, {'deal': '1'}), deals: true),
      for (final d in cat.depts) chip(d.id, context.tr(d.name), () => AppNav.go(Routes.shop, {'dept': d.id})),
      chip('new', '✨ ${context.tr('New arrivals')}', () => AppNav.go(Routes.shop, {'sort': 'new'})),
    ];

    return Container(
      height: ChromeMetrics.catNavH,
      decoration: BoxDecoration(color: t.surface, border: Border(top: BorderSide(color: t.line))),
      // the chips fade out at the end of the row to hint that it scrolls (the CSS mask-image)
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 1 - 48 / r.width, 1],
        ).createShader(r, textDirection: Directionality.of(context)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(start: 12, end: 36),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Center(child: chips[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
