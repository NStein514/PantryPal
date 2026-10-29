/// Pantry categories. Stored and sent to the AI as these English keys; shown through
/// categoryLabel (lib/l10n/l10n.dart). Order = the order pickers list them in.
const kCategories = [
  'Produce', 'Dairy', 'Meat', 'Seafood', 'PlantProtein', 'Deli', 'Bakery', 'Grains', 'Baking', 'Canned',
  'Condiments', 'Spices', 'Spreads', 'Snacks', 'Pantry', 'Frozen', 'Beverage', 'Alcohol', 'Baby', 'Pet',
  'Household', 'Other',
];

/// What each key covers, for AI prompts (the AI must answer with a key).
const kCategoryHints = {
  'Produce': 'fresh fruit, vegetables, fresh herbs',
  'Dairy': 'milk, cheese, yogurt, butter, cream, eggs, plant milks',
  'Meat': 'meat and poultry',
  'Seafood': 'fish and shellfish',
  'PlantProtein': 'tofu, tempeh, meat alternatives',
  'Deli': 'ready meals, deli items, hummus, fresh pasta dishes',
  'Bakery': 'bread, rolls, tortillas, cakes, pastries',
  'Grains': 'rice, pasta, noodles, oats, cereal, quinoa, dry beans and lentils',
  'Baking': 'flour, sugar, yeast, baking powder, cocoa, chocolate chips',
  'Canned': 'canned and jarred goods, soups, broth, tomato paste',
  'Condiments': 'sauces, ketchup, mustard, mayonnaise, dressings, oils, vinegar',
  'Spices': 'salt, pepper, spices, dried herbs, stock cubes',
  'Spreads': 'jam, honey, peanut butter, chocolate spread, syrup',
  'Snacks': 'chips, crackers, nuts, chocolate, sweets, cookies, popcorn',
  'Pantry': 'other shelf-stable staples',
  'Frozen': 'frozen food, ice cream',
  'Beverage': 'non-alcoholic drinks: water, juice, soda, coffee, tea',
  'Alcohol': 'beer, wine, spirits',
  'Baby': 'baby food, formula, nappies',
  'Pet': 'pet food and supplies',
  'Household': 'non-food: cleaning, paper goods, toiletries',
  'Other': 'anything else',
};

/// Older or AI-produced names that mean one of the keys.
const _aliases = {
  'beverages': 'Beverage', 'drinks': 'Beverage', 'drink': 'Beverage',
  'fish': 'Seafood', 'plant protein': 'PlantProtein', 'plantprotein': 'PlantProtein', 'tofu': 'PlantProtein',
  'grain': 'Grains', 'pasta': 'Grains', 'canned goods': 'Canned', 'condiment': 'Condiments', 'sauces': 'Condiments',
  'spice': 'Spices', 'spread': 'Spreads', 'snack': 'Snacks', 'sweets': 'Snacks', 'alcoholic': 'Alcohol',
  'pets': 'Pet', 'cleaning': 'Household', 'dairy & eggs': 'Dairy', 'eggs': 'Dairy',
};

