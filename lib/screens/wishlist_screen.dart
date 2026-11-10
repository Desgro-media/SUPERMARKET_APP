import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../shell/page_scroll.dart';
import '../state/actions.dart';
import '../state/store.dart';
import '../widgets/buttons.dart';
import '../widgets/page_widgets.dart';
import '../widgets/product_card.dart';

/// The products the visitor saved with the heart.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final ids = ref.watch(storeProvider.select((s) => s.wish));
    final items = [for (final id in ids) if (cat.byId[id] != null) cat.byId[id]!];
    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle('Wishlist'),
              if (items.isEmpty)
                EmptyState(
                  emoji: '\u{1F49A}',
                  title: 'Your wishlist is empty',
                  text: 'Tap the heart on any product to save it here for later.',
                  tall: true,
                  actions: [AppButton(label: context.tr('Discover products'), height: 46, onTap: () => AppNav.go(Routes.shop))],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Text(
                              context.tr('${items.length} saved item${items.length == 1 ? '' : 's'}'),
                              style: ts(14, w: FontWeight.w700, color: t.muted),
                            ),
                            AppButton(label: context.tr('Add all to cart'), icon: 'cart', onTap: ref.read(actionsProvider).wishAll),
                          ],
                        ),
                      ),
                      ProductGrid(products: items),
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
