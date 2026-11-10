import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/category_nav.dart';
import '../../shell/page_scroll.dart';
import '../../shell/sheets.dart';
import '../../state/store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/product_card.dart';
import 'filters_sheet.dart';
import 'shop_logic.dart';

const String _kViewKey = 'freshnest.view';

/// The shop: search results and category pages with filters, sorting, a grid or list layout and "Load more".
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.args = const {}});

  final Map<String, dynamic> args;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  late final ValueNotifier<ShopFilters> _filters;
  bool _list = false;

  @override
  void initState() {
    super.initState();
    _filters = ValueNotifier(ShopFilters.fromArgs(ref.read(catalogueProvider), widget.args));
    _list = ref.read(prefsProvider).getString(_kViewKey) == 'list';
  }

  @override
  void dispose() {
    _filters.dispose();
    super.dispose();
  }

  void _setView(bool list) {
    ref.read(prefsProvider).setString(_kViewKey, list ? 'list' : 'grid');
    setState(() => _list = list);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final cfg = cat.config;
    return ValueListenableBuilder<ShopFilters>(
      valueListenable: _filters,
      builder: (context, f, _) {
        final all = shopSorted(shopBase(cat, f, translate: context.tr), f.sort);
        final shown = all.length < f.page * cfg.pageSize ? all.length : f.page * cfg.pageSize;
        final visible = all.sublist(0, shown);
        final cols = MediaQuery.sizeOf(context).width - 24 < 560 ? 2 : (MediaQuery.sizeOf(context).width - 24 < 820 ? 3 : 4);
        final perRow = _list ? 1 : cols;
        final rowCount = (visible.length / perRow).ceil();

        // the chips of active filters under the toolbar
        final chips = <(String, String)>[
          if (f.q.isNotEmpty) ('q', 'Search: ${f.q}'),
          if (f.dept.isNotEmpty) ('dept', cat.deptById[f.dept]!.name),
          if (f.cat.isNotEmpty) ('cat', cat.catById[f.cat]!.name),
          for (final b in f.brands) ('brand:$b', b),
          if (f.min.isNotEmpty || f.max.isNotEmpty) ('price', '${cfg.currency} ${f.min.isEmpty ? '0' : f.min}${f.max.isNotEmpty ? ' – ${f.max}' : '+'}'),
          if (f.deal) ('deal', 'On sale'),
          if (f.stock) ('stock', 'In stock'),
          if (f.rate) ('rate', '4★ & up'),
        ];
        void remove(String k) {
          if (k == 'q') {
            _filters.value = f.copyWith(q: '', page: 1);
          } else if (k == 'dept') {
            _filters.value = f.copyWith(dept: '', page: 1);
          } else if (k == 'cat') {
            _filters.value = f.copyWith(cat: '', page: 1);
          } else if (k == 'price') {
            _filters.value = f.copyWith(min: '', max: '', page: 1);
          } else if (k.startsWith('brand:')) {
            _filters.value = f.copyWith(brands: [for (final b in f.brands) if (b != k.substring(6)) b], page: 1);
          } else if (k == 'deal') {
            _filters.value = f.copyWith(deal: false, page: 1);
          } else if (k == 'stock') {
            _filters.value = f.copyWith(stock: false, page: 1);
          } else if (k == 'rate') {
            _filters.value = f.copyWith(rate: false, page: 1);
          }
        }

        final sortLabel = kSorts.firstWhere((s) => s.$1 == f.sort, orElse: () => kSorts.first).$2;
        final title = shopTitle(cat, f);

        Widget viewButton(bool list, String icon) => Pressable(
              onTap: () => _setView(list),
              scale: .94,
              semanticLabel: context.tr(list ? 'List view' : 'Grid view'),
              child: Container(
                height: 28,
                constraints: const BoxConstraints(minWidth: 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _list == list ? t.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _list == list ? t.shadow1 : null,
                ),
                child: AppIcon(icon, size: 16, color: _list == list ? t.text : t.muted),
              ),
            );

        return PageScroll(
          activeNav: activeNavKey(cat, {'cat': f.cat, 'dept': f.dept, 'deal': f.deal ? '1' : '', 'sort': f.sort == 'new' ? 'new' : ''}),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Crumbs([Crumbs.home, ('Shop', null)]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(context.tr(title), style: ts(22, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
                        Text(context.tr('${all.length} product${all.length == 1 ? '' : 's'}'), style: ts(12.5, w: FontWeight.w600, color: t.muted)),
                      ],
                    ),
                  ),
                  // toolbar: [Filters] [Sort ........] [grid | list]
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () => showFiltersSheet(context, _filters),
                          scale: .97,
                          semanticLabel: context.tr('Filters'),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon('filter', size: 17, color: t.text),
                                const SizedBox(width: 8),
                                Text(context.tr('Filters'), style: ts(13, w: FontWeight.w700, color: t.text, height: 1.2)),
                                if (chips.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 17),
                                    height: 17,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: t.badgeBg, borderRadius: BorderRadius.circular(999)),
                                    child: Text('${chips.length}', style: ts(10, w: FontWeight.w800, color: t.badgeFg, height: 1)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Pressable(
                            onTap: () async {
                              final pick = await showChoiceSheet<String>(context, title: 'Sort by', options: kSorts, current: f.sort);
                              if (pick != null) _filters.value = f.copyWith(sort: pick, page: 1);
                            },
                            scale: .98,
                            semanticLabel: context.tr('Sort by'),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(999)),
                              child: Row(
                                children: [
                                  Expanded(child: Text(context.tr(sortLabel), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, w: FontWeight.w700, color: t.text, height: 1.2))),
                                  AppIcon('down', size: 16, color: t.muted, stroke: 2.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [viewButton(false, 'grid'), const SizedBox(width: 2), viewButton(true, 'list')]),
                        ),
                      ],
                    ),
                  ),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            for (final (key, label) in chips)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 8),
                                child: Pressable(
                                  onTap: () => remove(key),
                                  scale: .96,
                                  semanticLabel: '${context.tr('Remove')} $label',
                                  child: Container(
                                    height: 28,
                                    padding: const EdgeInsetsDirectional.only(start: 11, end: 10),
                                    decoration: BoxDecoration(color: t.brand50, border: Border.all(color: t.brand, width: 1.5), borderRadius: BorderRadius.circular(999)),
                                    child: Row(
                                      children: [
                                        Text(context.tr(key == 'q' ? 'Search: ${f.q}' : label), style: ts(12, w: FontWeight.w600, color: t.brand600, height: 1.2)),
                                        const SizedBox(width: 6),
                                        AppIcon('x', size: 14, color: t.brand600),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (chips.length > 1)
                              Pressable(
                                onTap: () => _filters.value = f.cleared(),
                                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(context.tr('Clear all'), style: ts(12.5, w: FontWeight.w700, color: t.brand600))),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            if (all.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  emoji: '\u{1F50D}',
                  title: 'No products found',
                  text: '${f.q.isNotEmpty ? "We couldn't find anything for “${f.q}” with these filters." : 'No products match these filters.'} Try removing a filter or browse a category.',
                  actions: [
                    AppButton(label: context.tr('Clear all filters'), onTap: () => _filters.value = f.cleared()),
                    AppButton(label: context.tr('Browse everything'), kind: BtnKind.outline, onTap: () => _filters.value = f.cleared()),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList.builder(
                  itemCount: rowCount,
                  itemBuilder: (context, r) {
                    final cells = <Widget>[];
                    for (var c = 0; c < perRow; c++) {
                      final k = r * perRow + c;
                      if (c > 0) cells.add(const SizedBox(width: 8));
                      final Widget cell = k >= visible.length
                          ? const SizedBox.shrink()
                          : (_list ? ProductListCard(visible[k], key: ValueKey('l${visible[k].id}')) : ProductCard(visible[k], key: ValueKey(visible[k].id)));
                      cells.add(Expanded(child: cell));
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
                      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)),
                    );
                  },
                ),
              ),
            if (all.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 22, 12, 6),
                  child: shown < all.length
                      ? Column(
                          children: [
                            Text(context.tr('Showing $shown of ${all.length}'), style: ts(14, w: FontWeight.w600, color: t.muted)),
                            const SizedBox(height: 8),
                            FractionallySizedBox(widthFactor: .7, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 260), child: ProgressBar(shown / all.length * 100, color: t.brand))),
                            const SizedBox(height: 8),
                            AppButton(label: context.tr('Load more'), kind: BtnKind.outline, height: 46, onTap: () => _filters.value = f.copyWith(page: f.page + 1)),
                          ],
                        )
                      : Text(context.tr("You've seen all ${all.length} item${all.length == 1 ? '' : 's'}"), textAlign: TextAlign.center, style: ts(14, w: FontWeight.w600, color: t.muted)),
                ),
              ),
          ],
        );
      },
    );
  }
}
