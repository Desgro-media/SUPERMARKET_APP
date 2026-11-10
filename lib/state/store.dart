import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalogue.dart';
import '../data/models.dart';

/// The web app keeps everything in localStorage under this key; the app keeps the same JSON in shared preferences.
const String kStoreKey = 'freshnest.v1';

/// Overridden in main() with the opened SharedPreferences.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider must be overridden'));

const Object _keep = Object();

/// Everything the shop remembers: cart, wishlist, orders, account, theme, language ... (js/store.js).
class AppState {
  const AppState({
    this.cart = const {},
    this.wish = const [],
    this.orders = const [],
    this.user,
    this.recent = const [],
    this.searches = const [],
    this.theme = 'light',
    this.lang = 'en',
    this.notesRead = const [],
    this.palette = 'ocean',
    this.reviews = const {},
    this.promo,
    this.area,
    this.addr,
  });

  /// product id -> quantity
  final Map<int, int> cart;
  final List<int> wish;
  final List<Map<String, dynamic>> orders;
  final Map<String, dynamic>? user;
  final List<int> recent;
  final List<String> searches;

  /// 'light' (default), 'dark' or 'auto' (follow the phone).
  final String theme;
  final String lang;
  final List<String> notesRead;
  final String palette;

  /// product id -> reviews written in the app
  final Map<String, List<Map<String, dynamic>>> reviews;
  final String? promo;
  final String? area;
  final Map<String, dynamic>? addr;

  AppState copyWith({
    Map<int, int>? cart,
    List<int>? wish,
    List<Map<String, dynamic>>? orders,
    Object? user = _keep,
    List<int>? recent,
    List<String>? searches,
    String? theme,
    String? lang,
    List<String>? notesRead,
    String? palette,
    Map<String, List<Map<String, dynamic>>>? reviews,
    Object? promo = _keep,
    Object? area = _keep,
    Object? addr = _keep,
  }) =>
      AppState(
        cart: cart ?? this.cart,
        wish: wish ?? this.wish,
        orders: orders ?? this.orders,
        user: identical(user, _keep) ? this.user : user as Map<String, dynamic>?,
        recent: recent ?? this.recent,
        searches: searches ?? this.searches,
        theme: theme ?? this.theme,
        lang: lang ?? this.lang,
        notesRead: notesRead ?? this.notesRead,
        palette: palette ?? this.palette,
        reviews: reviews ?? this.reviews,
        promo: identical(promo, _keep) ? this.promo : promo as String?,
        area: identical(area, _keep) ? this.area : area as String?,
        addr: identical(addr, _keep) ? this.addr : addr as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'cart': {for (final e in cart.entries) '${e.key}': e.value},
        'wish': wish,
        'orders': orders,
        'user': user,
        'recent': recent,
        'searches': searches,
        'theme': theme,
        'themeV': 2,
        'lang': lang,
        'notesRead': notesRead,
        'palette': palette,
        'reviews': reviews,
        'promo': promo,
        'area': area,
        'addr': addr,
      };

  /// Reads the saved state, dropping anything that no longer exists in the catalogue (like store.js load()).
  static AppState load(SharedPreferences prefs, Catalogue cat) {
    Map<String, dynamic> saved = const {};
    try {
      final raw = prefs.getString(kStoreKey);
      if (raw != null) saved = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      saved = const {};
    }
    List<T> list<T>(String key) => saved[key] is List ? List<T>.from(saved[key] as List) : <T>[];

    // Light is the default theme. Older saves held 'auto' (follow the device); those move to light once.
    var theme = (saved['theme'] as String?) ?? 'light';
    if (saved['themeV'] != 2 && theme == 'auto') theme = 'light';

    final cart = <int, int>{};
    if (saved['cart'] is Map) {
      (saved['cart'] as Map).forEach((k, v) {
        final id = int.tryParse('$k');
        if (id != null && v is num && cat.byId.containsKey(id) && v > 0) cart[id] = v.toInt();
      });
    }
    final reviews = <String, List<Map<String, dynamic>>>{};
    if (saved['reviews'] is Map) {
      (saved['reviews'] as Map).forEach((k, v) {
        if (v is List) reviews['$k'] = [for (final r in v) Map<String, dynamic>.from(r as Map)];
      });
    }
    final lang = (saved['lang'] as String?) ?? 'en';
    final palette = (saved['palette'] as String?) ?? 'ocean';
    return AppState(
      cart: cart,
      wish: [for (final id in list<num>('wish')) if (cat.byId.containsKey(id.toInt())) id.toInt()],
      orders: [for (final o in list<Map>('orders')) Map<String, dynamic>.from(o)],
      user: saved['user'] is Map ? Map<String, dynamic>.from(saved['user'] as Map) : null,
      recent: [for (final id in list<num>('recent')) id.toInt()],
      searches: list<String>('searches'),
      theme: theme,
      lang: const ['en', 'bn', 'ar'].contains(lang) ? lang : 'en',
      notesRead: list<String>('notesRead'),
      palette: cat.config.palettes.any((p) => p.id == palette) ? palette : 'ocean',
      reviews: reviews,
      promo: saved['promo'] as String?,
      area: saved['area'] as String?,
      addr: saved['addr'] is Map ? Map<String, dynamic>.from(saved['addr'] as Map) : null,
    );
  }
}

