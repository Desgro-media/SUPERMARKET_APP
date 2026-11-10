import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// Watches the page stack inside the shell: which page is on top (for the bottom bar highlight and the header's scroll
/// position) and whether Android's back button can go back.
class RouteTracker extends NavigatorObserver {
  final ValueNotifier<Route<dynamic>?> current = ValueNotifier(null);
  final ValueNotifier<bool> canPop = ValueNotifier(false);
  final List<Route<dynamic>> _stack = [];

  // Navigator calls these while building, so listeners are told after the frame.
  void _sync() => SchedulerBinding.instance.addPostFrameCallback((_) {
        current.value = _stack.isEmpty ? null : _stack.last;
        canPop.value = _stack.length > 1;
      });

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) _stack[i] = newRoute;
    _sync();
  }

  void dispose() {
    current.dispose();
    canPop.dispose();
  }
}
