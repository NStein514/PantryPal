import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../models/taste_profile.dart';

/// The user's learned recipe taste (see TasteProfile), kept on the device.
class TasteStore extends ChangeNotifier {
  TasteStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  static const _key = 'taste_profile';
  final DateTime Function() _clock;
  TasteProfile profile = const TasteProfile();

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    try {
      profile = raw == null ? const TasteProfile() : TasteProfile.fromJson(jsonDecode(raw)).pruned(_clock());
    } catch (_) {
      profile = const TasteProfile();
    }
    notifyListeners();
  }

  Future<void> _set(TasteProfile p) async {
    profile = p;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(p.toJson()));
  }

  Future<void> cooked(Recipe r) => _set(profile.cookedIt(r.dish, _clock()));
  Future<void> saved(Recipe r) => _set(profile.savedIt(r.dish, _clock()));
  Future<void> planned(Recipe r) => _set(profile.plannedIt(r.dish, _clock()));
  Future<void> swappedAway(Recipe r) => _set(profile.swappedAway(r.dish, _clock()));
  Future<void> notForMe(Recipe r) => _set(profile.notForMe(r.dish, r.title, _clock()));
  Future<void> undoNotForMe(Recipe r) => _set(profile.undoNotForMe(r.dish, r.title, _clock()));

  /// Forgets everything learned.
  Future<void> reset() async {
    profile = const TasteProfile();
    notifyListeners();
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
