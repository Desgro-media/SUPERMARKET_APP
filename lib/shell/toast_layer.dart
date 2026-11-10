import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../state/toasts.dart';
import '../widgets/pressable.dart';

/// Shows the toasts just above the bottom bar (`.toasts`).
class ToastLayer extends ConsumerWidget {
  const ToastLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastProvider);
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    return PositionedDirectional(
      start: 12,
      end: 12,
      bottom: 66 + safe,
      child: IgnorePointer(
        ignoring: toasts.isEmpty,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < toasts.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                    child: _ToastView(key: ValueKey(toasts[i].id), toast: toasts[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastView extends ConsumerWidget {
  const _ToastView({super.key, required this.toast});

  final ToastItem toast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(.2, .9, .3, 1.2),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: Transform.scale(scale: .96 + .04 * v, child: child)),
      ),
      child: AnimatedOpacity(
        opacity: toast.leaving ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedSlide(
          offset: toast.leaving ? const Offset(0, .25) : Offset.zero,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: t.deep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
              boxShadow: t.shadow2,
            ),
            child: Row(
              children: [
                Expanded(child: Text(context.tr(toast.message), style: ts(13.5, w: FontWeight.w600, color: Colors.white, height: 1.4))),
                if (toast.action != null) ...[
                  const SizedBox(width: 14),
                  Pressable(
                    onTap: () {
                      ref.read(toastProvider.notifier).dismiss(toast.id);
                      toast.onAction?.call();
                    },
                    scale: .94,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
                      child: Text(context.tr(toast.action!), style: ts(12.5, w: FontWeight.w800, color: t.sun, height: 1.3)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
