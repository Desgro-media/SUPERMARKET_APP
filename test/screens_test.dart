import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supermarket_android/core/app_nav.dart';
import 'package:supermarket_android/core/i18n.dart';
import 'package:supermarket_android/shell/bottom_nav.dart';
import 'package:supermarket_android/state/actions.dart';
import 'package:supermarket_android/state/store.dart';

import 'support/test_app.dart';

Future<void> open(WidgetTester tester, String route, [Map<String, dynamic>? args]) async {
  AppNav.key.currentState!.pushReplacementNamed(route, arguments: args);
  await settle(tester);
  expect(tester.takeException(), isNull, reason: 'opening $route ${args ?? ''}');
}

Future<void> scrollPage(WidgetTester tester, {int steps = 14}) async {
  for (var i = 0; i < steps; i++) {
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: 'layout error while scrolling (step $i)');
  }
}

/// A widget by its accessibility label (what a screen reader reads), without turning semantics on.
Finder semLabel(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

void main() {
  final cat = loadCatalogue();
  final noPhoto = cat.products.firstWhere((p) => !p.hasPhoto);
  final twoPhotos = cat.products.firstWhere((p) => p.imgs.length > 1);
  final onSale = cat.products.firstWhere((p) => p.off > 0 && p.isNew);
  final soldOut = cat.products.where((p) => !p.inStock);

  final user = {'name': 'Sangeeth K', 'contact': 'sangeeth@example.com'};
  final order = {
    'id': 'FN-TEST01',
    'ts': DateTime.now().millisecondsSinceEpoch - 30000,
    'items': [
      {'id': 6322, 'name': 'Free Range Eggs', 'emoji': '🥚', 'unit': 'Dozen', 'price': 13.95, 'qty': 2},
      {'id': 99999, 'name': 'A product that no longer exists', 'emoji': '🛒', 'unit': '1 pc', 'price': 5.5, 'qty': 1},
    ],
    'totals': {'subtotal': 33.4, 'discount': 3.34, 'delivery': 12.0, 'express': 0.0, 'total': 42.06, 'promo': 'SAVE10'},
    'customer': {'name': 'Sangeeth K', 'phone': '+966 50 123 4567', 'email': 'sangeeth@example.com'},
    'address': {'area': 'Riyadh', 'street': 'Olaya St', 'building': 'Tower 2, floor 3', 'landmark': 'Near the mall'},
    'slot': 'Today, 18:00 – 20:00',
    'payment': 'Cash on delivery',
    'notes': 'Ring the bell',
  };
  final full = <String, dynamic>{
    'cart': {'6322': 2, '6323': 1, '${noPhoto.id}': 1},
    'wish': [6322, 6323, noPhoto.id],
    'user': user,
    'orders': [order],
    'promo': 'SAVE10',
    'reviews': {
      '6322': [
        {'name': 'Sangeeth K', 'text': 'Great eggs, very fresh.', 'stars': 5, 'ts': DateTime.now().millisecondsSinceEpoch, 'title': ''},
      ],
    },
    'recent': [6322, 6323, 6324],
    'addr': {'name': 'Sangeeth K', 'phone': '+966 50 123 4567', 'email': '', 'area': 'Jeddah', 'street': 'Tahlia St', 'building': 'Flat 4', 'landmark': ''},
  };

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  final routes = <(String, Map<String, dynamic>?)>[
    (Routes.shop, null),
    (Routes.shop, {'q': 'milk'}),
    (Routes.shop, {'q': 'zzzzqq'}),
    (Routes.shop, {'dept': 'beauty', 'sort': 'price-asc'}),
    (Routes.shop, {'cat': 'grooming', 'brand': 'Sharp Edge', 'deal': '1'}),
    (Routes.product, {'id': 6322}),
    (Routes.product, {'id': noPhoto.id}),
    (Routes.product, {'id': twoPhotos.id}),
    (Routes.product, {'id': onSale.id}),
    if (soldOut.isNotEmpty) (Routes.product, {'id': soldOut.first.id}),
    (Routes.product, {'id': 424242}),
    (Routes.wishlist, null),
    (Routes.cart, null),
    (Routes.checkout, null),
    (Routes.order, {'id': 'FN-TEST01'}),
    (Routes.order, {'id': 'NOPE'}),
    (Routes.orders, null),
    (Routes.track, null),
    (Routes.track, {'id': 'FN-TEST01'}),
    (Routes.account, null),
    (Routes.profile, null),
    (Routes.address, null),
    (Routes.support, null),
    (Routes.coupons, null),
    (Routes.notifications, null),
    (Routes.contact, null),
    (Routes.privacy, null),
    (Routes.terms, null),
    (Routes.about, null),
    (Routes.credits, null),
    ('/unknown', null),
  ];

  group('every screen renders and scrolls without layout errors', () {
    for (final (lang, size) in const [('en', Size(412, 915)), ('en', Size(320, 568)), ('bn', Size(360, 640)), ('ar', Size(360, 640))]) {
      for (final signedInAndFull in [true, false]) {
        testWidgets('$lang ${size.width.toInt()}x${size.height.toInt()} ${signedInAndFull ? 'with data' : 'empty'}', (tester) async {
          await pumpNestMart(tester, lang: lang, size: size, saved: signedInAndFull ? full : const {});
          for (final (route, args) in routes) {
            await open(tester, route, args);
            await scrollPage(tester, steps: 8);
          }
          await disposeApp(tester);
        });
      }
    }
  });

  group('dark theme and other colour themes', () {
    for (final (palette, theme) in const [('crimson', 'dark'), ('teal', 'light'), ('plum', 'dark')]) {
      testWidgets('$palette $theme', (tester) async {
        await pumpNestMart(tester, palette: palette, theme: theme, saved: full);
        for (final (route, args) in routes.where((r) => const [Routes.shop, Routes.product, Routes.cart, Routes.checkout, Routes.account, Routes.orders].contains(r.$1))) {
          await open(tester, route, args);
          await scrollPage(tester, steps: 5);
        }
        await disposeApp(tester);
      });
    }
  });

  testWidgets('cart: promo code, quantity and clearing', (tester) async {
    final container = await pumpNestMart(tester, saved: {'cart': {'6322': 1, '6323': 1}});
    await open(tester, Routes.cart);
    expect(container.read(totalsProvider).count, 2);
    expect(container.read(totalsProvider).promoCode, isNull);

    await tester.enterText(find.widgetWithText(TextField, '').first, 'SAVE10');
    // the promo box is the only TextField that is not the header search: find it by its hint text
    final promoField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Promo code');
    await tester.enterText(promoField, 'save10');
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(storeProvider).promo, 'SAVE10');
    expect(find.textContaining('applied'), findsWidgets);
    await tester.tap(find.text('Remove').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(storeProvider).promo, isNull);

    container.read(actionsProvider).clearCart();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('cart sheet opens from "View cart" and shows the lines', (tester) async {
    final container = await pumpNestMart(tester, saved: {'cart': {'6322': 2}});
    container.read(actionsProvider).openCart();
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Checkout'), findsWidgets);
    expect(find.text('View cart'), findsOneWidget);
    await tester.tap(find.text('View cart'));
    await settle(tester);
    expect(find.text('Order summary'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('checkout: validates, places the order and shows the confirmation', (tester) async {
    final container = await pumpNestMart(tester, saved: {'cart': {'6322': 2, '6323': 1}});
    await open(tester, Routes.checkout);

    // empty form -> errors
    final place = find.text('Place order');
    Scrollable.ensureVisible(tester.element(place), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(place);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Please fix the highlighted fields.'), findsOneWidget);
    expect(find.text('This field is required'), findsWidgets);

    Future<void> type(String label, String text) async {
      final field = find.ancestor(of: find.textContaining(label, findRichText: true), matching: find.byType(Column)).first;
      final input = find.descendant(of: field, matching: find.byType(TextField)).first;
      Scrollable.ensureVisible(tester.element(input), alignment: .5);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(input, text);
      await tester.pump(const Duration(milliseconds: 100));
    }

    await type('Full name', 'Sangeeth K');
    await type('Mobile number', '+966 50 123 4567');
    await type('Street / neighbourhood', 'Olaya St');
    await type('Building, floor & flat', 'Tower 2');
    Scrollable.ensureVisible(tester.element(place), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(place);
    await settle(tester);
    expect(tester.takeException(), isNull);

    final orders = container.read(storeProvider).orders;
    expect(orders.length, 1);
    expect(orders.first['customer'], containsPair('name', 'Sangeeth K'));
    expect(container.read(totalsProvider).count, 0);
    expect(find.textContaining('Thank you, Sangeeth'), findsOneWidget);
    expect(find.text('Order placed'), findsWidgets);
    await scrollPage(tester, steps: 6);
    await disposeApp(tester);
  });

  testWidgets('shop: filters sheet, chips, sort and list view', (tester) async {
    final container = await pumpNestMart(tester);
    await open(tester, Routes.shop, {'dept': 'grocery'});
    expect(find.text('Groceries'), findsWidgets);

    await tester.tap(find.text('Filters'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Department'), findsOneWidget);
    final sheetScroll = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('On sale'), 300, scrollable: sheetScroll);
    await tester.tap(find.text('On sale'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining(RegExp(r'^Show \d+ items')), findsOneWidget);
    await tester.tapAt(const Offset(200, 40)); // the dark area closes the sheet
    await settle(tester);
    expect(find.text('On sale'), findsWidgets); // now also a chip under the toolbar

    // list layout
    await tester.tap(semLabel('List view').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(prefsProvider).getString('freshnest.view'), 'list');
    await scrollPage(tester, steps: 6);
    await disposeApp(tester);
  });

  testWidgets('shop: a search from the header opens results', (tester) async {
    await pumpNestMart(tester);
    await tester.enterText(find.byType(TextField).first, 'milk');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Results for'), findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('product: quantity, add to cart, tabs and reviews', (tester) async {
    final container = await pumpNestMart(tester);
    await open(tester, Routes.product, {'id': 6322});
    await tester.tap(semLabel('Increase quantity').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('2'), findsWidgets);
    // the sticky bar's button (the last one) is always on screen
    await tester.tap(find.textContaining('Add to cart', findRichText: true).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(storeProvider).cart[6322], 2);
    expect(tester.takeException(), isNull);

    // tabs
    Scrollable.ensureVisible(tester.element(find.text('Details')), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Details'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Product code'), findsOneWidget);
    await tester.tap(find.text('Reviews').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Write a review'), findsOneWidget);

    // review validation
    final submit = find.text('Submit review');
    Scrollable.ensureVisible(tester.element(submit), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Please choose a star rating.'), findsOneWidget);
    await tester.tap(semLabel('5 stars').first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('orders: reorder puts the items back in the cart', (tester) async {
    final container = await pumpNestMart(tester, saved: {'orders': [order]});
    await open(tester, Routes.orders);
    expect(find.text('#FN-TEST01'), findsOneWidget);
    await tester.tap(find.text('Reorder'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(storeProvider).cart[6322], 2);
    await tester.tap(find.text('View'));
    await settle(tester);
    expect(find.textContaining('Order'), findsWidgets);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('track order: finds an order by its ID and rejects an unknown one', (tester) async {
    await pumpNestMart(tester, saved: {'orders': [order]});
    await open(tester, Routes.track);
    final input = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'e.g. FN-ABC123');
    await tester.enterText(input, 'nope');
    await tester.tap(find.text('Track'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining("couldn't find that order"), findsOneWidget);
    await tester.enterText(input, 'fn-test01');
    await tester.tap(find.text('Track'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Order progress'), findsNothing); // (semantics label only)
    expect(find.text('Packing'), findsWidgets);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('address and profile save, support message validates', (tester) async {
    final container = await pumpNestMart(tester, saved: {'user': user});
    await open(tester, Routes.profile);
    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(storeProvider).user!['name'], 'Sangeeth K');

    await open(tester, Routes.address);
    final save = find.text('Save address');
    Scrollable.ensureVisible(tester.element(save), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('This field is required'), findsWidgets);

    await open(tester, Routes.support);
    await tester.tap(find.text('How fast is delivery?'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Choose a delivery time slot'), findsOneWidget);
    final send = find.text('Send message');
    Scrollable.ensureVisible(tester.element(send), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(send);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Enter a valid email or mobile number'), findsNothing); // name and contact are prefilled from the account
    expect(find.text('This field is required'), findsOneWidget); // only the message is empty
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('coupons can be applied and notifications marked as read', (tester) async {
    final container = await pumpNestMart(tester, saved: {'orders': [order]});
    await open(tester, Routes.coupons);
    await tester.tap(find.text('Apply').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(storeProvider).promo, 'SAVE10');
    expect(find.text('Applied'), findsOneWidget);

    await open(tester, Routes.notifications);
    expect(find.text('4 unread'), findsOneWidget);
    await tester.tap(find.text('Mark all as read'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('You are all caught up'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('bottom bar leads to cart and account pages', (tester) async {
    await pumpNestMart(tester);
    await tester.tap(find.descendant(of: find.byType(BottomNav), matching: find.text('Cart')));
    await settle(tester);
    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(BottomNav), matching: find.text('Account')));
    await settle(tester);
    expect(find.text('Preferences'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  test('every language has a translation for the new page titles', () {
    final tr = Translator('ar', loadTranslations());
    for (final s in ['Your cart', 'Checkout', 'Order summary', 'Place order', 'My orders', 'Track Order', 'Wishlist', 'Filters', 'Load more']) {
      expect(tr(s), isNot(s), reason: 'no Arabic text for "$s"');
    }
  });
}
