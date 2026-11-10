import 'package:material_ui/material_ui.dart';

import '../core/theme/app_tokens.dart';
import 'category_nav.dart';
import 'chrome_scope.dart';
import 'footer.dart';

/// The scrolling frame of every page: room for the header, the department chips, the page's own slivers, the footer
/// and room for the bottom bar. (In the web app these are the `<header>`, `<main>` and `<footer>` of one long page.)
class PageScroll extends StatelessWidget {
  const PageScroll({super.key, required this.slivers, this.activeNav, this.showFooter = true});

  final List<Widget> slivers;

  /// Which department chip is highlighted ('deals', a department id or 'new').
  final String? activeNav;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final scope = ChromeScope.of(context);
    return ColoredBox(
      color: context.t.bg,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: scope.top)),
          SliverToBoxAdapter(child: CategoryNav(active: activeNav)),
          ...slivers,
          if (showFooter) const SliverToBoxAdapter(child: SiteFooter()),
          SliverToBoxAdapter(child: SizedBox(height: scope.bottom)),
        ],
      ),
    );
  }
}

/// A box with the page's standard 12px side margins (`.container` on phones).
class PageBox extends StatelessWidget {
  const PageBox({super.key, required this.child, this.top = 0});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(12, top, 12, 0), child: child);
}
