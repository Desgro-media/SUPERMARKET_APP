import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supermarket_android/app.dart';
import 'package:supermarket_android/core/translator.dart';
import 'package:supermarket_android/data/catalogue.dart';
import 'package:supermarket_android/state/store.dart';

/// The catalogue and dictionary exactly as the app loads them.
Catalogue loadCatalogue() => Catalogue.fromJson(jsonDecode(File('assets/data/catalogue.json').readAsStringSync()) as Map<String, dynamic>);

TranslationData loadTranslations() =>
    TranslationData.fromJson(jsonDecode(File('assets/data/translations.json').readAsStringSync()) as Map<String, dynamic>);

/// Tests normally draw every letter as a square block; loading the real fonts makes text widths (and so overflow) realistic.
Future<void> loadAppFonts() async {
  const families = {
    'PlusJakartaSans': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    'NotoSansBengali': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    'NotoSansArabic': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final w in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/${e.key}-$w.ttf'));
    }
    await loader.load();
  }
}

/// Starts the whole app on a phone-sized screen with the given saved settings.
Future<ProviderContainer> pumpNestMart(
  WidgetTester tester, {
  String lang = 'en',
  String palette = 'ocean',
  String theme = 'light',
  Size size = const Size(412, 915),
  Map<String, dynamic> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    kStoreKey: jsonEncode({'lang': lang, 'palette': palette, 'theme': theme, 'themeV': 2, ...saved}),
  });
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 2.625;
  tester.view.physicalSize = size * 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        catalogueProvider.overrideWithValue(loadCatalogue()),
        translationDataProvider.overrideWithValue(loadTranslations()),
      ],
      child: const NestMartApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  return ProviderScope.containerOf(tester.element(find.byType(NestMartApp)));
}

/// Removes the app, so its timers (hero carousel, countdown) are cancelled before the test ends.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// Every piece of text currently built on screen.
List<String> shownTexts(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(find.byType(Text)))
        (t.data ?? t.textSpan?.toPlainText() ?? '').trim(),
    ].where((s) => s.isNotEmpty).toList();

/// Lets a page transition or a sheet finish sliding in. (The first frame only starts the animation, so two frames are needed;
/// pumpAndSettle is avoided because the home page's clock and carousel keep scheduling frames.)
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}