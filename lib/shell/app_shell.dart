import 'dart:math' as math;

import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../app_routes.dart';
import '../core/app_nav.dart';
import '../core/i18n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../state/store.dart';
import '../widgets/app_icon.dart';
import '../widgets/pressable.dart';
import 'announce_bar.dart';
import 'app_header.dart';
import 'bottom_nav.dart';
import 'chrome_scope.dart';
import 'route_tracker.dart';
import 'search_suggest.dart';
import 'toast_layer.dart';

/// The frame around every page, like the web app's header, bottom bar and toasts around its <main>:
///  * the announcement strip scrolls away; the header sticks to the top, slides out of sight when you scroll down
///    (after 160dp) and slides back when you scroll up;
///  * the bottom bar, toasts and "back to top" button float above the page;
///  * pages are swapped in a nested [Navigator], so the bars never move when you open a page.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final RouteTracker _tracker = RouteTracker();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// How far the current page is scrolled, and whether the header is slid out of sight.
  final ValueNotifier<double> _offset = ValueNotifier(0);
  final ValueNotifier<bool> _hidden = ValueNotifier(false);
  final ValueNotifier<bool> _suggestOpen = ValueNotifier(false);
  final ValueNotifier<bool> _langOpen = ValueNotifier(false);

  // each page remembers its own scroll position, so going back restores the header state
  final Map<Route<dynamic>, double> _offsets = {};
  final Map<Route<dynamic>, ScrollPosition> _positions = {};
  double _lastY = 0;

  @override
  void initState() {
    super.initState();
    _tracker.current.addListener(_onRoute);
    _searchFocus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _tracker.current.removeListener(_onRoute);
    _searchFocus.removeListener(_onFocus);
    _tracker.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _offset.dispose();
    _hidden.dispose();
    _suggestOpen.dispose();
    _langOpen.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_searchFocus.hasFocus) {
      _suggestOpen.value = true;
      _langOpen.value = false;
      _hidden.value = false;
    }
  }

  void _onRoute() {
    final r = _tracker.current.value;
    final y = r == null ? 0.0 : (_offsets[r] ?? 0.0);
    _offset.value = y;
    _lastY = y;
    _hidden.value = false;
    _suggestOpen.value = false;
    _langOpen.value = false;
    _searchFocus.unfocus();
    // a search shows its words in the header's search box; any other page clears it
    final args = r?.settings.arguments;
    if (r?.settings.name == Routes.shop) {
      if (args is Map && args['q'] != null) _search.text = '${args['q']}';
    } else {
      _search.clear();
    }
  }

  void _closeSuggest() {
    _suggestOpen.value = false;
    _searchFocus.unfocus();
  }

  bool _onScroll(ScrollNotification n) {
    // only the page's own vertical scrolling counts (not the sideways scrollers inside it)
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final route = _tracker.current.value;
    if (route == null) return false;
    final y = n.metrics.pixels < 0 ? 0.0 : n.metrics.pixels;
    _offsets[route] = y;
    final ctx = n.context;
    if (ctx != null) {
      final pos = Scrollable.maybeOf(ctx)?.position;
      if (pos != null) _positions[route] = pos;
    }
    _offset.value = y;
    final d = y - _lastY;
    if (d.abs() >= 8) {
      final typing = _searchFocus.hasFocus || _suggestOpen.value;
      _hidden.value = d > 0 && y > 160 && !typing;
      _lastY = y;
    }
    return false;
  }

  void _toTop() {
    final pos = _positions[_tracker.current.value];
    if (pos != null && pos.hasPixels) pos.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  void _focusSearch() {
    final pos = _positions[_tracker.current.value];
    if (pos != null && pos.hasPixels) pos.jumpTo(0);
    _hidden.value = false;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _submit(String raw) {
    final q = raw.trim();
    if (q.isEmpty) {
      _searchFocus.requestFocus();
      return;
    }
    ref.read(storeProvider.notifier).pushSearch(q);
    _closeSuggest();
    AppNav.go(Routes.shop, {'q': q});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final media = MediaQuery.of(context);
    final topInset = media.viewPadding.top;
    final bottomInset = media.viewPadding.bottom;
    const announceH = ChromeMetrics.announceH, headerH = ChromeMetrics.headerH;
    final scopeTop = topInset + announceH + headerH;
    final scopeBottom = ChromeMetrics.navH + bottomInset;

    return ListenableBuilder(
      listenable: Listenable.merge([_tracker.canPop, _suggestOpen, _langOpen]),
      // Android's back button: close an open menu first, then go back a page, and only leave the app from the home page
      builder: (context, child) => PopScope(
        canPop: !_tracker.canPop.value && !_suggestOpen.value && !_langOpen.value,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_langOpen.value) {
            _langOpen.value = false;
          } else if (_suggestOpen.value) {
            _closeSuggest();
          } else {
            AppNav.back();
          }
        },
        child: child!,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: t.dark ? Brightness.light : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Material(
          color: t.bg,
          textStyle: baseText(t),
          child: Stack(
            children: [
              // ---- the page (it ends above the on-screen keyboard, so a text field you tap is never hidden by it) ----
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: media.viewInsets.bottom,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: ChromeScope(
                    top: scopeTop,
                    bottom: scopeBottom,
                    child: Navigator(
                      key: AppNav.key,
                      observers: [_tracker],
                      initialRoute: Routes.home,
                      onGenerateRoute: AppRoutes.generate,
                    ),
                  ),
                ),
              ),

              // ---- announcement strip, header, suggestions, language menu, status bar ----
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: Listenable.merge([_offset, _hidden, _suggestOpen, _langOpen]),
                  builder: (context, _) {
                    final y = _offset.value;
                    final annTop = topInset - math.min(y, announceH);
                    final hdrTop = topInset + math.max(0.0, announceH - y);
                    return Stack(
                      children: [
                        if (_suggestOpen.value || _langOpen.value)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                _closeSuggest();
                                _langOpen.value = false;
                              },
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: annTop,
                          height: announceH,
                          child: AnnounceBar(langOpen: _langOpen.value, onToggleLang: () => _langOpen.value = !_langOpen.value),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: hdrTop,
                          height: headerH,
                          child: AnimatedSlide(
                            offset: Offset(0, _hidden.value ? -1.02 : 0),
                            duration: const Duration(milliseconds: 300),
                            curve: const Cubic(.2, .8, .2, 1),
                            child: AppHeader(controller: _search, focusNode: _searchFocus, onSubmit: _submit),
                          ),
                        ),
                        if (_suggestOpen.value)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: hdrTop + ChromeMetrics.searchBottom + 10,
                            child: ListenableBuilder(
                              listenable: _search,
                              builder: (context, _) => SearchSuggestions(query: _search.text, onDone: _closeSuggest),
                            ),
                          ),
                        if (_langOpen.value)
                          PositionedDirectional(
                            top: annTop + 36,
                            end: 12,
                            child: LangMenu(onPicked: () => _langOpen.value = false),
                          ),
                        // the strip behind the phone's clock and battery icons (the web app's theme-color)
                        Positioned(left: 0, right: 0, top: 0, height: topInset, child: ColoredBox(color: t.themeColor)),
                      ],
                    );
                  },
                ),
              ),

              // ---- bottom bar ----
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ListenableBuilder(
                  listenable: _tracker.current,
                  builder: (context, _) => BottomNav(
                    activeTab: navTabFor(_tracker.current.value?.settings.name),
                    onSearch: _focusSearch,
                  ),
                ),
              ),

              // ---- back to top ----
              ValueListenableBuilder<double>(
                valueListenable: _offset,
                builder: (context, y, _) {
                  final show = y > 700;
                  return PositionedDirectional(
                    end: 12,
                    bottom: 70 + bottomInset,
                    child: IgnorePointer(
                      ignoring: !show,
                      child: AnimatedOpacity(
                        opacity: show ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Pressable(
                          onTap: _toTop,
                          semanticLabel: context.tr('Back to top'),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: t.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.line),
                              boxShadow: t.shadow2,
                            ),
                            child: AppIcon('up', size: 20, color: t.text),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const ToastLayer(),
            ],
          ),
        ),
      ),
    );
  }
}
