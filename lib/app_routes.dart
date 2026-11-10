import 'package:material_ui/material_ui.dart';

import 'core/app_nav.dart';
import 'screens/account/account_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/cart/checkout_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/info/info_screens.dart';
import 'screens/not_found_screen.dart';
import 'screens/orders/order_screens.dart';
import 'screens/shop/product_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/wishlist_screen.dart';

/// A page that fades in over the previous one (`.view { animation: view-in .3s }` in the web app).
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute({required super.settings, required WidgetBuilder builder})
      : super(
          pageBuilder: (context, _, _) => builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.ease), child: child),
        );
}

/// Which screen each route opens (the web app's hash router).
abstract final class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    final args = (settings.arguments as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final id = args['id'];

    final Widget page = switch (settings.name) {
      Routes.home => const HomeScreen(),
      Routes.shop => ShopScreen(args: args),
      Routes.product => id is int ? ProductScreen(productId: id) : (int.tryParse('$id') == null ? const NotFoundScreen() : ProductScreen(productId: int.parse('$id'))),
      Routes.wishlist => const WishlistScreen(),
      Routes.cart => const CartScreen(),
      Routes.checkout => const CheckoutScreen(),
      Routes.order => OrderScreen(orderId: '$id'),
      Routes.orders => const OrdersScreen(),
      Routes.track => TrackScreen(orderId: id == null ? null : '$id'),
      Routes.account => const AccountScreen(),
      Routes.profile => const ProfileScreen(),
      Routes.address => const AddressScreen(),
      Routes.support => const SupportScreen(),
      Routes.coupons => const CouponsScreen(),
      Routes.notifications => const NotificationsScreen(),
      Routes.contact => const ContactScreen(),
      Routes.privacy => const PrivacyScreen(),
      Routes.terms => const TermsScreen(),
      Routes.about => const AboutScreen(),
      Routes.credits => const CreditsScreen(),
      _ => const NotFoundScreen(),
    };
    return FadeRoute<void>(settings: settings, builder: (_) => page);
  }
}
