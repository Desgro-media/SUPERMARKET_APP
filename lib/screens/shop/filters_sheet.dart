import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/pressable.dart';
import 'shop_logic.dart';

/// The Filters sheet: department, category, price, brand and the three "show only" switches. Every change is applied to the
/// list behind the sheet straight away, and the button at the bottom shows how many products match.
Future<void> showFiltersSheet(BuildContext context, ValueNotifier<ShopFilters> filters) =>
    showAppSheet<void>(context, (_) => _FiltersSheet(filters: filters));

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.filters});

  final ValueNotifier<ShopFilters> filters;

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  final _min = TextEditingController(), _max = TextEditingController();
  Timer? _debounce;

  ShopFilters get _f => widget.filters.value;

  @override
  void initState() {
    super.initState();
    _min.text = _f.min;
    _max.text = _f.max;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _set(ShopFilters Function(ShopFilters f) change) {
    widget.filters.value = change(_f).copyWith(page: 1);
  }

  void _priceTyped() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _set((f) => f.copyWith(min: _min.text.trim(), max: _max.text.trim())));
  }

  Widget _group(BuildContext context, String title, Widget child, {bool first = false}) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: t.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: ts(14, w: FontWeight.w800, color: t.text))),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final media = MediaQuery.of(context);
    return ValueListenableBuilder<ShopFilters>(
      valueListenable: widget.filters,
      builder: (context, f, _) {
        final list = shopBase(cat, f, translate: context.tr);
        // counts for the department and category lists ignore their own filter
        final catCounts = <String, int>{}, deptCounts = <String, int>{};
        for (final p in shopBase(cat, f, skipCat: true, translate: context.tr)) {
          catCounts[p.cat] = (catCounts[p.cat] ?? 0) + 1;
        }
        for (final p in shopBase(cat, f, skipCat: true, skipDept: true, translate: context.tr)) {
          deptCounts[p.dept] = (deptCounts[p.dept] ?? 0) + 1;
        }
        final cats = cat.categories.where((c) => f.dept.isEmpty || c.dept == f.dept).toList();
        final totalCats = cats.fold<int>(0, (n, c) => n + (catCounts[c.id] ?? 0));
        final totalDepts = deptCounts.values.fold<int>(0, (a, b) => a + b);
        final cur = context.tr(cat.config.currency);

        return Container(
          constraints: BoxConstraints(maxHeight: media.size.height * .86),
          decoration: BoxDecoration(color: t.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), boxShadow: t.shadow2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 0),
                child: Row(
                  children: [
                    Expanded(child: Text(context.tr('Filters'), style: ts(20, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02))),
                    Pressable(
                      onTap: () {
                        _min.clear();
                        _max.clear();
                        widget.filters.value = _f.cleared().copyWith(q: '');
                      },
                      child: Text(context.tr('Clear all'), style: ts(14, w: FontWeight.w700, color: t.brand600)),
                    ),
                    IconCircleButton(icon: 'x', size: 44, semanticLabel: context.tr('Close filters'), onTap: () => Navigator.of(context).maybePop()),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _group(
                      context,
                      context.tr('Department'),
                      Column(children: [
                        ToggleRow(label: context.tr('All departments'), style: ToggleStyle.radio, value: f.dept.isEmpty, count: totalDepts, onChanged: (_) => _set((x) => x.copyWith(dept: '', cat: ''))),
                        for (final d in cat.depts)
                          ToggleRow(
                            label: context.tr(d.name),
                            style: ToggleStyle.radio,
                            value: f.dept == d.id,
                            count: deptCounts[d.id] ?? 0,
                            onChanged: (_) => _set((x) => x.copyWith(dept: d.id, cat: x.cat.isNotEmpty && cat.catById[x.cat]!.dept != d.id ? '' : x.cat)),
                          ),
                      ]),
                      first: true,
                    ),
                    _group(
                      context,
                      context.tr('Category'),
                      Column(children: [
                        ToggleRow(label: context.tr('All categories'), style: ToggleStyle.radio, value: f.cat.isEmpty, count: totalCats, onChanged: (_) => _set((x) => x.copyWith(cat: ''))),
                        for (final c in cats) ToggleRow(label: context.tr(c.name), style: ToggleStyle.radio, value: f.cat == c.id, count: catCounts[c.id] ?? 0, onChanged: (_) => _set((x) => x.copyWith(cat: c.id))),
                      ]),
                    ),
                    _group(
                      context,
                      '${context.tr('Price')} ($cur)',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _PriceBox(controller: _min, hint: context.tr('Min'), onChanged: _priceTyped)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('–', style: ts(14, color: t.muted))),
                              Expanded(child: _PriceBox(controller: _max, hint: context.tr('Max'), onChanged: _priceTyped)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final (label, lo, hi) in kPricePresets)
                                _PresetChip(
                                  label: context.tr(label),
                                  on: f.min == lo && f.max == hi,
                                  onTap: () {
                                    final on = f.min == lo && f.max == hi;
                                    _min.text = on ? '' : lo;
                                    _max.text = on ? '' : hi;
                                    _set((x) => x.copyWith(min: on ? '' : lo, max: on ? '' : hi));
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _group(
                      context,
                      context.tr('Brand'),
                      Column(children: [
                        for (final b in cat.brands)
                          ToggleRow(
                            label: context.tr(b),
                            value: f.brands.contains(b),
                            onChanged: (on) => _set((x) => x.copyWith(brands: on ? [...x.brands, b] : [for (final y in x.brands) if (y != b) y])),
                          ),
                      ]),
                    ),
                    _group(
                      context,
                      context.tr('Show only'),
                      Column(children: [
                        ToggleRow(label: context.tr('On sale'), style: ToggleStyle.toggle, value: f.deal, onChanged: (v) => _set((x) => x.copyWith(deal: v))),
                        ToggleRow(label: context.tr('In stock'), style: ToggleStyle.toggle, value: f.stock, onChanged: (v) => _set((x) => x.copyWith(stock: v))),
                        ToggleRow(label: context.tr('Rated 4★ & up'), style: ToggleStyle.toggle, value: f.rate, onChanged: (v) => _set((x) => x.copyWith(rate: v))),
                      ]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + media.viewPadding.bottom),
                decoration: BoxDecoration(color: t.surface, border: Border(top: BorderSide(color: t.line))),
                child: AppButton(
                  label: context.tr('Show ${list.length} items'),
                  height: 46,
                  expand: true,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.controller, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => onChanged(),
        cursorColor: t.brand,
        style: ts(16, color: t.text, height: 1.2),
        decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: hint, hintStyle: ts(16, color: t.muted, height: 1.2)),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Pressable(
      onTap: onTap,
      scale: .96,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? t.brand50 : t.surface,
          border: Border.all(color: on ? t.brand : t.line, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: ts(12.5, w: FontWeight.w600, color: on ? t.brand600 : t.text, height: 1.2)),
      ),
    );
  }
}
