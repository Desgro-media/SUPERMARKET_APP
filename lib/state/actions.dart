import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_nav.dart';
import '../data/catalogue.dart';
import '../screens/cart/cart_sheet.dart';
import 'store.dart';
import 'toasts.dart';

/// The shop's user actions (add to cart, wishlist ...) together with the toast messages the web app shows for them (app.js).
class ShopActions {
  ShopActions(this._ref);

  final Ref _ref;

  StoreNotifier get _store => _ref.read(storeProvider.notifier);
  ToastNotifier get _toast => _ref.read(toastProvider.notifier);
  Catalogue get _cat => _ref.read(catalogueProvider);

  void toast(String message, {String? action, void Function()? onAction}) =>
      _toast.show(message, action: action, onAction: onAction);

  /// "View cart": the cart slides up over the page (the web app's cart drawer).
  void openCart() {
    final context = AppNav.key.currentContext;
    if (context != null) showCartSheet(context);
  }

  void cartAdd(int id, {bool quiet = false}) {
    final p = _cat.byId[id];
    if (p == null || !p.inStock) return;
    final q = _store.qty(id), max = _store.maxQty(p);
    if (q >= max) {
      _toast.show('Maximum $max per order for ${p.name}');
      return;
    }
    _store.setQty(id, q + 1);
    _ref.read(cartBumpProvider.notifier).bump();
    if (q == 0 && !quiet) _toast.show('${p.name} added to cart', action: 'View cart', onAction: openCart);
  }

  void cartDec(int id) {
    final p = _cat.byId[id];
    final q = _store.qty(id);
    if (p == null || q == 0) return;
    _store.setQty(id, q - 1);
    if (q == 1) _toast.show('Removed ${p.name}', action: 'Undo', onAction: () => _store.setQty(id, 1));
  }

  void cartRemove(int id) {
    final p = _cat.byId[id];
    final q = _store.qty(id);
    if (p == null || q == 0) return;
    _store.setQty(id, 0);
    _toast.show('Removed ${p.name}', action: 'Undo', onAction: () => _store.setQty(id, q));
  }

  void clearCart() {
    final snap = _store.snapshot();
    _store.clearCart();
    _toast.show('Cart cleared', action: 'Undo', onAction: () => _store.restoreCart(snap.cart, snap.promo));
  }

  void toggleWish(int id) {
    final p = _cat.byId[id];
    if (p == null) return;
    final on = _store.toggleWish(id);
    if (on) {
      _toast.show('Saved ${p.name} to wishlist', action: 'View', onAction: () => AppNav.go(Routes.wishlist));
    } else {
      _toast.show('Removed from wishlist', action: 'Undo', onAction: () => _store.toggleWish(id));
    }
  }

  void wishAll() {
    var n = 0;
    for (final id in _ref.read(storeProvider).wish) {
      final p = _cat.byId[id];
      if (p != null && p.inStock && _store.qty(id) == 0) {
        _store.setQty(id, 1);
        n++;
      }
    }
    if (n > 0) {
      _ref.read(cartBumpProvider.notifier).bump();
      _toast.show('$n item${n == 1 ? '' : 's'} added to cart', action: 'View cart', onAction: openCart);
    } else {
      _toast.show('Nothing new to add');
    }
  }
}

final actionsProvider = Provider<ShopActions>((ref) => ShopActions(ref));
