import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../shell/page_scroll.dart';
import '../widgets/buttons.dart';
import '../widgets/page_widgets.dart';

/// Shown for a product or order that does not exist (`V.notFound` in the web app).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => PageScroll(
        slivers: [
          SliverToBoxAdapter(
            child: EmptyState(
              emoji: '\u{1F955}',
              title: "We couldn't find that page",
              text: 'The link may be old, or the product may no longer be on our shelves.',
              tall: true,
              actions: [
                AppButton(label: context.tr('Back to home'), onTap: AppNav.goHome),
                AppButton(label: context.tr('Browse products'), kind: BtnKind.outline, onTap: () => AppNav.go(Routes.shop)),
              ],
            ),
          ),
        ],
      );
}
