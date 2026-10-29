import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/categories.dart';

void main() {
  test('every key has a description for the AI and is unique', () {
    expect(kCategories.toSet().length, kCategories.length);
    expect(kCategories.length, 22);
    for (final c in kCategories) {
      expect(kCategoryHints[c], isNotNull, reason: c);
    }
  });

  test('guesses everyday items into the right aisle', () {
    final cases = {
      'Rice': 'Grains', 'Basmati rice': 'Grains', 'Olive oil': 'Condiments', 'Black pepper': 'Spices',
      'Peppercorns': 'Spices', 'Red peppers': 'Produce', 'Peanut butter': 'Spreads', 'Canned tuna': 'Canned',
      'Tomato sauce': 'Condiments', 'Watermelon': 'Produce', 'Dog food': 'Pet', 'Toilet paper': 'Household',
      'Red wine': 'Alcohol', 'Tofu': 'PlantProtein', 'Baby wipes': 'Baby', 'Pasta salad': 'Deli', 'Oat milk': 'Dairy',
      'Salted butter': 'Dairy', 'Ground cumin': 'Spices', 'Chicken stock': 'Canned', 'Hummus': 'Deli', 'Cashews': 'Snacks',
      'Jelly beans': 'Snacks', 'Green beans': 'Produce', 'Honey': 'Spreads', 'Whole milk': 'Dairy', 'Chicken thighs': 'Meat',
      'Salmon fillet': 'Seafood', 'Bananas': 'Produce', 'Orange juice': 'Beverage', 'Frozen peas': 'Frozen',
      'Vanilla ice cream': 'Frozen', 'Flour': 'Baking', 'Brot': 'Bakery', 'Green tea': 'Beverage', 'Steak': 'Meat',
    };
    for (final e in cases.entries) {
      expect(guessCategory(e.key), e.value, reason: e.key);
    }
  });

  test('Spanish, German and French names', () {
    expect(guessCategory('Arroz'), 'Grains');
    expect(guessCategory('Reis'), 'Grains');
    expect(guessCategory("Huile d'olive"), 'Condiments');
    expect(guessCategory('Pâtes'), 'Grains');
    expect(guessCategory('Erdnussbutter'), 'Spreads');
    expect(guessCategory('Leche entera'), 'Dairy');
    expect(guessCategory('Saumon fumé'), 'Seafood');
  });

  test('short keywords only match whole words', () {
    expect(guessCategory('Steak'), 'Meat'); // not "tea"
    expect(guessCategory('Candy'), 'Snacks'); // not "can"
    expect(guessCategory('Pancakes'), 'Bakery'); // named outright; "pan" (bread) needs the whole word
  });

  test('nothing to go on', () {
    expect(guessCategory(''), isNull);
    expect(guessCategory('Mystery box'), isNull);
    expect(guessCategory('Vollkornbrot'), isNull); // compound words only match at the start
  });

  test('normalizeCategory accepts keys, plurals and common names', () {
    expect(['Beverages', 'drinks', 'Fish', 'grains', 'PLANTPROTEIN', 'Pantry', 'produce', 'nonsense', null].map(normalizeCategory),
        ['Beverage', 'Beverage', 'Seafood', 'Grains', 'PlantProtein', 'Pantry', 'Produce', 'Other', 'Other']);
  });

  test('betterCategory fixes food filed as a drink and refines Pantry, nothing else', () {
    expect(betterCategory('Rice', 'Beverage'), 'Grains');
    expect(betterCategory('Olive oil', 'Beverage'), 'Condiments');
    expect(betterCategory('Orange juice', 'Beverage'), isNull);
    expect(betterCategory('Oat milk', 'Beverage'), isNull); // drinks-adjacent: leave it
    expect(betterCategory('Mystery', 'Beverage'), isNull);
    expect(betterCategory('Flour', 'Pantry'), 'Baking');
    expect(betterCategory('Bananas', 'Pantry'), isNull); // only shelf-stable refinements
    expect(betterCategory('Rice', 'Produce'), isNull); // other categories are the user's choice
  });

  test('pepper: the spice when bare, the vegetable when plural or coloured', () {
    expect(guessCategory('Pepper'), 'Spices');
    expect(guessCategory('Peppers'), 'Produce');
    expect(guessCategory('Red pepper'), 'Produce');
    expect(guessCategory('Bell peppers'), 'Produce');
    expect(guessCategory('Black pepper'), 'Spices');
  });
}
