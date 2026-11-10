/// A stable sort (equal items keep their catalogue order), like JavaScript's Array.sort. Dart's List.sort is not stable,
/// and the web app's lists (deals, popular ...) rely on ties staying in catalogue order.
List<T> sortedStable<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [for (final (i, v) in items.indexed) (i, v)];
  indexed.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}
