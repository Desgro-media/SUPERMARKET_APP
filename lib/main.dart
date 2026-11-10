import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/translator.dart';
import 'data/catalogue.dart';
import 'state/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // the app follows the web app's phone layout, so it stays upright
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final prefs = await SharedPreferences.getInstance();
  final catalogue = await Catalogue.load();
  final translations = await TranslationData.load();
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        catalogueProvider.overrideWithValue(catalogue),
        translationDataProvider.overrideWithValue(translations),
      ],
      child: const NestMartApp(),
    ),
  );
}
