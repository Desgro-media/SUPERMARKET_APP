import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../shell/sheets.dart';
import '../../state/store.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cart_widgets.dart';
import 'cart_screen.dart';

/// The cart that slides up over the page ("View cart" in the toast after adding something): the lines, the free-delivery
/// meter, the totals and the View cart / Checkout buttons (the web app's cart drawer on phones).
Future<void> showCartSheet(BuildContext context) => showAppSheet<void>(context, (_) => const _CartSheet());

class _CartSheet extends ConsumerWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final totals = ref.watch(totalsProvider);
    final media = MediaQuery.of(context);

    void go(String route) {
      Navigator.of(context).pop();
      AppNav.go(route);
    }

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * .9),
      decoration: BoxDecoration(color: t.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), boxShadow: t.shadow2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header: "Your cart (3)" and the close button
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 12, 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: context.tr('Your cart')),
                      if (totals.count > 0) TextSpan(text: ' (${totals.count})', style: TextStyle(color: t.muted, fontWeight: FontWeight.w600)),
                    ]),
                    style: ts(18, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02),
                  ),
                ),
                IconCircleButton(icon: 'x', size: 44, semanticLabel: context.tr('Close cart'), onTap: () => Navigator.of(context).maybePop()),
              ],
            ),
          ),
          if (totals.count == 0)
            Padding(
              padding: EdgeInsets.only(bottom: media.viewPadding.bottom),
              child: EmptyCart(
                tall: false,
                text: 'Add something you need.',
                title: 'Your cart is empty',
                onStart: () => go(Routes.shop),
              ),
            )
          else ...[
            Flexible(
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                children: [
                  ShipMeter(totals),
                  for (var i = 0; i < totals.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    CartLineTile(totals.items[i], onDark: true, key: ValueKey(totals.items[i].p.id)),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + media.viewPadding.bottom),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SummaryRows(totals),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(flex: 10, child: AppButton(label: context.tr('View cart'), kind: BtnKind.outline, height: 44, horizontal: 12, expand: true, onTap: () => go(Routes.cart))),
                      const SizedBox(width: 10),
                      Expanded(flex: 13, child: AppButton(label: context.tr('Checkout'), trailingIcon: 'arrow', height: 44, horizontal: 12, expand: true, onTap: () => go(Routes.checkout))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
