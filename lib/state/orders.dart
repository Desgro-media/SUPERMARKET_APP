/// The four steps an order goes through, with the one-line description under each (STAGES in the web app).
const List<(String, String)> kOrderStages = [
  ('Order placed', "We've got your order"),
  ('Packing', 'Our team is picking your items'),
  ('On the way', 'Your driver is heading to you'),
  ('Delivered', 'Enjoy your groceries!'),
];

/// Where an order is right now. The demo store has no courier, so the tracker simply advances with time:
/// placed -> packing after 12s -> on the way after 40s -> delivered after 90s.
int orderStage(Map<String, dynamic> order, {DateTime? now}) {
  final seconds = ((now ?? DateTime.now()).millisecondsSinceEpoch - (order['ts'] as num).toInt()) / 1000;
  return seconds < 12 ? 0 : (seconds < 40 ? 1 : (seconds < 90 ? 2 : 3));
}

int orderItemCount(Map<String, dynamic> order) => [for (final i in order['items'] as List) (i as Map)['qty'] as int].fold(0, (a, b) => a + b);

const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];

/// "just now", "5 min ago", "3 h ago", otherwise a date like "5 Nov 2026" (UI.ago in the web app).
String agoText(int timestamp, {DateTime? now}) {
  final d = ((now ?? DateTime.now()).millisecondsSinceEpoch - timestamp) / 1000;
  if (d < 60) return 'just now';
  if (d < 3600) return '${(d / 60).floor()} min ago';
  if (d < 86400) return '${(d / 3600).floor()} h ago';
  final t = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${t.day} ${_months[t.month - 1]} ${t.year}';
}
