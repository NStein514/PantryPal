import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/product_lookup_service.dart';

void main() {
  test('returns name and mapped category for a known barcode', () async {
    late Uri requested;
    final svc = ProductLookupService(client: MockClient((req) async {
      requested = req.url;
      expect(req.headers['User-Agent'], contains('PantryPal'));
      return http.Response(
          jsonEncode({'status': 1, 'product': {'product_name': ' Whole Milk ', 'categories_tags': ['en:dairies', 'en:milks']}}), 200);
    }));
    final info = await svc.lookup('012345678905');
    expect(requested.path, '/api/v2/product/012345678905.json');
    expect(info?.name, 'Whole Milk');
    expect(info?.category, 'Dairy');
  });

  test('returns null for unknown products, blank names and HTTP errors', () async {
    expect(await ProductLookupService(client: MockClient((_) async => http.Response('{"status":0}', 200))).lookup('1'), isNull);
    expect(
        await ProductLookupService(client: MockClient((_) async => http.Response('{"status":1,"product":{"product_name":""}}', 200)))
            .lookup('1'),
        isNull);
    expect(await ProductLookupService(client: MockClient((_) async => http.Response('', 503))).lookup('1'), isNull);
  });

  test('categoryFromTags maps tags and falls back to Other', () {
    expect(ProductLookupService.categoryFromTags(['en:frozen-foods']), 'Frozen');
    expect(ProductLookupService.categoryFromTags(['en:breads']), 'Bakery');
    expect(ProductLookupService.categoryFromTags(['en:fruits-and-vegetables-based-foods']), 'Produce');
    expect(ProductLookupService.categoryFromTags([]), 'Other');
  });

  test('prefers the name in the requested language and reads brand and pack size', () async {
    late Uri requested;
    final svc = ProductLookupService(client: MockClient((req) async {
      requested = req.url;
      return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Whole milk',
              'product_name_es': 'Leche entera',
              'brands': 'Granja Sol, Other',
              'quantity': '1,5 L',
              'categories_tags': ['en:milks'],
            }
          }),
          200);
    }));
    final info = (await svc.lookup('8410000000000', language: 'es'))!;
    expect(requested.queryParameters['fields'], contains('product_name_es'));
    expect([info.name, info.brand, info.quantity, info.unit, info.category], ['Leche entera', 'Granja Sol', 1.5, Unit.l, 'Dairy']);
  });

  test('falls back to the default name; no size when unreadable', () async {
    final svc = ProductLookupService(client: MockClient((_) async => http.Response(
        jsonEncode({'status': 1, 'product': {'product_name': 'Crackers', 'product_name_fr': ' ', 'quantity': 'a box'}}), 200)));
    final info = (await svc.lookup('1', language: 'fr'))!;
    expect([info.name, info.quantity, info.unit, info.brand], ['Crackers', null, null, null]);
  });

  test('a slow server times out (so the app can say "no connection")', () async {
    final svc = ProductLookupService(
      timeout: const Duration(milliseconds: 20),
      client: MockClient((_) => Future.delayed(const Duration(seconds: 1), () => http.Response('{}', 200))),
    );
    await expectLater(svc.lookup('1'), throwsA(isA<TimeoutException>()));
  });

  test('categoryFromTags: real Open Food Facts tag lists (rice was once filed as a drink)', () {
    const base = ['en:plant-based-foods-and-beverages', 'en:plant-based-foods'];
    final cases = <String, (List<String>, String)>{
      'rice': ([...base, 'en:cereals-and-potatoes', 'en:seeds', 'en:cereal-grains', 'en:rices', 'en:long-grain-rices'], 'Grains'),
      'pasta': ([...base, 'en:cereals-and-potatoes', 'en:pastas', 'en:dry-pastas'], 'Grains'),
      'olive oil': ([...base, 'en:fats', 'en:vegetable-oils', 'en:olive-oils'], 'Condiments'),
      'orange juice': ([...base, 'en:beverages', 'en:plant-based-beverages', 'en:fruit-juices', 'en:orange-juices'], 'Beverage'),
      'peanut butter': ([...base, 'en:spreads', 'en:nut-butters', 'en:peanut-butters'], 'Spreads'),
      'canned tuna': (['en:seafood', 'en:fishes', 'en:canned-foods', 'en:canned-fishes', 'en:tunas', 'en:canned-tunas'], 'Canned'),
      'dark chocolate': (['en:snacks', 'en:sweet-snacks', 'en:chocolates', 'en:dark-chocolates'], 'Snacks'),
      'flour': ([...base, 'en:cereals-and-potatoes', 'en:flours', 'en:wheat-flours'], 'Baking'),
      'salt': (['en:condiments', 'en:salts', 'en:sea-salts'], 'Spices'),
      'watermelon': ([...base, 'en:fruits', 'en:melons', 'en:watermelons'], 'Produce'),
      'whole milk': (['en:dairies', 'en:milks', 'en:whole-milks'], 'Dairy'),
      'red wine': (['en:beverages', 'en:alcoholic-beverages', 'en:wines', 'en:red-wines'], 'Alcohol'),
      'tofu': ([...base, 'en:meat-alternatives', 'en:tofu'], 'PlantProtein'),
      'frozen peas': ([...base, 'en:frozen-foods', 'en:frozen-vegetables', 'en:frozen-peas'], 'Frozen'),
      'baby puree': (['en:baby-foods', 'en:fruit-purees-for-babies'], 'Baby'),
      'ketchup': ([...base, 'en:groceries', 'en:condiments', 'en:sauces', 'en:ketchup'], 'Condiments'),
      'baked beans': ([...base, 'en:canned-foods', 'en:canned-legumes', 'en:baked-beans'], 'Canned'),
      'bread': ([...base, 'en:cereals-and-potatoes', 'en:breads', 'en:sliced-breads'], 'Bakery'),
    };
    for (final e in cases.entries) {
      expect(ProductLookupService.categoryFromTags(e.value.$1), e.value.$2, reason: e.key);
    }
  });

  test('categoryFromTags: only umbrella tags, or none, is Other', () {
    expect(ProductLookupService.categoryFromTags(['en:plant-based-foods-and-beverages', 'en:plant-based-foods']), 'Other');
    expect(ProductLookupService.categoryFromTags([]), 'Other');
  });
}