/// Keyword hints (English, Spanish, German, French) for guessing a category from a name.
/// Categories are tried in this order, so specific beats general: "tomato sauce" is
/// Condiments, "canned tuna" Canned, "rice crackers" Snacks, "apple juice" a drink.
/// Keywords of 3 letters or fewer, or starting with "=", must match a whole word; longer ones
/// match a word's start ("bean" → "beans"). Keywords with a space match as a phrase.
const _categoryHints = <String, List<String>>{
  'Frozen': ['frozen', 'ice cream', 'sorbet', 'congelad', 'helado', 'tiefkühl', 'tiefkuehl', 'surgelé', 'surgele', 'glace'],
  'Alcohol': [
    'beer', 'wine', 'vodka', 'whisky', 'whiskey', 'rum', 'gin', 'tequila', 'cider', 'prosecco', 'champagne', 'liqueur',
    'cerveza', 'vino', 'bier', 'wein', 'sekt', 'bière', 'biere', 'vin',
  ],
  'Baby': ['baby', 'infant formula', 'nappies', 'nappy', 'diaper', 'bebé', 'bebe', 'pañal', 'windel', 'couche'],
  'Pet': ['dog food', 'cat food', 'kibble', 'cat litter', 'pet food', 'perro', 'gato', 'hundefutter', 'katzenfutter', 'croquette'],
  'Household': [
    'toilet paper', 'paper towel', 'kitchen roll', 'detergent', 'dish soap', 'washing up', 'dishwasher', 'bleach', 'sponge',
    'bin bag', 'trash bag', 'foil', 'cling film', 'shampoo', 'toothpaste', '=soap', 'tissues', 'papel higiénico', 'detergente',
    'spülmittel', 'waschmittel', 'toilettenpapier', 'lessive', 'papier toilette', 'savon',
  ],
  'Beverage': [
    'juice', 'soda', 'cola', 'water', 'coffee', '=tea', 'lemonade', 'smoothie', 'kombucha', 'zumo', 'jugo', 'agua',
    'café', 'refresco', 'saft', 'wasser', 'kaffee', '=tee', '=jus', '=eau', 'thé',
  ],
  'PlantProtein': ['tofu', 'tempeh', 'seitan', 'meat substitute', 'plant-based burger', 'veggie burger', 'quorn'],
  'Deli': ['hummus', 'ready meal', 'pizza', 'sandwich', 'sushi', 'lasagna', 'lasagne', 'quiche', 'guacamole', 'coleslaw'],
  'Spreads': [
    'peanut butter', 'almond butter', 'nut butter', '=jam', 'marmalade', 'honey', 'syrup', 'nutella', 'chocolate spread',
    'mermelada', '=miel', 'erdnussbutter', 'marmelade', 'honig', 'confiture', 'mantequilla de cacahuete', 'beurre de cacahuète',
  ],
  'Condiments': [
    'sauce', 'ketchup', 'mustard', 'mayonnaise', '=mayo', 'dressing', 'vinegar', '=oil', 'olive oil', 'soy sauce', 'salsa',
    'pesto', 'relish', 'sriracha', 'salsa de', 'mostaza', 'vinagre', 'aceite', 'soße', 'sosse', 'senf', 'essig', '=öl',
    'moutarde', 'vinaigre', 'huile',
  ],
  'Spices': [
    '=salt', 'pepper flakes', 'black pepper', 'peppercorn', 'paprika', 'cumin', 'cinnamon', 'oregano', 'turmeric', 'curry powder',
    'chili powder', 'nutmeg', 'stock cube', 'bouillon', 'seasoning', '=sal', 'pimienta', 'canela', '=salz', 'zimt', 'gewürz',
    '=sel', 'cannelle', 'épice',
  ],
  'Baking': [
    'flour', 'sugar', 'yeast', 'baking powder', 'baking soda', 'bicarbonate', 'cocoa', 'chocolate chip', 'vanilla', 'cornstarch',
    'harina', 'azúcar', 'azucar', 'levadura', 'mehl', 'zucker', 'hefe', 'backpulver', 'farine', 'sucre', 'levure',
  ],
  'Canned': [
    'canned', 'tinned', '=can', 'baked bean', 'tomato paste', 'chopped tomato', 'soup', 'broth', 'stock', 'chickpea', 'en lata',
    'conserva', 'caldo', 'sopa', 'dose', 'konserve', 'brühe', 'suppe', 'conserve', 'bouillon de', 'soupe', 'pois chiche',
  ],
  'Snacks': [
    'chips', 'crisps', 'cracker', 'pretzel', 'popcorn', '=nuts', 'almond', 'cashew', 'peanut', 'chocolate', 'candy', 'sweets',
    'cookie', 'biscuit', 'granola bar', 'cereal bar', 'patatas fritas', 'galleta', 'chocolate', 'galletas', 'kekse', 'nüsse',
    'schokolade', 'süßigkeiten', 'gâteaux', 'biscuits', 'bonbons', 'noix',
  ],
  'Grains': [
    'rice', 'pasta', 'spaghetti', 'penne', 'macaroni', 'noodle', 'oats', 'oatmeal', 'porridge', 'cereal', 'quinoa', 'couscous',
    'barley', 'lentil', 'bean', 'arroz', 'fideo', 'avena', 'lenteja', 'frijol', 'judía', 'reis', 'nudeln', 'haferflocken',
    'linsen', 'bohnen', '=riz', 'pâtes', 'pates', 'lentille', 'haricot',
  ],
  'Bakery': [
    'bread', 'bagel', 'baguette', 'croissant', 'tortilla', 'muffin', '=bun', '=buns', '=roll', 'rolls', 'pita', 'naan', 'brioche',
    'cake', 'pancake', 'waffle', 'crumpet', '=pan', 'bollo', 'brot', 'brötchen', 'broetchen', 'kuchen', '=pain',
  ],
  'Seafood': [
    'fish', 'salmon', 'tuna', 'cod', 'shrimp', 'prawn', 'mussel', 'crab', 'lobster', 'sardine', 'anchov', 'pescado',
    'salmón', 'atún', 'atun', 'gamba', 'fisch', 'lachs', 'thunfisch', 'garnele', 'poisson', 'saumon', '=thon', 'crevette',
  ],
  'Meat': [
    'chicken', 'beef', 'pork', '=ham', 'bacon', 'sausage', 'turkey', 'mince', 'steak', 'lamb', 'salami', 'chorizo', 'pollo',
    'ternera', 'cerdo', 'jamón', 'jamon', 'carne', 'hähnchen', 'huhn', 'rind', 'schwein', 'schinken', 'wurst', 'hack',
    'poulet', 'boeuf', 'bœuf', 'porc', 'jambon', 'saucisse', 'viande',
  ],
  'Dairy': [
    'milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'egg', 'eggs', 'kefir', 'leche', 'queso', 'yogur', 'mantequilla',
    '=nata', 'huevo', 'milch', 'käse', 'kaese', 'joghurt', 'sahne', 'quark', 'eier', '=lait', 'fromage', 'yaourt', 'beurre',
    'crème', 'oeuf', 'œuf', 'oeufs', 'œufs',
  ],
  'Produce': [
    'apple', 'banana', 'lettuce', 'tomato', 'onion', 'potato', 'carrot', 'spinach', 'berr', 'grape', 'lemon', 'lime', 'orange',
    'avocado', 'pepper', 'cucumber', 'broccoli', 'garlic', 'salad', 'fruit', 'vegetable', 'melon', 'mushroom', 'zucchini',
    'courgette', 'squash', 'kale', 'cabbage', 'celery', 'herbs', 'basil', 'cilantro', 'parsley', 'pear', 'peach', 'plum',
    'mango', 'pineapple', 'manzana', 'plátano', 'platano', 'lechuga', 'tomate', 'cebolla', 'patata', '=papa', 'zanahoria',
    'fresa', '=uva', 'limón', 'apfel', 'banane', 'salat', 'zwiebel', 'kartoffel', 'karotte', 'möhre', 'erdbeer', 'pomme',
    'laitue', 'oignon', 'carotte', 'fraise', 'citron', 'champignon',
  ],
};

