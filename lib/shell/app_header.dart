import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../state/store.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/pressable.dart';
import 'logo.dart';
import 'sheets.dart';

/// The sticky header: logo, delivery city and wishlist on the first row, the search bar on the second.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key, required this.controller, required this.focusNode, required this.onSubmit});

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cfg = ref.watch(catalogueProvider).config;
    final area = ref.watch(storeProvider.select((s) => s.area)) ?? cfg.areas.first;
    final wishCount = ref.watch(storeProvider.select((s) => s.wish.length));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: .94),
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const NestLogo(),
                    const Spacer(),
                    // delivery city
                    Pressable(
                      onTap: () => showAreaSheet(context),
                      scale: .96,
                      semanticLabel: context.tr('Delivery city, change'),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsetsDirectional.only(start: 3, end: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: t.brand50, shape: BoxShape.circle),
                              child: AppIcon('pin', size: 15, color: t.brand600),
                            ),
                            const SizedBox(width: 6),
                            Text(context.tr(area), style: ts(13, w: FontWeight.w700, color: t.text, height: 1.2)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconCircleButton(
                      icon: 'heart',
                      badge: wishCount,
                      semanticLabel: context.tr('Wishlist'),
                      onTap: () => AppNav.go(Routes.wishlist),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 40, child: _SearchField(controller: controller, focusNode: focusNode, onSubmit: onSubmit)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode, required this.onSubmit});

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focus = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: focus ? t.surface : t.surface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: focus ? t.brand : Colors.transparent, width: 1.5),
            boxShadow: focus ? [BoxShadow(color: t.brand50, spreadRadius: 4)] : null,
          ),
          child: Row(
            children: [
              AppIcon('search', size: 18, color: t.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  textField: true,
                  label: context.tr('Search products'),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmit,
                    cursorColor: t.brand,
                    style: ts(16, color: t.text, height: 1.2),
                    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: context.tr('Search products, brands…'),
                      hintStyle: ts(16, color: t.muted, height: 1.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
