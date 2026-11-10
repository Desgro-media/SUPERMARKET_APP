import 'catalogue.dart';
import 'models.dart';

final RegExp _splitter = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

List<String> _tokens(String q) => q
    .toLowerCase()
    .split(_splitter)
    .where((t) => t.isNotEmpty)
    .map((t) => t.length > 3 ? t.replaceFirst(RegExp(r's$'), '') : t)
    .toList();

int _score(Catalogue c, Product p, List<String> toks, String Function(String)? tr) {
  var name = p.name.toLowerCase();
  var brand = p.brand.toLowerCase();
  var cat = c.catById[p.cat]!.name.toLowerCase();
  final blurb = p.blurb.toLowerCase();
  // in Bengali / Arabic the translated name, brand and category are searched as well
  if (tr != null) {
    name += ' ${tr(p.name).toLowerCase()}';
    brand += ' ${tr(p.brand).toLowerCase()}';
    cat += ' ${tr(c.catById[p.cat]!.name).toLowerCase()}';
  }
  final words = name.split(RegExp(r'\s+'));
  var total = 0;
  for (final t in toks) {
    var s = 0;
    if (words.any((w) => w.startsWith(t))) {
      s = 6;
    } else if (name.contains(t)) {
      s = 4;
    } else if (brand.contains(t)) {
      s = 3;
    } else if (cat.contains(t)) {
      s = 2;
    } else if (blurb.contains(t)) {
      s = 1;
    }
    if (s == 0) return 0;
    total += s;
  }
  return total;
}

/// The web app's product search (shared by the header suggestions and the shop page): every word must match
/// the name, brand, category or description; best matches first, ties broken by popularity.
List<Product> searchProducts(Catalogue c, String q, {int? limit, String Function(String)? translate}) {
  final toks = _tokens(q);
  if (toks.isEmpty) return const [];
  final scored = <(Product, int)>[];
  for (final p in c.products) {
    final s = _score(c, p, toks, translate);
    if (s > 0) scored.add((p, s));
  }
  scored.sort((a, b) {
    final bySore = b.$2.compareTo(a.$2);
    return bySore != 0 ? bySore : b.$1.pop.compareTo(a.$1.pop);
  });
  final out = [for (final e in scored) e.$1];
  return limit == null || out.length <= limit ? out : out.sublist(0, limit);
}