/// Names that a shorter keyword in an earlier category would otherwise claim.
const _categoryOverrides = <String, String>{
  'butternut': 'Produce', 'green bean': 'Produce', 'snap pea': 'Produce', 'sweet potato': 'Produce', 'watermelon': 'Produce',
  'coconut milk': 'Canned', 'cream of tartar': 'Baking', 'chocolate milk': 'Dairy',
  'oat milk': 'Dairy', 'almond milk': 'Dairy', 'soy milk': 'Dairy', 'rice milk': 'Dairy', 'coconut water': 'Beverage',
  'ice tea': 'Beverage', 'iced tea': 'Beverage', 'peanut butter': 'Spreads', 'almond butter': 'Spreads',
  'erdnussbutter': 'Spreads', 'mantequilla de cacahuete': 'Spreads', 'beurre de cacahuète': 'Spreads', 'cacahuete': 'Snacks',
  'fish sauce': 'Condiments', 'fish fingers': 'Frozen', 'fish sticks': 'Frozen', 'frozen pizza': 'Frozen',
  'chicken stock': 'Canned', 'beef stock': 'Canned', 'vegetable stock': 'Canned', 'tuna can': 'Canned', 'canned tuna': 'Canned',
  'rice cake': 'Snacks', 'rice cracker': 'Snacks', 'salted butter': 'Dairy', 'egg noodle': 'Grains',
  // Bare "pepper" on a list means the spice; the vegetable comes plural or with a colour.
  '=pepper': 'Spices', '=peppers': 'Produce', 'bell pepper': 'Produce', 'red pepper': 'Produce',
  'green pepper': 'Produce', 'yellow pepper': 'Produce', 'chili pepper': 'Produce', 'jalapeño': 'Produce', 'black pepper': 'Spices', 'white pepper': 'Spices',
  'ground pepper': 'Spices', 'peppercorn': 'Spices', 'baby spinach': 'Produce', 'baby carrot': 'Produce',
  'pasta salad': 'Deli', 'potato salad': 'Deli', 'jelly bean': 'Snacks', 'fish cake': 'Seafood', 'dried herb': 'Spices',
  'chocolate chip': 'Baking', 'eggplant': 'Produce', 'aubergine': 'Produce', '=pie': 'Bakery',
};

