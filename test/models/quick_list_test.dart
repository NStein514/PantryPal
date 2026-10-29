import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/quick_list.dart';
import 'package:pantrypal/models/unit.dart';

void main() {
  final today = DateTime(2026, 10, 28);
  List<String> parse(String s, {Map<String, KnownProduct> known = const {}}) =>
      [for (final d in parseQuickList(s, known: known, today: today)) '${d.name} ${d.quantityLabel} ${d.category}'];

  test('counts before or after the name, sizes anywhere', () {
    expect(parse('2 x milk\nflour 1 kg\neggs 12\nmilk x3\n500 g butter\n6 x 330 ml cola\nbananas'), [
      'Milk ×2 Dairy',
      'Flour 1 kg Baking',
      'Eggs ×12 Dairy',
      'Milk ×3 Dairy',
      'Butter 500 g Dairy',
      'Cola ×6 Beverage',
      'Bananas ×1 Produce',
    ]);
  });

  test('commas, semicolons and bullets separate items; decimal commas do not', () {
    expect(parse('- bread, 1,5 l milk; • apples'), ['Bread ×1 Bakery', 'Milk 1.5 L Dairy', 'Apples ×1 Produce']);
  });

  test('names that start with digits stay intact; blanks are skipped', () {
    expect(parse('7up\n\n   \n'), ['7up ×1 Other']);
  });

  test('remembered products bring spelling, category, usual size and shelf life', () {
    const flour = KnownProduct(name: 'Flour (T55)', category: 'Pantry', unit: Unit.kg, quantity: 1, shelfDays: 180);
    final drafts = parseQuickList('2 flour (t55)', known: {flour.key: flour}, today: today);
    final d = drafts.single;
    expect([d.name, d.quantityLabel, d.expiry, d.expiryEstimated], ['Flour (T55)', '2 kg', DateTime(2027, 4, 26), true]);
  });

  test('nothing to parse', () => expect(parse(' \n , ; '), isEmpty));

  test('more ways people type counts (found by running the parser on messy samples)', () {
    expect(parse('milk 2x\nMilk (3)\n1 dozen eggs\ndozen eggs\n2 dozen eggs\nDutzend Eier\ndocena de huevos\ntomatoes 400g x2'), [
      'Milk ×2 Dairy',
      'Milk ×3 Dairy',
      'Eggs ×12 Dairy',
      'Eggs ×12 Dairy',
      'Eggs ×24 Dairy',
      'Eier ×12 Dairy',
      'Huevos ×12 Dairy',
      'Tomatoes 800 g Produce',
    ]);
  });
}
