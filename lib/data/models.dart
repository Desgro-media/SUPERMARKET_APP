import 'package:material_ui/material_ui.dart';

/// Photos live in assets/images/products/ (the JSON keeps the web app's relative paths, e.g. images/products/6322.webp).
String _asset(String webPath) => webPath.isEmpty ? '' : 'assets/$webPath';

class Dept {
  Dept.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        emoji = j['emoji'] as String,
        blurb = j['blurb'] as String,
        count = j['count'] as int,
        img = _asset(j['img'] as String),
        thumb = _asset(j['thumb'] as String);

  final String id, name, emoji, blurb, img, thumb;
  final int count;
}

class Category {
  Category.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        dept = j['dept'] as String,
        name = j['name'] as String,
        emoji = j['emoji'] as String,
        tint = _hex(j['tint'] as String),
        note = j['note'] as String,
        spec = [
          for (final r in j['spec'] as List) List<String>.from(r as List),
        ],
        count = j['count'] as int,
        img = _asset(j['img'] as String),
        thumb = _asset(j['thumb'] as String);

  final String id, dept, name, emoji, note, img, thumb;
  final Color tint;

  /// Three [label, value] rows for the product page's details tab.
  final List<List<String>> spec;
  final int count;
}

class Product {
  Product.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        name = j['name'] as String,
        cat = j['cat'] as String,
        dept = j['dept'] as String,
        brand = j['brand'] as String,
        price = (j['price'] as num).toDouble(),
        was = (j['was'] as num).toDouble(),
        unit = j['unit'] as String,
        emoji = j['emoji'] as String,
        rating = (j['rating'] as num).toDouble(),
        reviews = j['reviews'] as int,
        stock = j['stock'] as int,
        isNew = j['isNew'] as bool,
        blurb = j['blurb'] as String,
        off = j['off'] as int,
        pop = (j['pop'] as num).toDouble(),
        imgs = [for (final p in j['imgs'] as List) _asset(p as String)],
        thumbs = [for (final p in j['thumbs'] as List) _asset(p as String)];

  final int id, reviews, stock, off;
  final String name, cat, dept, brand, unit, emoji, blurb;

  /// [was] is the old price (0 when the product is not on sale).
  final double price, was, rating, pop;
  final bool isNew;
  final List<String> imgs, thumbs;

  bool get hasPhoto => imgs.isNotEmpty;
  bool get inStock => stock > 0;
}

Color _hex(String h) => Color(0xFF000000 | int.parse(h.substring(1), radix: 16));
