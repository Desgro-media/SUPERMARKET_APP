import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_nav.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../widgets/pressable.dart';

/// The NestMart logo: the round mark and the store name. Tapping it goes to the home page.
class NestLogo extends ConsumerWidget {
  const NestLogo({super.key, this.onDark = false});

  /// Used in the dark footer, where the name is white and the mark has no outline.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final name = ref.watch(catalogueProvider).config.name;
    return Pressable(
      onTap: AppNav.goHome,
      semanticLabel: '$name home',
      scale: .97,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: onDark
                  ? null
                  : [
                      BoxShadow(color: t.line, spreadRadius: 1),
                      const BoxShadow(color: Color(0x33000000), blurRadius: 8, spreadRadius: -3, offset: Offset(0, 3)),
                    ],
            ),
            child: ClipOval(child: Image.asset('assets/icons/logo-160.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium)),
          ),
          const SizedBox(width: 8),
          Text(name, style: ts(18, w: FontWeight.w800, color: onDark ? Colors.white : t.text, height: 1.5, ls: -.03)),
        ],
      ),
    );
  }
}