class CartLine {
  const CartLine(this.p, this.qty);

  final Product p;
  final int qty;

  double get total => p.price * qty;
  double get was => (p.was > 0 ? p.was : p.price) * qty;
}

/// The cart's money summary (store.js totals()).
class Totals {
  const Totals({
    required this.items,
    required this.count,
    required this.subtotal,
    required this.savings,
    required this.discount,
    required this.delivery,
    required this.express,
    required this.total,
    required this.promoCode,
    required this.promoNote,
    required this.toFree,
    required this.freeShip,
  });

  final List<CartLine> items;
  final int count;
  final double subtotal, savings, discount, delivery, express, total, toFree;
  final String? promoCode;
  final String promoNote;
  final bool freeShip;
}

Totals computeTotals(AppState s, Catalogue c, {bool express = false}) {
  final cfg = c.config;
  final items = [
    for (final e in s.cart.entries)
      if (c.byId[e.key] != null) CartLine(c.byId[e.key]!, e.value),
  ];
  var subtotal = 0.0, was = 0.0, count = 0;
  for (final l in items) {
    subtotal += l.total;
    was += l.was;
    count += l.qty;
  }
  final code = s.promo;
  final promo = code == null ? null : cfg.promos[code];
  var discount = 0.0, freeShip = false, note = '';
  if (promo != null) {
    switch (promo.type) {
      case 'pct':
        discount = subtotal * promo.value / 100;
      case 'flat':
        if (subtotal >= promo.min) {
          discount = promo.value;
        } else {
          note = 'Add ${cfg.currency} ${(promo.min - subtotal).toStringAsFixed(2)} more to use $code';
        }
      case 'ship':
        freeShip = true;
    }
  }
  var delivery = 0.0;
  if (count > 0) {
    final free = freeShip || subtotal >= cfg.freeDeliveryAt;
    delivery = free ? 0 : cfg.deliveryFee;
  }
  final exp = express && count > 0 ? cfg.expressFee : 0.0;
  final total = subtotal - discount + delivery + exp;
  return Totals(
    items: items,
    count: count,
    subtotal: subtotal,
    savings: was - subtotal,
    discount: discount,
    delivery: delivery,
    express: exp,
    total: total < 0 ? 0 : total,
    promoCode: promo == null ? null : code,
    promoNote: note,
    toFree: (cfg.freeDeliveryAt - subtotal) < 0 ? 0 : cfg.freeDeliveryAt - subtotal,
    freeShip: freeShip,
  );
}

class StoreNotifier extends Notifier<AppState> {
  late final SharedPreferences _prefs = ref.read(prefsProvider);
  late final Catalogue _cat = ref.read(catalogueProvider);

  @override
  AppState build() => AppState.load(_prefs, _cat);

  void _commit(AppState s) {
    state = s;
    _prefs.setString(kStoreKey, jsonEncode(s.toJson()));
  }

  // ---- cart ----
  int maxQty(Product p) {
    final m = p.stock < _cat.config.maxPerItem ? p.stock : _cat.config.maxPerItem;
    return m < 0 ? 0 : m;
  }

  int qty(int id) => state.cart[id] ?? 0;

  int setQty(int id, int q) {
    final p = _cat.byId[id];
    if (p == null) return 0;
    final max = maxQty(p);
    q = q < 0 ? 0 : (q > max ? max : q);
    final cart = Map<int, int>.from(state.cart);
    if (q > 0) {
      cart[id] = q;
    } else {
      cart.remove(id);
    }
    _commit(state.copyWith(cart: cart));
    return q;
  }

