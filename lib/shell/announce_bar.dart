import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../state/store.dart';
import '../widgets/app_icon.dart';
import '../widgets/flag_svgs.dart';
import '../widgets/pressable.dart';

/// The dark strip at the very top: the free-delivery message, the Dark Mode switch and the language button.
class AnnounceBar extends ConsumerWidget {
  const AnnounceBar({super.key, required this.langOpen, required this.onToggleLang});

  final bool langOpen;
  final VoidCallback onToggleLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cfg = ref.watch(catalogueProvider).config;
    final lang = ref.watch(storeProvider.select((s) => s.lang));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = Colors.white.withValues(alpha: .92);
    final msg = context.tr('Free delivery over ${moneyText(cfg.freeDeliveryAt, cfg.currency)}');

    return Container(
      color: t.deep,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DefaultTextStyle(
        style: ts(11.5, w: FontWeight.w600, color: fg, height: 1.5),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const AppIcon('truck', size: 13),
                  const SizedBox(width: 4),
                  Flexible(child: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Dark Mode switch
            Pressable(
              onTap: () => ref.read(storeProvider.notifier).setTheme(isDark ? 'light' : 'dark'),
              scale: .96,
              semanticLabel: context.tr('Dark Mode'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('Dark Mode'), style: ts(11, w: FontWeight.w700, color: fg)),
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 16,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? t.sun : Colors.white.withValues(alpha: .32),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isDark ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1))],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // language button
            Pressable(
              onTap: onToggleLang,
              scale: .96,
              semanticLabel: context.tr('Language'),
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(languageById(lang).short, style: ts(11.5, w: FontWeight.w800, color: fg, ls: .04)),
                    const SizedBox(width: 3),
                    AnimatedRotation(
                      turns: langOpen ? .5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const AppIcon('down', size: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The drop-down list of languages under the language button.
class LangMenu extends ConsumerWidget {
  const LangMenu({super.key, required this.onPicked});

  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cur = ref.watch(storeProvider.select((s) => s.lang));
    return Container(
      constraints: const BoxConstraints(minWidth: 176),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: t.shadow2,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in kLanguages)
              Pressable(
                onTap: () {
                  ref.read(storeProvider.notifier).setLang(l.id);
                  onPicked();
                },
                scale: .98,
                semanticLabel: l.name,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: l.id == cur ? t.brand50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 16,
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0x24000000), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SvgPicture.string(kFlagSvgs[l.id]!, width: 24, height: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l.name,
                        style: ts(14.5, w: l.id == cur ? FontWeight.w800 : FontWeight.w600, color: l.id == cur ? t.brand600 : t.text, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
