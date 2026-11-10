import '../data/models.dart';

/// The reviews every product shows besides the ones a customer writes. The web app makes them up from the product id with a
/// small seeded random generator (so a product always shows the same five reviews); this is the same generator and text.
class SampleReview {
  const SampleReview({required this.name, required this.stars, required this.title, required this.text, required this.ts});

  final String name, title, text;
  final int stars, ts;
}

const List<String> _names = ['Aisha K.', 'Omar S.', 'Priya N.', 'Daniel R.', 'Fatima A.', 'Lucas M.', 'Noor H.', 'Sanjay P.', 'Layla B.', 'Chris T.'];
const List<(String, String)> _good = [
  ('Great quality', 'Arrived well packed and exactly as described.'),
  ('Will order again', 'Good value for the price and the delivery was right on time.'),
  ('Family favourite', "Everyone at home loved it. It's now a regular on our weekly list."),
  ('Better than the shop', 'Better quality than what I usually find in store. Very happy.'),
  ('Perfect', 'Just as described. Packaging was neat and nothing was damaged.'),
];
const List<(String, String)> _ok = [
  ('Decent', "Good overall, though I'd like a slightly bigger pack size."),
  ('Fine', 'Does the job. Delivery was a little later than expected.'),
];

int _imul(int a, int b) => (a.toSigned(32) * b.toSigned(32)).toSigned(32);
int _u32(int x) => x & 0xFFFFFFFF;

/// JavaScript's mulberry32 generator, bit for bit (int32 arithmetic).
double Function() seededRandom(int seed) {
  var s = seed.toSigned(32);
  return () {
    s = (s + 0x6D2B79F5).toSigned(32);
    var t = _imul((s ^ (_u32(s) >> 15)).toSigned(32), 1 | s);
    t = ((t + _imul((t ^ (_u32(t) >> 7)).toSigned(32), 61 | t)).toSigned(32) ^ t).toSigned(32);
    return _u32((t ^ (_u32(t) >> 14)).toSigned(32)) / 4294967296;
  };
}

List<SampleReview> sampleReviews(Product p, {DateTime? now}) {
  final r = seededRandom(p.id);
  final base = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final out = <SampleReview>[];
  for (var i = 0; i < 5; i++) {
    final good = r() < (p.rating - 3) / 2.1;
    final pick = good ? _good[(r() * _good.length).floor()] : _ok[(r() * _ok.length).floor()];
    final name = _names[(r() * _names.length).floor()];
    final stars = good ? (r() < 0.55 ? 5 : 4) : 3;
    final days = (r() * 60 + 2).floor();
    out.add(SampleReview(name: name, stars: stars, title: pick.$1, text: pick.$2, ts: base - days * 86400000));
  }
  return out;
}

/// The share of 5, 4, 3, 2 and 1 star ratings shown in the reviews tab, by the product's average rating.
List<int> ratingBars(double rating) {
  if (rating >= 4.8) return const [78, 17, 3, 1, 1];
  if (rating >= 4.6) return const [68, 24, 5, 2, 1];
  if (rating >= 4.4) return const [58, 30, 8, 3, 1];
  if (rating >= 4.2) return const [48, 32, 13, 5, 2];
  return const [38, 32, 18, 8, 4];
}
