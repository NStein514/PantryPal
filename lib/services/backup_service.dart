import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/categories.dart';
import '../models/known_product.dart';
import '../models/pantry_item.dart';
import '../models/reminder_settings.dart';
import '../models/shopping_item.dart';

enum BackupProblem { notJson, notPantryPal, tooNew }

/// Why a file couldn't be imported. [message] stays English (logs); the UI translates [problem].
class BackupFormatException extends FormatException {
  const BackupFormatException(this.problem, super.message);
  final BackupProblem problem;
}

/// What a backup file contains once decoded.
class BackupData {
  const BackupData(
      {required this.items, required this.shopping, this.products = const [], this.reminders, this.exportedAt});
  final List<PantryItem> items;
  final List<ShoppingItem> shopping;

  /// Remembered products (scan memory). Empty for v1 backups.
  final List<KnownProduct> products;
  final ReminderSettings? reminders;
  final DateTime? exportedAt;
}

/// Encodes/decodes PantryPal backups (pretty-printed JSON). Pure Dart: no files, no plugins.
///
/// Format v2 (v1 is the same without "products", and still imports):
/// `{"format":"pantrypal-backup","version":2,"exported_at":ISO,
///   "items":[{name,category,quantity,unit,expiry,added_at}],
///   "shopping":[{name,checked}],"settings":{"lead_days":int,"reminder_hour":int},
///   "products":[{name,category,unit,quantity,barcode,shelf_days,uses,last_used}]}`
/// Cached Open Food Facts lookups are not backed up; they are re-fetched when needed.
class BackupService {
  static const format = 'pantrypal-backup';
  static const version = 2;

  static String fileName(DateTime now) => 'pantrypal-backup-${DateFormat('yyyy-MM-dd').format(now)}.json';

  static String encode({
    required List<PantryItem> items,
    required List<ShoppingItem> shopping,
    required ReminderSettings reminders,
    List<KnownProduct> products = const [],
    DateTime? now,
  }) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'version': version,
        'exported_at': (now ?? DateTime.now()).toIso8601String(),
        'items': [for (final i in items) i.toMap()..remove('id')],
        'shopping': [for (final s in shopping) {'name': s.name, 'checked': s.checked}],
        'settings': {'lead_days': reminders.leadDays, 'reminder_hour': reminders.hour},
        'products': [for (final p in products) p.toMap()..remove('key')],
      });

  /// Throws [BackupFormatException] (a [FormatException]) with a readable message when [raw] isn't a usable backup.
  /// Individual malformed entries are skipped rather than failing the whole import.
  static BackupData decode(String raw) {
    final Object? root;
    try {
      root = jsonDecode(raw);
    } on FormatException {
      throw const BackupFormatException(BackupProblem.notJson, "That file isn't valid JSON.");
    }
    if (root is! Map || root['format'] != format) {
      throw const BackupFormatException(BackupProblem.notPantryPal, "That file isn't a PantryPal backup.");
    }
    final v = root['version'];
    if (v is! int || v > version) {
      throw const BackupFormatException(
          BackupProblem.tooNew, 'This backup was made by a newer version of PantryPal. Update the app first.');
    }

    final items = <PantryItem>[];
    for (final e in root['items'] as List? ?? const []) {
      if (e is! Map || e['name'] is! String || (e['name'] as String).trim().isEmpty) continue;
      try {
        final m = Map<String, Object?>.from(e)..remove('id');
        m['category'] = normalizeCategory(m['category']);
        final item = PantryItem.fromMap(m);
        if (item.quantity > 0) items.add(item);
      } catch (_) {
        // bad date or type in one entry: skip it
      }
    }

    final shopping = <ShoppingItem>[
      for (final e in root['shopping'] as List? ?? const [])
        if (e is Map && e['name'] is String && (e['name'] as String).trim().isNotEmpty)
          ShoppingItem(name: (e['name'] as String).trim(), checked: e['checked'] == true),
    ];

    final products = <KnownProduct>[];
    for (final e in root['products'] as List? ?? const []) {
      if (e is! Map || e['name'] is! String || (e['name'] as String).trim().isEmpty) continue;
      try {
        final m = Map<String, Object?>.from(e);
        final k = KnownProduct.fromMap(m);
        final shelf = k.shelfDays;
        products.add(KnownProduct(
          name: k.name.trim(),
          category: normalizeCategory(k.category),
          unit: k.unit,
          quantity: k.quantity > 0 ? k.quantity : 1,
          barcode: k.barcode != null && RegExp(r'^\d{6,14}$').hasMatch(k.barcode!) ? k.barcode : null,
          shelfDays: shelf != null && shelf > 0 && shelf <= 3650 ? shelf : null,
          uses: k.uses < 1 ? 1 : k.uses,
          lastUsed: k.lastUsed,
        ));
      } catch (_) {
        // wrong types in one entry: skip it
      }
    }

    ReminderSettings? reminders;
    final s = root['settings'];
    if (s is Map && s['lead_days'] is int && s['reminder_hour'] is int) {
      reminders = ReminderSettings(
        leadDays: (s['lead_days'] as int).clamp(1, 7),
        hour: (s['reminder_hour'] as int).clamp(0, 23),
      );
    }

    return BackupData(
      items: items,
      shopping: shopping,
      products: products,
      reminders: reminders,
      exportedAt: root['exported_at'] is String ? DateTime.tryParse(root['exported_at'] as String) : null,
    );
  }
}
