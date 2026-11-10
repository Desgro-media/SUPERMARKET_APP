import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../data/catalogue.dart';
import '../../shell/page_scroll.dart';
import '../../state/store.dart';
import '../../widgets/ui_bits.dart';
import 'hero_carousel.dart';
import 'home_sections.dart';

/// The home page: hero, promo banners, why-shop-with-us bar, categories, today's deals, popular products,
/// a baby banner, new arrivals, recently viewed, brands and the newsletter (V.home in the web app).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(catalogueProvider);
    final recentIds = ref.watch(storeProvider.select((s) => s.recent));
    final recent = [for (final id in recentIds) if (cat.byId[id] != null) cat.byId[id]!].take(8).toList();
    final fresh = mixedNew(cat, 10);

    Widget section(Widget child) => Padding(padding: const EdgeInsets.fromLTRB(12, 24, 12, 0), child: child);

    return PageScroll(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // hero + promo banners + trust bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [HeroCarousel(), SizedBox(height: 8), PromoCards(), SizedBox(height: 10), TrustBar()],
              ),
            ),
            section(Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHead(title: context.tr('Shop by category'), sub: context.tr('Groceries, beauty, home and more — all in one place')),
                const CategoryRail(),
              ],
            )),
            Padding(padding: const EdgeInsets.fromLTRB(8, 24, 8, 0), child: const DealsBand()),
            section(const PopularSection()),
            section(const WidePromo()),
            section(Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHead(
                  title: context.tr('New arrivals'),
                  sub: context.tr('Just landed on our shelves'),
                  trailing: LinkMore(context.tr('View all'), onTap: () => AppNav.go(Routes.shop, {'sort': 'new'})),
                ),
                ProductScroller(products: fresh),
              ],
            )),
            if (recent.isNotEmpty)
              section(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHead(title: context.tr('Recently viewed'), sub: context.tr('Pick up where you left off')),
                  ProductScroller(products: recent),
                ],
              )),
            section(Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [SectionHead(title: context.tr('Shop by brand')), const BrandRow()],
            )),
            section(const NewsletterBox()),
          ]),
        ),
      ],
    );
  }
}
