import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categories.dart';
import '../models/unit.dart';

class ProductInfo {
  const ProductInfo({required this.name, required this.category, this.brand, this.quantity, this.unit});
  final String name;
  final String category;
  final String? brand;

  /// Package size, when Open Food Facts has a readable one ("500 g", "6 x 330 ml").
  final double? quantity;
  final Unit? unit;
}

/// Looks up barcodes in the free Open Food Facts database.
class ProductLookupService {
  ProductLookupService({http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();
  final http.Client _client;
  final Duration timeout;

  /// Returns null when the product is unknown or has no name. Throws on network problems
  /// (including [timeout]) so callers can tell "offline" from "not found".
  /// [language] (e.g. "es") prefers the product's name in that language when OFF has one.
  Future<ProductInfo?> lookup(String barcode, {String? language}) async {
    final lang = language?.toLowerCase();
    final fields = [
      'product_name',
      if (lang != null) 'product_name_$lang',
      'brands',
      'quantity',
      'categories_tags',
    ].join(',');
    final uri = Uri.https('world.openfoodfacts.org', '/api/v2/product/$barcode.json', {'fields': fields});
    final res = await _client.get(uri, headers: {'User-Agent': 'PantryPal/0.1 (Flutter)'}).timeout(timeout);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status'] != 1) return null;
    final p = body['product'] as Map<String, dynamic>;

    String? text(String k) {
      final v = p[k];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final name = (lang == null ? null : text('product_name_$lang')) ?? text('product_name');
    if (name == null) return null;
    final size = parsePackageSize(text('quantity'));
    return ProductInfo(
      name: name,
      category: categoryFromTags(List<String>.from(p['categories_tags'] ?? const [])),
      brand: text('brands')?.split(',').first.trim(),
      quantity: size?.quantity,
      unit: size?.unit,
    );
  }

  /// Broad Open Food Facts tags that say nothing about the aisle. "Plant-based foods and
  /// beverages" sits on nearly every plant product; it once filed rice as a drink.
  static const _umbrellaTags = {
    'plant-based-foods-and-beverages', 'plant-based-foods', 'foods', 'groceries', 'animal-based-foods',
    'beverages-and-beverages-preparations', 'food-additives', 'dietary-supplements', 'sweet-snacks-and-beverages',
  };

  /// Tag phrases that a broader rule further down would otherwise claim.
  static const _tagOverrides = {
    'green-bean': 'Produce', 'cereal-bar': 'Snacks', 'coconut-milk': 'Canned', 'coconut-water': 'Beverage',
    'fish-sauce': 'Condiments', 'rice-cake': 'Snacks', 'rice-cracker': 'Snacks', 'chocolate-chip': 'Baking',
    'fruit-preserve': 'Spreads', 'cocoa-powder': 'Baking', 'baking-chocolate': 'Baking', 'plant-based-milk': 'Dairy',
    'fish-finger': 'Frozen', 'sweet-potato': 'Produce',
  };

  /// Category → words or hyphenated phrases found in Open Food Facts tags (singular).
  /// Tried in this order within each tag, so drinks beat produce ("fruit juices") and canned
  /// beats seafood ("canned tunas").
  static const _tagRules = <String, List<String>>{
    'Frozen': ['frozen', 'ice-cream', 'sorbet'],
    'Alcohol': ['alcoholic', 'beer', 'wine', 'spirit', 'cider', 'liqueur', 'champagne', 'whisky', 'vodka', 'rum'],
    'Baby': ['baby', 'infant'],
    'Pet': ['pet-food', 'dog-food', 'cat-food', 'pet'],
    'PlantProtein': ['tofu', 'tempeh', 'seitan', 'meat-analogue', 'meat-alternative', 'plant-based-meat'],
    'Deli': ['meal', 'prepared-meal', 'ready-meal', 'pizza', 'sandwich', 'hummus', 'prepared-salad', 'sushi', 'quiche'],
    'Spreads': ['spread', 'jam', 'honey', 'marmalade', 'nut-butter', 'peanut-butter', 'syrup', 'nutella'],
    'Condiments': ['condiment', 'sauce', 'ketchup', 'mustard', 'mayonnaise', 'dressing', 'vinegar', 'oil', 'pesto'],
    'Spices': ['spice', 'salt', 'seasoning', 'dried-herb', 'black-pepper', 'ground-pepper', 'peppercorn', 'bouillon-cube', 'stock-cube'],
    'Baking': ['flour', 'sugar', 'baking', 'yeast', 'baking-powder', 'starch'],
    'Canned': ['canned', 'soup', 'broth', 'tomato-paste', 'preserve', 'tinned'],
    'Beverage': ['beverage', 'drink', 'juice', 'water', 'soda', 'coffee', 'tea', 'smoothie', 'nectar', 'lemonade'],
    'Snacks': ['snack', 'chip', 'crisp', 'cracker', 'biscuit', 'cookie', 'chocolate', 'candy', 'confectionery', 'nut', 'popcorn', 'pretzel'],
    'Grains': ['cereal', 'rice', 'pasta', 'noodle', 'oat', 'quinoa', 'couscous', 'legume', 'lentil', 'bean', 'grain', 'semolina'],
    'Bakery': ['bread', 'bakery', 'pastry', 'cake', 'viennoiserie', 'tortilla', 'bun', 'brioche'],
    'Seafood': ['fish', 'seafood', 'shellfish', 'tuna', 'salmon', 'shrimp', 'prawn', 'sardine', 'mussel'],
    'Meat': ['meat', 'poultry', 'chicken', 'beef', 'pork', 'ham', 'sausage', 'bacon', 'charcuterie', 'turkey'],
    'Dairy': ['dairy', 'milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'egg', 'kefir'],
    'Produce': ['fruit', 'vegetable', 'potato', 'herb', 'salad', 'mushroom', 'berry'],
  };

  /// Maps Open Food Facts category tags onto PantryPal categories. Tags come broad → specific,
  /// so they are read from the most specific end; umbrella tags are skipped; words match whole
  /// (singular), so "watermelons" is not "water".
  static String categoryFromTags(List<String> tags) {
    final parsed = <({List<String> words, String joined})>[];
    for (final raw in tags.reversed) {
      final tag = (raw.contains(':') ? raw.substring(raw.indexOf(':') + 1) : raw).toLowerCase().trim();
      if (tag.isEmpty || _umbrellaTags.contains(tag)) continue;
      final words = [for (final w in tag.split('-')) if (w.isNotEmpty) singularize(w)];
      parsed.add((words: words, joined: words.join('-')));
    }
    // Storage form decides where it lives in the kitchen: any frozen or canned tag wins, even when
    // the most specific tag only names the food ("baked beans" under "canned legumes").
    for (final (form, keys) in const [('Frozen', ['frozen']), ('Canned', ['canned', 'tinned'])]) {
      if (parsed.any((t) => keys.any(t.words.contains))) return form;
    }
    for (final (:words, :joined) in parsed) {
      for (final e in _tagOverrides.entries) {
        if (joined.contains(e.key)) return e.value;
      }
      for (final e in _tagRules.entries) {
        for (final kw in e.value) {
          if (kw.contains('-') ? joined.contains(kw) : words.contains(kw)) return e.key;
        }
      }
    }
    return 'Other';
  }

}
