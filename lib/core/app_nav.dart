import 'package:material_ui/material_ui.dart';

/// Routes of the app. They mirror the web app's hash routes (`#/shop`, `#/product/<id>`, `#/cart` ...).
abstract final class Routes {
  static const home = '/';
  static const shop = '/shop';
  static const product = '/product';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const order = '/order';
  static const orders = '/orders';
  static const wishlist = '/wishlist';
  static const account = '/account';
  static const track = '/track';
  static const profile = '/profile';
  static const address = '/address';
  static const support = '/support';
  static const coupons = '/coupons';
  static const notifications = '/notifications';
  static const contact = '/contact';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const about = '/about';
  static const credits = '/credits';
}

/// Navigation inside the app shell. The header and bottom bar stay put and only the page below them changes,
/// just like the web app swaps its <main> element.
abstract final class AppNav {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get _nav => key.currentState;

  static bool get canPop => _nav?.canPop() ?? false;

  /// Opens [route]; [args] are its parameters (for example {'dept': 'beauty'} for the shop).
  static void go(String route, [Map<String, dynamic>? args]) => _nav?.pushNamed(route, arguments: args);

  /// Opens [route] in place of the current page (so Back does not return to it).
  static void replace(String route, [Map<String, dynamic>? args]) => _nav?.pushReplacementNamed(route, arguments: args);

  static void goHome() => _nav?.popUntil((r) => r.isFirst);

  static void back() => _nav?.maybePop();
}