  void clearCart() => _commit(state.copyWith(cart: const {}, promo: null));

  void restoreCart(Map<int, int> cart, String? promo) => _commit(state.copyWith(cart: cart, promo: promo));

  ({Map<int, int> cart, String? promo}) snapshot() => (cart: Map<int, int>.from(state.cart), promo: state.promo);

  // ---- wishlist ----
  bool isWished(int id) => state.wish.contains(id);

  /// Returns true when the product was added, false when it was removed.
  bool toggleWish(int id) {
    final i = state.wish.indexOf(id);
    final list = [...state.wish];
    if (i > -1) {
      list.removeAt(i);
    } else {
      list.insert(0, id);
    }
    _commit(state.copyWith(wish: list));
    return i == -1;
  }

  // ---- promo codes ----
  ({bool ok, String msg}) applyPromo(String raw) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return (ok: false, msg: 'Enter a promo code');
    final promo = _cat.config.promos[code];
    if (promo == null) return (ok: false, msg: 'That code is not valid');
    _commit(state.copyWith(promo: code));
    return (ok: true, msg: '${promo.label} applied');
  }

  void removePromo() => _commit(state.copyWith(promo: null));

  // ---- history ----
  void pushRecent(int id) =>
      _commit(state.copyWith(recent: [id, ...state.recent.where((x) => x != id)].take(12).toList()));

  void pushSearch(String q) {
    q = q.trim();
    if (q.isEmpty) return;
    _commit(state.copyWith(
      searches: [q, ...state.searches.where((x) => x.toLowerCase() != q.toLowerCase())].take(6).toList(),
    ));
  }

  void clearSearches() => _commit(state.copyWith(searches: const []));

  // ---- preferences / account ----
  void setTheme(String t) => _commit(state.copyWith(theme: t));
  void setLang(String l) => _commit(state.copyWith(lang: l));
  void setPalette(String p) => _commit(state.copyWith(palette: p));
  void setArea(String a) => _commit(state.copyWith(area: a));
  void setUser(Map<String, dynamic>? u) => _commit(state.copyWith(user: u));
  void saveAddress(Map<String, dynamic>? a) => _commit(state.copyWith(addr: a));
  void readNotes(List<String> ids) => _commit(state.copyWith(notesRead: [...ids]));

  // ---- orders and reviews ----

  /// Places the order for everything in the cart, empties the cart and returns the saved order (store.js placeOrder).
  Map<String, dynamic> placeOrder({
    required bool express,
    required Map<String, dynamic> customer,
    required Map<String, dynamic> address,
    required String slot,
    required String payment,
    String notes = '',
  }) {
    final t = computeTotals(state, _cat, express: express);
    final now = DateTime.now().millisecondsSinceEpoch;
    final code = now.toRadixString(36).toUpperCase();
    final order = <String, dynamic>{
      'id': 'FN-${code.length > 6 ? code.substring(code.length - 6) : code}',
      'ts': now,
      'items': [
        for (final l in t.items) {'id': l.p.id, 'name': l.p.name, 'emoji': l.p.emoji, 'unit': l.p.unit, 'price': l.p.price, 'qty': l.qty},
      ],
      'totals': {
        'subtotal': t.subtotal,
        'discount': t.discount,
        'delivery': t.delivery,
        'express': t.express,
        'total': t.total,
        'promo': t.promoCode,
      },
      'customer': customer,
      'address': address,
      'slot': slot,
      'payment': payment,
      'notes': notes,
    };
    _commit(state.copyWith(orders: [order, ...state.orders], cart: const {}, promo: null));
    return order;
  }

  Map<String, dynamic>? order(String id) {
    for (final o in state.orders) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  void addReview(int productId, Map<String, dynamic> review) {
    final reviews = {...state.reviews};
    reviews['$productId'] = [review, ...(reviews['$productId'] ?? const [])];
    _commit(state.copyWith(reviews: reviews));
  }
}

final storeProvider = NotifierProvider<StoreNotifier, AppState>(StoreNotifier.new);

/// Cart totals (without express delivery); watch a field with `.select` to rebuild only when it changes.
final totalsProvider = Provider<Totals>((ref) => computeTotals(ref.watch(storeProvider), ref.watch(catalogueProvider)));

/// Bumped each time something is added to the cart, so the cart icon can play its little "bump" animation.
class BumpNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final cartBumpProvider = NotifierProvider<BumpNotifier, int>(BumpNotifier.new);
