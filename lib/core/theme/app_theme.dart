import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

const String kFontFamily = 'PlusJakartaSans';

/// Bengali and Arabic letters are not in Plus Jakarta Sans, so text falls back to the same Noto families the web app loads.
const List<String> kFontFallback = ['NotoSansBengali', 'NotoSansArabic'];

/// Bengali and Arabic are joined scripts. The web app switches letter-spacing off for them and makes the lines taller
/// (body text 1.65, headings 1.35). The app sets [complex] whenever the language changes (see NestMartApp).
abstract final class ScriptStyle {
  static bool complex = false;
}

/// The web app's body text: Plus Jakarta Sans, 14px on phones, line-height 1.5.
TextStyle baseText(AppTokens t) => TextStyle(
      fontFamily: kFontFamily,
      fontFamilyFallback: kFontFallback,
      fontSize: 14,
      height: ScriptStyle.complex ? 1.65 : 1.5,
      fontWeight: FontWeight.w400,
      color: t.text,
      letterSpacing: 0,
    );

/// Shorthand for the many one-off text styles in the web CSS. [ls] is letter-spacing in `em`, like CSS.
TextStyle ts(
  double size, {
  FontWeight w = FontWeight.w400,
  Color? color,
  double height = 1.5,
  double ls = 0,
  TextDecoration? decoration,
  List<Shadow>? shadows,
  bool tabular = false,
}) {
  var lineHeight = height, spacing = ls;
  if (ScriptStyle.complex) {
    spacing = 0;
    // body text 1.5 -> 1.65, headings 1.15 / 1.08 -> 1.35 (a line height of exactly 1.16 is used by prices and stays put)
    if (lineHeight == 1.5) {
      lineHeight = 1.65;
    } else if (lineHeight == 1.15 || lineHeight == 1.08) {
      lineHeight = 1.35;
    }
  }
  return TextStyle(
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    fontSize: size,
    fontWeight: w,
    color: color,
    height: lineHeight,
    letterSpacing: spacing * size,
    decoration: decoration,
    shadows: shadows,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

ThemeData buildTheme(AppTokens t) {
  final base = baseText(t);
  final scheme = ColorScheme(
    brightness: t.dark ? Brightness.dark : Brightness.light,
    primary: t.brand,
    onPrimary: t.onBrand,
    secondary: t.accent,
    onSecondary: t.ink,
    error: t.danger,
    onError: Colors.white,
    surface: t.surface,
    onSurface: t.text,
    outline: t.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.surface,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    // The web app has no ripple: pressed controls shrink slightly instead (see Pressable).
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    dividerColor: t.line,
    textTheme: TextTheme(
      displayLarge: base,
      displayMedium: base,
      displaySmall: base,
      headlineLarge: base,
      headlineMedium: base,
      headlineSmall: base,
      titleLarge: base,
      titleMedium: base,
      titleSmall: base,
      bodyLarge: base,
      bodyMedium: base,
      bodySmall: base,
      labelLarge: base,
      labelMedium: base,
      labelSmall: base,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.brand,
      selectionColor: t.brand.withValues(alpha: .3),
      selectionHandleColor: t.brand,
    ),
    extensions: [t],
  );
}
