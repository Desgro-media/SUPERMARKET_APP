import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import 'models.dart';

/// The shop's data: departments, categories and products, exactly as in the web app's js/data.js.
/// Like the web app (which has no server), it ships inside the app as assets/data/catalogue.json.
class Catalogue {
  Catalogue._({
    required this.config,
    required this.depts,
    required this.categories,
    required this.products,
    required this.brands,
  })  : byId = {for (final p in products) p.id: p},
        catById = {for (final c in categories) c.id: c},
        deptById = {for (final d in depts) d.id: d};

  factory Catalogue.fromJson(Map<String, dynamic> j) => Catalogue._(
        config: AppConfig.fromJson(j['config'] as Map<String, dynamic>),
        depts: [for (final d in j['depts'] as List) Dept.fromJson(d as Map<String, dynamic>)],
        categories: [for (final c in j['categories'] as List) Category.fromJson(c as Map<String, dynamic>)],
        products: [for (final p in j['products'] as List) Product.fromJson(p as Map<String, dynamic>)],
        brands: List<String>.from(j['brands'] as List),
      );

  static Future<Catalogue> load() async {
    final raw = await rootBundle.loadString('assets/data/catalogue.json');
    return Catalogue.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  final AppConfig config;
  final List<Dept> depts;
  final List<Category> categories;
  final List<Product> products;
  final List<String> brands;
  final Map<int, Product> byId;
  final Map<String, Category> catById;
  final Map<String, Dept> deptById;

  Category categoryOf(Product p) => catById[p.cat]!;
}

/// Overridden in main() with the loaded catalogue.
final catalogueProvider = Provider<Catalogue>((ref) => throw UnimplementedError('catalogueProvider must be overridden'));
