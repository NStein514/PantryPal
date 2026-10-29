import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/meal_shopping.dart';

void main() {
  final pantry = [
    PantryItem(id: 1, name: 'Milk', quantity: 1, unit: Unit.l),
    PantryItem(id: 2, name: 'Eggs', quantity: 4),
    PantryItem(id: 3, name: 'Flour', quantity: 1, unit: Unit.kg),
  ];
  Recipe r(String title, List<RecipeIngredient> ings) => Recipe(title: title, ingredients: ings);
  List<String> labels(List<ShoppingNeed> n) => [for (final x in n) '${x.label} <${x.recipes.join(', ')}>'];

  test('pantry stock is reserved across the week', () {
    final week = [
      r('Pancakes', const [RecipeIngredient(name: 'Milk', amount: 500, unit: Unit.ml), RecipeIngredient(name: 'Eggs', amount: 2)]),
      r('Custard', const [RecipeIngredient(name: 'milk', amount: 0.4, unit: Unit.l), RecipeIngredient(name: 'Eggs', amount: 2)]),
      r('Quiche', const [RecipeIngredient(name: 'Whole milk', amount: 300, unit: Unit.ml), RecipeIngredient(name: 'Egg', amount: 3)]),
    ];
    // milk: 500 + 400 = 900 ml of 1 L, then 300 ml more → short 0.2 L; eggs: 2 + 2 of 4, then 3 short
    expect(labels(shoppingForPlan(week, pantry)), ['Milk 0.2 L <Quiche>', 'Eggs 3 <Quiche>']);
  });

  test('missing ingredients add up across recipes when units allow', () {
    final week = [
      r('A', const [RecipeIngredient(name: 'Basil'), RecipeIngredient(name: 'Butter', amount: 50, unit: Unit.g)]),
      r('B', const [RecipeIngredient(name: 'basil'), RecipeIngredient(name: 'Butter', amount: 0.1, unit: Unit.kg)]),
      r('C', const [RecipeIngredient(name: 'Cream', amount: 1, unitText: 'cup'), RecipeIngredient(name: 'Cream', amount: 1, unitText: 'cup')]),
    ];
    expect(labels(shoppingForPlan(week, pantry)), ['Basil <A, B>', 'Butter 150 g <A, B>', 'Cream 2 cup <C>']);
  });

  test('staples and unclear amounts of things you have are not added', () {
    final week = [
      r('A', const [RecipeIngredient(name: 'Salt'), RecipeIngredient(name: 'Water', amount: 1, unit: Unit.l),
        RecipeIngredient(name: 'Flour', amount: 2, unitText: 'cups')]),
    ];
    expect(shoppingForPlan(week, pantry), isEmpty);
  });

  test('labels read back as quantities on the shopping list', () {
    expect(ShoppingNeed(name: 'Eggs', amount: 3, unit: Unit.count, recipes: []).label, 'Eggs 3');
    expect(ShoppingNeed(name: 'Rice', amount: 1.5, unit: Unit.kg, recipes: []).label, 'Rice 1.5 kg');
    expect(ShoppingNeed(name: 'Basil', recipes: []).label, 'Basil');
  });
}
