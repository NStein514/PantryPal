import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/data/settings_repo.dart';
import 'package:pantrypal/models/recipe_preferences.dart';
import 'package:pantrypal/models/reminder_settings.dart';
import 'package:pantrypal/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsRepo', () {
    test('defaults to 2 days at 9:00', () async {
      final s = await SettingsRepo().load();
      expect([s.leadDays, s.hour], [2, 9]);
    });
    test('round-trips saved values', () async {
      await SettingsRepo().save(const ReminderSettings(leadDays: 5, hour: 20));
      final s = await SettingsRepo().load();
      expect([s.leadDays, s.hour], [5, 20]);
    });
  });

  group('NotificationService.reminderTime', () {
    test('subtracts lead days and applies the hour', () {
      expect(NotificationService.reminderTime(DateTime(2026, 11, 10), 2, 9), DateTime(2026, 11, 8, 9));
      expect(NotificationService.reminderTime(DateTime(2026, 11, 10), 1, 18), DateTime(2026, 11, 9, 18));
    });
    test('crosses month boundaries', () {
      expect(NotificationService.reminderTime(DateTime(2026, 3, 1), 2, 9), DateTime(2026, 2, 27, 9));
    });
  });

  test('recipe preferences: defaults, round-trip, corrupted value', () async {
    expect((await SettingsRepo().loadRecipePreferences()).servings, 2);
    await SettingsRepo().saveRecipePreferences(const RecipePreferences(diets: {Diet.vegan}, servings: 3));
    final p = await SettingsRepo().loadRecipePreferences();
    expect([p.diets, p.servings], [{Diet.vegan}, 3]);
    SharedPreferences.setMockInitialValues({'recipe_prefs': '{oops'});
    expect((await SettingsRepo().loadRecipePreferences()).servings, 2);
  });
}