/// Singular of a lower-case English word, for matching ("tomatoes" → tomato, "berries" → berry).
String singularize(String w) => _singular(w);

String _singular(String w) {
  if (w.length > 4 && w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
  if (w.length > 4 && w.endsWith('oes')) return w.substring(0, w.length - 2);
  if (w.length > 4 && RegExp(r'(ches|shes|sses|xes)$').hasMatch(w)) return w.substring(0, w.length - 2);
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) return w.substring(0, w.length - 1);
  return w;
}

bool _hit(String kw, String text, List<String> words) {
  if (kw.contains(' ')) return text.contains(kw);
  if (kw.startsWith('=')) {
    final k = kw.substring(1);
    return words.any((w) => w == k || _singular(w) == k);
  }
  return words.any((w) => kw.length <= 3 ? (w == kw || _singular(w) == kw) : w.startsWith(kw));
}

/// A likely category for a typed or scanned item name, or null when nothing matches.
String? guessCategory(String name) {
  final text = ' ${name.trim().toLowerCase()} ';
  if (text.trim().isEmpty) return null;
  final words = text.split(RegExp(r"[^a-zà-ÿœß]+")).where((w) => w.isNotEmpty).toList();
  // The longest matching override wins ("baby spinach" over "baby").
  String? best;
  var bestLen = 0;
  for (final e in _categoryOverrides.entries) {
    if (e.key.length > bestLen && _hit(e.key, text, words)) {
      best = e.value;
      bestLen = e.key.length;
    }
  }
  if (best != null) return best;
  for (final e in _categoryHints.entries) {
    for (final kw in e.value) {
      if (_hit(kw, text, words)) return e.key;
    }
  }
  return null;
}

/// A better category for an item filed under a coarse or mistaken one, or null to leave it.
/// Used once when upgrading stored data:
///  * Beverage → a food category when the name clearly says food (barcode scans of plant-based
///    products used to land in Beverage);
///  * Pantry → one of the newer, more specific shelf-stable categories.
String? betterCategory(String name, String current) {
  final guess = guessCategory(name);
  if (guess == null || guess == current) return null;
  if (current == 'Beverage' && !const {'Beverage', 'Alcohol', 'Dairy', 'Other'}.contains(guess)) return guess;
  if (current == 'Pantry' && const {'Grains', 'Baking', 'Canned', 'Condiments', 'Spices', 'Spreads', 'Snacks'}.contains(guess)) {
    return guess;
  }
  return null;
}

/// Maps free text (e.g. from the AI or older data) onto a known category.
/// Case-insensitive; tolerates plurals and common names ("Beverages", "Drinks", "Fish").
/// Unknown values become "Other".
String normalizeCategory(Object? raw) {
  final s = '${raw ?? ''}'.trim().toLowerCase();
  if (s.isEmpty) return 'Other';
  for (final c in kCategories) {
    if (s == c.toLowerCase()) return c;
  }
  final alias = _aliases[s];
  if (alias != null) return alias;
  for (final c in kCategories) {
    if (s.startsWith(c.toLowerCase())) return c;
  }
  return 'Other';
}
