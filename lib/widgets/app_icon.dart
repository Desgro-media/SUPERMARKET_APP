import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import 'icon_paths.dart';

/// One of the web app's 53 line icons (js/ui.js). By default it takes the surrounding text colour, like `currentColor` in CSS.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 20, this.color, this.stroke = 1.8, this.filled = false});

  final String name;
  final double size;
  final Color? color;

  /// Stroke width in a 24-unit box (the web default is 1.8; a few buttons use 2.2-2.4).
  final double stroke;

  /// `.ico.filled` in the CSS: the shape is filled as well as outlined (hearts, stars).
  final bool filled;

  static final Map<String, String> _svgs = {};

  static String _svg(String name, double stroke, bool filled) => _svgs.putIfAbsent(
        '$name|$stroke|$filled',
        () => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? '#000' : 'none'}" '
            'stroke="#000" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">${kIconPaths[name]}</svg>',
      );

  @override
  Widget build(BuildContext context) {
    assert(kIconPaths.containsKey(name), 'Unknown icon "$name"');
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    Widget w = SvgPicture.string(
      _svg(name, stroke, filled),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
    // arrows that point along the reading direction are mirrored in right-to-left languages
    if (kFlipIcons.contains(name) && Directionality.of(context) == TextDirection.rtl) {
      w = Transform.flip(flipX: true, child: w);
    }
    return ExcludeSemantics(child: w);
  }
}
