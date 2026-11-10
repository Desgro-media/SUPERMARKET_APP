import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_android/core/i18n.dart';
import 'package:supermarket_android/shell/bottom_nav.dart';
import 'package:supermarket_android/shell/sheets.dart';
import 'package:supermarket_android/state/store.dart';
import 'package:supermarket_android/widgets/product_card.dart';

import 'support/test_app.dart';

/// Scrolls the current page from top to bottom in small steps, failing on the first layout error (overflow, bad margin ...).
Future<void> scrollThrough(WidgetTester tester, {int steps = 16}) async {
  for (var i = 0; i < steps; i++) {
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -650));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull, reason: 'a layout error appeared after scrolling step $i');
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  group('home page renders without errors', () {
    const combos = [
      ('en', 'ocean', 'light', Size(412, 915)),
      ('en', 'ocean', 'dark', Size(412, 915)),
      ('en', 'crimson', 'light', Size(360, 640)),
      ('en', 'sunset', 'dark', Size(320, 568)),
      ('bn', 'plum', 'light', Size(412, 915)),
      ('bn', 'teal', 'dark', Size(360, 640)),
      ('ar', 'ocean', 'light', Size(412, 915)),
      ('ar', 'crimson', 'dark', Size(360, 640)),
      ('en', 'teal', 'light', Size(600, 960)),
    ];
    for (final c in combos) {
      testWidgets('${c.$1} / ${c.$2} / ${c.$3} / ${c.$4.width.toInt()}x${c.$4.height.toInt()}', (tester) async {
        await pumpNestMart(tester, lang: c.$1, palette: c.$2, theme: c.$3, size: c.$4);
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
        await disposeApp(tester);
      });
    }
  });

  testWidgets('every hero slide fits its text (swipe through all four)', (tester) async {
    for (final lang in ['en', 'bn', 'ar']) {
      await pumpNestMart(tester, lang: lang, size: const Size(360, 640));
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull, reason: 'hero slide ${i + 1} overflowed in $lang');
      }
      await disposeApp(tester);
    }
  });

  testWidgets('department chips are present under the header', (tester) async {
    await pumpNestMart(tester);
    expect(find.text('\u{1F525} Deals'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('adding a product updates the cart, and the stepper appears', (tester) async {
    final container = await pumpNestMart(tester);
    expect(container.read(totalsProvider).count, 0);
    // bring the first product's round "+" button to the middle of the screen, then tap it
    final plus = find.byType(QtyControl).first;
    Scrollable.ensureVisible(tester.element(plus), alignment: .5);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(plus);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(totalsProvider).count, 1);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('switching language, palette and theme at run time keeps the page intact', (tester) async {
    final container = await pumpNestMart(tester);
    final store = container.read(storeProvider.notifier);

    store.setLang('ar');
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(shownTexts(tester), contains(Translator(container.read(storeProvider).lang, loadTranslations())('Shop by category')));
    expect(Directionality.of(tester.element(find.byType(CustomScrollView).first)), TextDirection.rtl);

    store.setLang('bn');
    store.setPalette('plum');
    store.setTheme('dark');
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(Directionality.of(tester.element(find.byType(CustomScrollView).first)), TextDirection.ltr);

    store.setLang('en');
    store.setTheme('light');
    store.setPalette('ocean');
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('account page: sign in, colour themes, language and appearance', (tester) async {
    for (final lang in ['en', 'ar']) {
      final container = await pumpNestMart(tester, lang: lang);
      final tr = Translator(lang, loadTranslations());
      await tester.tap(find.descendant(of: find.byType(BottomNav), matching: find.text(tr('Account'))));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'account page ($lang)');
      expect(container.read(storeProvider).palette, 'ocean');

      // colour themes: tap the "Crimson red" dot
      final crimson = find.byTooltip(tr('Crimson red'));
      Scrollable.ensureVisible(tester.element(crimson), alignment: .5);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(crimson);
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(storeProvider).palette, 'crimson', reason: 'colour theme ($lang)');
      expect(tester.takeException(), isNull);

      // appearance: Dark
      await tester.tap(find.text(tr('Dark')).last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(storeProvider).theme, 'dark');
      expect(tester.takeException(), isNull);

      // language: the Bengali button
      await tester.tap(find.text('বাংলা').last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(container.read(storeProvider).lang, 'bn');
      expect(tester.takeException(), isNull);
      await scrollThrough(tester, steps: 4);
      await disposeApp(tester);
    }
  });

  testWidgets('sign in sheet validates and signs in', (tester) async {
    final container = await pumpNestMart(tester);
    await tester.tap(find.descendant(of: find.byType(BottomNav), matching: find.text('Account')));
    await settle(tester);
    await tester.tap(find.text('Login'));
    await settle(tester);
    expect(find.text('Welcome to NestMart'), findsOneWidget);
    // empty form: both errors
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Please tell us your name'), findsOneWidget);
    expect(find.text('Enter a valid email or mobile number'), findsOneWidget);
    // valid form
    final fields = find.descendant(of: find.byType(SheetFrame), matching: find.byType(TextField));
    await tester.enterText(fields.first, 'Sangeeth K');
    await tester.enterText(fields.last, 'sangeeth@example.com');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(container.read(storeProvider).user, {'name': 'Sangeeth K', 'contact': 'sangeeth@example.com'});
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('city and category sheets open from the header and the bottom bar', (tester) async {
    final container = await pumpNestMart(tester);
    // category sheet
    await tester.tap(find.descendant(of: find.byType(BottomNav), matching: find.text('Categories')));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'category sheet');
    expect(find.text('Shop by category'), findsWidgets);
    await tester.tapAt(const Offset(200, 40)); // the dark area above the sheet closes it
    await settle(tester);
    // city sheet
    await tester.tap(find.text('Riyadh').first);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'city sheet');
    expect(find.text('Where should we deliver?'), findsOneWidget);
    await tester.tap(find.text('Jeddah'));
    await settle(tester);
    expect(container.read(storeProvider).area, 'Jeddah');
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });
}