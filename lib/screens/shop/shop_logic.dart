import 'package:flutter/foundation.dart';

import '../../data/catalogue.dart';
import '../../data/models.dart';
import '../../data/search.dart';
import '../../data/sorting.dart';

/// The sort orders of the shop (value, label).
const List<(String, String)> kSorts = [
  ('rel', 'Best match'),
  ('pop', 'Popular'),
  ('price-asc', 'Lowest price'),
  ('price-desc', 'Highest price'),
  ('rating', 'Top rated'),
  ('off', 'Best discount'),
  ('new', 'Newest'),
];

/// The quick price ranges (label, min, max).
const List<(String, String, String)> kPricePresets = [
  ('Under 10', '', '10'),
  ('10 – 25', '10', '25'),
  ('25 – 50', '25', '50'),
  ('50 – 100', '50', '100'),
  ('100+', '100', ''),
];

String defaultSort(String q) => q.isEmpty ? 'pop' : 'rel';

/// Everything the visitor can set on the shop page: search words, department, category, brands, price range,
/// the three "show only" switches, the sort order and how many pages are loaded (`st` in the web app's V.shop).
@immutable
class ShopFilters {
  const ShopFilters({
    this.q = '',
    this.dept = '',
    this.cat = '',
    this.brands = const [],
    this.min = '',
    this.max = '',
    this.deal = false,
    this.stock = false,
    this.rate = false,
    this.sort = 'pop',
    this.page = 1,
  });

  /// Reads the page's arguments the way the web app reads the URL (`#/shop?dept=beauty&cat=grooming&q=brush ...`),
  /// dropping anything that does not exist.
  factory ShopFilters.fromArgs(Catalogue cat, Map<String, dynamic> a) {
    String s(String k) => (a[k] ?? '').toString().trim();
    final q = s('q');
    var c = s('cat'), d = s('dept');
    if (!cat.catById.containsKey(c)) c = '';
    if (!cat.deptById.containsKey(d)) d = '';
    if (c.isNotEmpty && d.isNotEmpty && cat.catById[c]!.dept != d) d = '';
    var sort = s('sort');
    if (!kSorts.any((x) => x.$1 == sort) || (sort == 'rel' && q.isEmpty)) sort = defaultSort(q);
    return ShopFilters(
      q: q,
      dept: d,
      cat: c,
      brands: s('brand').split(',').where((b) => b.isNotEmpty).toList(),
      min: s('min'),
      max: s('max'),
      deal: s('deal') == '1',
      stock: s('stock') == '1',
      rate: s('rate') == '1',
      sort: sort,
    );
  }

  final String q, dept, cat, min, max, sort;
  final List<String> brands;
  final bool deal, stock, rate;
  final int page;

  /// How many filters are active (the badge on the Filters button).
  int get activeCount =>
      (q.isNotEmpty ? 1 : 0) +
      (dept.isNotEmpty ? 1 : 0) +
      (cat.isNotEmpty ? 1 : 0) +
      brands.length +
      (min.isNotEmpty || max.isNotEmpty ? 1 : 0) +
      (deal ? 1 : 0) +
      (stock ? 1 : 0) +
      (rate ? 1 : 0);

  ShopFilters copyWith({
    String? q,
    String? dept,
    String? cat,
    List<String>? brands,
    String? min,
    String? max,
    bool? deal,
    bool? stock,
    bool? rate,
    String? sort,
    int? page,
  }) {
    final next = ShopFilters(
      q: q ?? this.q,
      dept: dept ?? this.dept,
      cat: cat ?? this.cat,
      brands: brands ?? this.brands,
      min: min ?? this.min,
      max: max ?? this.max,
      deal: deal ?? this.deal,
      stock: stock ?? this.stock,
      rate: rate ?? this.rate,
      sort: sort ?? this.sort,
      page: page ?? this.page,
    );
    // "Best match" only means something while searching
    return next.sort == 'rel' && next.q.isEmpty ? next.copyWith(sort: 'pop') : next;
  }

  /// Back to everything (the "Clear all" button).
  ShopFilters cleared() => const ShopFilters();

  @override
  bool operator ==(Object other) =>
      other is ShopFilters &&
      other.q == q &&
      other.dept == dept &&
      other.cat == cat &&
      listEquals(other.brands, brands) &&
      other.min == min &&
      other.max == max &&
      other.deal == deal &&
      other.stock == stock &&
      other.rate == rate &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(q, dept, cat, Object.hashAll(brands), min, max, deal, stock, rate, sort, page);
}

/// The products matching the filters. [skipCat] / [skipDept] ignore that filter, so the sheet can show how many products
/// each other category or department would give.
List<Product> shopBase(Catalogue cat, ShopFilters f, {bool skipCat = false, bool skipDept = false, String Function(String)? translate}) {
  final list = f.q.isNotEmpty ? searchProducts(cat, f.q, translate: translate) : cat.products;
  final min = double.tryParse(f.min), max = double.tryParse(f.max);
  return [
    for (final p in list)
      if ((skipCat || f.cat.isEmpty || p.cat == f.cat) &&
          (skipDept || f.dept.isEmpty || p.dept == f.dept) &&
          (f.brands.isEmpty || f.brands.contains(p.brand)) &&
          (min == null || p.price >= min) &&
          (max == null || p.price <= max) &&
          (!f.deal || p.off > 0) &&
          (!f.stock || p.stock > 0) &&
          (!f.rate || p.rating >= 4))
        p,
  ];
}

List<Product> shopSorted(List<Product> list, String sort) {
  switch (sort) {
    case 'price-asc':
      return sortedStable(list, (a, b) => a.price.compareTo(b.price));
    case 'price-desc':
      return sortedStable(list, (a, b) => b.price.compareTo(a.price));
    case 'rating':
      return sortedStable(list, (a, b) {
        final r = b.rating.compareTo(a.rating);
        return r != 0 ? r : b.reviews.compareTo(a.reviews);
      });
    case 'off':
      return sortedStable(list, (a, b) => b.off.compareTo(a.off));
    case 'new':
      return sortedStable(list, (a, b) {
        final n = (b.isNew ? 1 : 0) - (a.isNew ? 1 : 0);
        return n != 0 ? n : b.id.compareTo(a.id);
      });
    case 'pop':
      return sortedStable(list, (a, b) => b.pop.compareTo(a.pop));
    default:
      return list; // 'rel' keeps the search ranking
  }
}

/// The page heading: "Results for “milk”", a category, a department, "Deals & offers", a brand or "All products".
String shopTitle(Catalogue cat, ShopFilters f) {
  if (f.q.isNotEmpty) return 'Results for “${f.q}”';
  if (f.cat.isNotEmpty) return cat.catById[f.cat]!.name;
  if (f.dept.isNotEmpty) return cat.deptById[f.dept]!.name;
  if (f.deal) return 'Deals & offers';
  if (f.brands.length == 1) return f.brands.first;
  return 'All products';
}
