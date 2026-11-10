import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../data/models.dart';
import '../../widgets/buttons.dart';
import '../../widgets/product_art.dart';
import '../../widgets/ui_bits.dart';

enum _Tone { hero1, accent, sun, hero4 }

class _Slide {
  const _Slide(this.tone, this.eyebrow, this.title, this.cta, this.route, this.args, this.art);

  final _Tone tone;
  final String eyebrow, title, cta, route;
  final Map<String, dynamic> args;

  /// (product id, rotation in degrees): the four product photos floating beside the text.
  final List<(int, double)> art;
}

// The four slides of the web app's hero (SLIDES in js/views-shop.js).
const List<_Slide> _slides = [
  _Slide(_Tone.hero1, 'Everything you need', 'One store for your whole home', 'Start shopping', Routes.shop, {},
      [(6400, -12), (6303, 14), (6402, -26), (6320, 10)]),
  _Slide(_Tone.accent, 'Weekly deals', 'Up to 30% off your favourites', 'See all deals', Routes.shop, {'deal': '1'},
      [(6302, -8), (6381, 12), (6361, -16), (6403, 8)]),
  _Slide(_Tone.sun, 'Grooming & care', 'Shaving sets, brushes & personal care', 'Shop health & beauty', Routes.shop, {'dept': 'beauty'},
      [(6412, -14), (6413, 10), (6407, -8), (6408, 14)]),
  _Slide(_Tone.hero4, 'Home & kitchen', 'Everything for a spotless, well-run home', 'Shop home & living', Routes.shop, {'dept': 'home'},
      [(6394, -10), (6390, 12), (6388, -6), (6391, 10)]),
];

/// The banner is as tall as its tallest slide (the web's CSS grid does this for free). Each slide's text is measured with the
/// real font, language and text size, so a long title in a narrow phone or in Bengali/Arabic can never overflow.
double _carouselHeight(BuildContext context, double width) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final copyWidth = (width - 16 - 14 - 4) * 145 / 225; // the text column of the slide
  var copy = 0.0;
  for (final s in _slides) {
    final eyebrow = TextPainter(
      text: TextSpan(text: context.tr(s.eyebrow).toUpperCase(), style: ts(10, w: FontWeight.w800, ls: .1)),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: copyWidth);
    final title = TextPainter(
      text: TextSpan(text: context.tr(s.title), style: ts(22, w: FontWeight.w800, height: 1.08, ls: -.03)),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: copyWidth);
    copy = math.max(copy, eyebrow.height + 6 + title.height + 10 + 36);
  }
  // 16 above, the dots' 40 below, and 2 spare so rounding can never overflow
  return 16 + math.max(copy, 120) + 40 + 2;
}

/// The rotating banner at the top of the home page: four slides, swipe or wait 6.5 seconds, dots at the bottom-left.
class HeroCarousel extends ConsumerStatefulWidget {
  const HeroCarousel({super.key});

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  final PageController _pages = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 6500), (_) {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        (_index + 1) % _slides.length,
        duration: const Duration(milliseconds: 650),
        curve: const Cubic(.65, 0, .25, 1),
      );
    });
  }

  void _stop() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _stop(),
      onPointerUp: (_) => _play(),
      onPointerCancel: (_) => _play(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: _carouselHeight(context, MediaQuery.sizeOf(context).width - 24),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(_slides[i]),
              ),
              PositionedDirectional(
                start: 14,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: .22), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _slides.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _pages.animateToPage(i, duration: const Duration(milliseconds: 650), curve: const Cubic(.65, 0, .25, 1)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: i == _index ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _index ? Colors.white : Colors.white.withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends ConsumerWidget {
  const _SlideView(this.slide);

  final _Slide slide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cat = ref.watch(catalogueProvider);
    final (bg, fg, onLight) = switch (slide.tone) {
      _Tone.hero1 => (t.hero1, Colors.white, false),
      _Tone.accent => (t.accent, t.ink, true),
      _Tone.sun => (t.sun, t.ink, true),
      _Tone.hero4 => (t.hero4, Colors.white, false),
    };
    final circleA = Colors.white.withValues(alpha: onLight ? .3 : .1);
    final circleB = Colors.white.withValues(alpha: onLight ? .18 : .06);

    return ColoredBox(
      color: bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          return Stack(
            children: [
              // the two soft circles behind the content
              PositionedDirectional(end: -.08 * w, top: h / 2 - 100, width: 200, height: 200, child: DecoratedBox(decoration: BoxDecoration(color: circleA, shape: BoxShape.circle))),
              PositionedDirectional(start: -.08 * w, bottom: -.30 * h, width: 160, height: 160, child: DecoratedBox(decoration: BoxDecoration(color: circleB, shape: BoxShape.circle))),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 14, 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 145,
                      child: DefaultTextStyle(
                        style: ts(14, color: fg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Eyebrow(context.tr(slide.eyebrow), size: 10, color: fg, opacity: onLight ? .8 : .85),
                            const SizedBox(height: 6),
                            Text(context.tr(slide.title), style: ts(22, w: FontWeight.w800, color: fg, height: 1.08, ls: -.03)),
                            const SizedBox(height: 10),
                            AppButton(
                              label: context.tr(slide.cta),
                              kind: onLight ? BtnKind.dark : BtnKind.light,
                              trailingIcon: 'arrow',
                              height: 36,
                              fontSize: 13,
                              horizontal: 14,
                              onTap: () => AppNav.go(slide.route, slide.args.isEmpty ? null : slide.args),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 80,
                      child: SizedBox(
                        height: 120,
                        child: LayoutBuilder(
                          builder: (context, art) {
                            // the four photos sit at fixed spots (left as a share of the width, top in dp), as in the phone CSS
                            const spots = [(0.0, 2.0), (.46, 12.0), (.06, 58.0), (.50, 62.0)];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var k = 0; k < slide.art.length; k++)
                                  PositionedDirectional(
                                    start: spots[k].$1 * art.maxWidth,
                                    top: spots[k].$2,
                                    child: _ArtTile(product: cat.byId[slide.art[k].$1]!, degrees: slide.art[k].$2),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One floating product photo: a white-framed rounded square, slightly rotated, with a soft shadow.
class _ArtTile extends StatelessWidget {
  const _ArtTile({required this.product, required this.degrees});

  final Product product;
  final double degrees;

  @override
  Widget build(BuildContext context) {
    const size = 54.6; // 1.3em of the 42px art font size
    return Transform.rotate(
      angle: degrees * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(1.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.4),
          boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 18, offset: Offset(0, 16))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.5),
          child: PhotoOrEmoji(src: product.hasPhoto ? product.imgs[0] : '', emoji: product.emoji, emojiSize: 36, cacheWidth: 220),
        ),
      ),
    );
  }
}
