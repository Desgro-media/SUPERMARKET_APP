import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palettes.dart';
import 'core/translator.dart';
import 'data/catalogue.dart';
import 'shell/app_shell.dart';
import 'state/store.dart';

/// No stretch/glow when a page is scrolled past its end: the web app switches that bounce off too.
class _NoOverscroll extends ScrollBehavior {
  const _NoOverscroll();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

class NestMartApp extends ConsumerWidget {
  const NestMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (theme, palette, lang) = ref.watch(storeProvider.select((s) => (s.theme, s.palette, s.lang)));
    final cfg = ref.watch(catalogueProvider).config;
    final translator = ref.watch(translatorProvider);
    // Bengali / Arabic: no letter-spacing, taller lines (read by ts() while the screens rebuild below)
    ScriptStyle.complex = translator.isComplexScript;
    return MaterialApp(
      title: cfg.name,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(kPaletteTokens['$palette-light']!),
      darkTheme: buildTheme(kPaletteTokens['$palette-dark']!),
      themeMode: switch (theme) {
        'dark' => ThemeMode.dark,
        'auto' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      locale: languageById(lang).locale,
      supportedLocales: [for (final l in kLanguages) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => I18nScope(
        translator: translator,
        // sizes are laid out in dp like the web CSS, so very large system fonts are capped
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1, maxScaleFactor: 1.15),
          ),
          child: ScrollConfiguration(behavior: const _NoOverscroll(), child: child!),
        ),
      ),
      home: const AppShell(),
    );
  }
}
