import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A small message at the bottom of the screen, optionally with one action button (UI.toast in the web app).
@immutable
class ToastItem {
  const ToastItem({required this.id, required this.message, this.action, this.onAction, this.leaving = false});

  final int id;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final bool leaving;

  ToastItem copyWith({bool? leaving}) =>
      ToastItem(id: id, message: message, action: action, onAction: onAction, leaving: leaving ?? this.leaving);
}

class ToastNotifier extends Notifier<List<ToastItem>> {
  int _seq = 0;
  final Map<int, Timer> _timers = {};

  @override
  List<ToastItem> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
    });
    return const [];
  }

  /// At most three toasts are shown; the oldest goes first.
  void show(String message, {String? action, VoidCallback? onAction, int ms = 4200}) {
    final id = ++_seq;
    var list = [...state, ToastItem(id: id, message: message, action: action, onAction: onAction)];
    while (list.length > 3) {
      _timers.remove(list.first.id)?.cancel();
      list = list.sublist(1);
    }
    state = list;
    _timers[id] = Timer(Duration(milliseconds: ms), () => dismiss(id));
  }

  /// Fades the toast out (0.2s) and then removes it.
  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    if (!state.any((t) => t.id == id && !t.leaving)) return;
    state = [for (final t in state) t.id == id ? t.copyWith(leaving: true) : t];
    Timer(const Duration(milliseconds: 220), () {
      state = [for (final t in state) if (t.id != id) t];
    });
  }
}

final toastProvider = NotifierProvider<ToastNotifier, List<ToastItem>>(ToastNotifier.new);
