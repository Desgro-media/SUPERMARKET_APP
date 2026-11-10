import 'package:material_ui/material_ui.dart';

/// The design tokens of the web app: its CSS custom properties (--bg, --surface, --brand, ...).
/// One instance exists per palette and light/dark mode (see palettes.dart); read it anywhere with `context.t`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.dark,
    required this.tintMix,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.line,
    required this.deep,
    required this.hero1,
    required this.hero4,
    required this.brand,
    required this.brand600,
    required this.brand50,
    required this.onBrand,
    required this.accent,
    required this.accent50,
    required this.sun,
    required this.sun50,
    required this.badgeBg,
    required this.badgeFg,
    required this.sale,
    required this.good,
    required this.good50,
    required this.wide,
    required this.ink,
    required this.star,
    required this.danger,
  });

  final bool dark;

  /// --tint-mix: how strongly a category tint shows (100% in light mode, 22% in dark mode).
  final double tintMix;
  final Color bg,
      surface,
      surface2,
      text,
      muted,
      line,
      deep,
      hero1,
      hero4,
      brand,
      brand600,
      brand50,
      onBrand,
      accent,
      accent50,
      sun,
      sun50,
      badgeBg,
      badgeFg,
      sale,
      good,
      good50,
      wide,
      ink,
      star,
      danger;

  /// CSS `color-mix(in srgb, [a] [pct], [b])` with [pct] as a 0..1 fraction.
  static Color mix(Color a, double pct, Color b) => Color.lerp(b, a, pct)!;

  /// `color-mix(in srgb, var(--tint) var(--tint-mix), var(--surface))`: the soft category colour behind photos and emoji.
  Color tinted(Color tint) => mix(tint, tintMix, surface);

  /// The colour the browser/status bar takes in the web app (`<meta name="theme-color">`).
  Color get themeColor => dark ? bg : brand;

  // --shadow-1 / --shadow-2 / --shadow-brand
  List<BoxShadow> get shadow1 => dark
      ? const [
          BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x40000000), blurRadius: 22, offset: Offset(0, 8)),
        ]
      : const [
          BoxShadow(color: Color(0x0D0F1B33), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0F0F1B33), blurRadius: 22, offset: Offset(0, 8)),
        ];

  List<BoxShadow> get shadow2 => [
        BoxShadow(
          color: dark ? const Color(0x8C000000) : const Color(0x290F1B33),
          blurRadius: 44,
          offset: const Offset(0, 16),
        ),
      ];

  List<BoxShadow> get shadowBrand => [
        BoxShadow(color: brand.withValues(alpha: .55), blurRadius: 16, spreadRadius: -6, offset: const Offset(0, 6)),
      ];

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(covariant AppTokens? other, double t) => other == null || t < .5 ? this : other;
}

extension AppTokensContext on BuildContext {
  /// The design tokens of the current palette and brightness.
  AppTokens get t => Theme.of(this).extension<AppTokens>()!;
}
