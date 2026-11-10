import 'package:material_ui/material_ui.dart';

/// Sizes (in dp, the same numbers as the web app's phone CSS) of the bars around every page.
abstract final class ChromeMetrics {
  /// The dark strip with the free-delivery message, the Dark Mode switch and the language menu.
  static const double announceH = 30;

  /// Logo, city and wishlist on the first row, the search bar on the second (8 + 36 + 8 + 40 + 8, plus a 1px border).
  static const double headerH = 101;

  /// The row of department chips under the header (1px border + 40).
  static const double catNavH = 41;

  /// The bottom navigation bar without the system gesture inset (1px border + 4 + 48 + 4).
  static const double navH = 57;

  /// Where the search bar ends inside the header (the suggestions drop down from just below it).
  static const double searchBottom = 92;
}

/// Tells a page how much room the shell's bars take, so its content can start below the header and end above the bottom bar.
class ChromeScope extends InheritedWidget {
  const ChromeScope({super.key, required this.top, required this.bottom, required super.child});

  /// Status bar + announcement strip + header.
  final double top;

  /// Bottom navigation bar + system gesture area.
  final double bottom;

  static ChromeScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ChromeScope>()!;

  @override
  bool updateShouldNotify(ChromeScope oldWidget) => oldWidget.top != top || oldWidget.bottom != bottom;
}
