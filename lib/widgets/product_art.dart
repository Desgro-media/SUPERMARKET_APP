import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/catalogue.dart';
import '../data/models.dart';

/// The picture of a product (`.art` in the web app): its photo on a tile tinted with the category colour,
/// or - for products without a photo - a big emoji on the same tile.
/// [variant] picks the n-th photo (product page gallery); [small] uses the 160px copy for tiny slots.
class ProductArt extends ConsumerWidget {
  const ProductArt(this.product, {super.key, this.variant = 0, this.small = false, this.aspectRatio = 1, this.radius = 16});

  final Product product;
  final int variant;
  final bool small;
  final double aspectRatio, radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tint = ref.watch(catalogueProvider).catById[product.cat]!.tint;
    final photo = product.hasPhoto;
    final lightPhoto = photo && !t.dark;
    // light theme: most photos sit on white, so the tile takes a soft tint and the photo is multiplied onto it
    final base = lightPhoto ? AppTokens.mix(tint, .42, Colors.white) : t.tinted(tint);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            Widget child;
            if (photo) {
              final list = small ? product.thumbs : product.imgs;
              final src = variant < list.length ? list[variant] : list[0];
              final dpr = MediaQuery.devicePixelRatioOf(context);
              child = Image.asset(
                src,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: small ? null : (w * dpr).round().clamp(160, 720),
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                color: lightPhoto ? base : null,
                colorBlendMode: lightPhoto ? BlendMode.multiply : null,
                errorBuilder: (_, _, _) => _EmojiArt(product: product, variant: variant, width: w),
              );
            } else {
              child = _EmojiArt(product: product, variant: variant, width: w);
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                color: base,
                // soft highlight in the top-left corner (not on light photos)
                gradient: lightPhoto
                    ? null
                    : RadialGradient(
                        center: const Alignment(-.44, -.76),
                        radius: .66,
                        colors: [Colors.white.withValues(alpha: t.dark ? .06 : .38), Colors.transparent],
                      ),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

/// An emoji standing in for a photo: `data-v` 0 = one emoji, 1 = three (gallery), 2 = one big emoji with a brand tag.
class _EmojiArt extends StatelessWidget {
  const _EmojiArt({required this.product, required this.variant, required this.width});

  final Product product;
  final int variant;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final emoji = product.emoji;
    TextStyle style(double fraction) => TextStyle(
          fontSize: width * fraction,
          height: 1,
          shadows: const [Shadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 4))],
        );

    if (variant == 1) {
      Widget at(double left, double top, double size, double deg) => Positioned(
            left: left * width,
            top: top * width,
            child: Transform.rotate(angle: deg * 3.1415926 / 180, child: Text(emoji, style: style(size))),
          );
      return Stack(children: [at(.12, .16, .34, -12), at(.52, .26, .30, 14), at(.33, .46, .38, 0)]);
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        // the soft ground shadow under the emoji
        Positioned(
          left: width * .28,
          right: width * .28,
          bottom: width * .14,
          height: width * .05,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0x24000000), borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
        Transform.translate(
          offset: variant == 2 ? Offset(width * .10, width * .10) : Offset.zero,
          child: Text(emoji, style: style(variant == 2 ? .84 : .52)),
        ),
        if (variant == 2)
          Positioned(
            left: width * .06,
            top: width * .06,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: width * .032 * .9, vertical: width * .032 * .35),
              decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(999), boxShadow: t.shadow1),
              child: Text(product.brand, style: ts(width * .032, w: FontWeight.w800, color: t.text, height: 1.3)),
            ),
          ),
      ],
    );
  }
}

/// A small square photo for tiny slots (search results, category tiles ...), or the emoji when there is no photo (`pic()` in the web app).
class PhotoOrEmoji extends StatelessWidget {
  const PhotoOrEmoji({super.key, required this.src, required this.emoji, this.emojiSize = 24, this.fit = BoxFit.cover, this.cacheWidth});

  final String src, emoji;
  final double emojiSize;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(child: Text(emoji, style: TextStyle(fontSize: emojiSize, height: 1)));
    if (src.isEmpty) return fallback();
    return Image.asset(
      src,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => fallback(),
    );
  }
}