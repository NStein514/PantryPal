import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/product_memory_db.dart';
import '../l10n/l10n.dart';
import '../models/known_product.dart';
import '../services/backup_files.dart';
import '../services/backup_service.dart';
import '../state/locale_store.dart';
import '../state/pantry_store.dart';
import '../state/taste_store.dart';
import '../state/theme_store.dart';
import 'remembered_products_screen.dart';
import '../state/shopping_store.dart';
import '../ui/layout.dart';

enum _ImportChoice { merge, replace }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  Future<void> _export(BuildContext context) async {
    final pantry = context.read<PantryStore>();
    final shop = context.read<ShoppingStore>();
    final files = context.read<BackupFiles>();
    final memory = context.read<ProductMemoryDb?>();
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final box = context.findRenderObject() as RenderBox?;
    final now = DateTime.now();
    try {
      final products = await memory?.all(limit: 100000) ?? const <KnownProduct>[];
      final json = BackupService.encode(
          items: pantry.items, shopping: shop.items, reminders: pantry.reminders, products: products, now: now);
      await files.share(json, BackupService.fileName(now),
          origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.exportFailed('$e'))));
    }
  }

  Future<void> _import(BuildContext context) async {
    final pantry = context.read<PantryStore>();
    final shop = context.read<ShoppingStore>();
    final files = context.read<BackupFiles>();
    final memory = context.read<ProductMemoryDb?>();
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;

    final String? raw;
    try {
      raw = await files.pick();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.openFileFailed('$e'))));
      return;
    }
    if (raw == null || !context.mounted) return;

    final BackupData data;
    try {
      data = BackupService.decode(raw);
    } on BackupFormatException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(switch (e.problem) {
        BackupProblem.notJson => l.backupNotJson,
        BackupProblem.notPantryPal => l.backupNotPantryPal,
        BackupProblem.tooNew => l.backupTooNew,
      })));
      return;
    }

    final pantryCount = l.pantryItemCount(data.items.length);
    final shoppingCount = l.shoppingItemCount(data.shopping.length);
    final summary = data.exportedAt == null
        ? l.restoreSummary(pantryCount, shoppingCount)
        : l.restoreSummaryDated(DateFormat.yMMMd().add_jm().format(data.exportedAt!), pantryCount, shoppingCount);
    final choice = await showDialog<_ImportChoice>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.restoreTitle),
        content: Text([
          summary,
          if (data.products.isNotEmpty) l.rememberedCount(data.products.length),
          l.restoreExplain,
        ].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(d, _ImportChoice.merge), child: Text(l.merge)),
          FilledButton(onPressed: () => Navigator.pop(d, _ImportChoice.replace), child: Text(l.replace)),
        ],
      ),
    );
    if (choice == null) return;

    final replace = choice == _ImportChoice.replace;
    // Settings first, so restored items are scheduled with the restored reminder timing.
    if (replace && data.reminders != null) await pantry.setReminders(data.reminders!);
    final n = await pantry.restore(data.items, replace: replace);
    final s = await shop.restore(data.shopping, replace: replace);
    try {
      await memory?.importAll(data.products, replace: replace);
    } catch (_) {
      // the pantry is restored; a memory problem shouldn't undo that
    }
    messenger.showSnackBar(SnackBar(content: Text(l.restoredSummary(n, s))));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PantryStore>();
    final r = store.reminders;
    final time = TimeOfDay(hour: r.hour, minute: 0);
    final l = context.l10n;
    final language = context.watch<LocaleStore>();
    final appearance = context.watch<ThemeStore?>();
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ReadableWidth(child: ListView(children: [
        if (appearance != null) ...[
          _header(context, l.appearanceHeader),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<ThemeMode>(
              key: const Key('theme-picker'),
              segments: [
                ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(l.themeSystem)),
                ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(l.themeLight)),
                ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(l.themeDark)),
              ],
              selected: {appearance.mode},
              onSelectionChanged: (s) => appearance.setMode(s.first),
            ),
          ),
        ],
        _header(context, l.languageHeader),
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(l.appLanguage),
          trailing: DropdownButton<String?>(
            key: const Key('language-picker'),
            value: language.languageCode,
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l.languageSystem)),
              for (final code in supportedLanguageCodes)
                DropdownMenuItem<String?>(value: code, child: Text(languageNativeName(code))),
            ],
            onChanged: language.setLanguage,
          ),
        ),
        _header(context, l.remindersHeader),
        ListTile(
          title: Text(l.remindBefore),
          trailing: DropdownButton<int>(
            value: r.leadDays,
            items: [for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(l.dayCount(d)))],
            onChanged: (v) => v == null ? null : store.setReminders(r.copyWith(leadDays: v)),
          ),
        ),
        ListTile(
          title: Text(l.timeOfDay),
          trailing: Text(time.format(context)),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time);
            if (t != null) store.setReminders(r.copyWith(hour: t.hour));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l.rescheduleNote),
        ),
        if (context.watch<TasteStore?>() case final taste?) ...[
          _header(context, l.recipeLearningHeader),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l.resetTaste),
            subtitle: Text(l.resetTasteBody),
            enabled: !taste.profile.isEmpty,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text(l.resetTaste),
                  content: Text(l.resetTasteBody),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.resetTasteConfirm)),
                  ],
                ),
              );
              if (ok != true) return;
              await taste.reset();
              messenger.showSnackBar(SnackBar(content: Text(l.resetTasteDone)));
            },
          ),
        ],
        _header(context, l.yourData),
        Builder(
          // Own context so the iPad share popover anchors to this tile.
          builder: (tile) => ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l.exportBackup),
            subtitle: Text(l.exportBackupDesc),
            onTap: () => _export(tile),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: Text(l.importBackup),
          subtitle: Text(l.importBackupDesc),
          onTap: () => _import(context),
        ),
        ListTile(
          leading: const Icon(Icons.psychology_outlined),
          title: Text(l.rememberedProducts),
          subtitle: Text(l.rememberedProductsDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RememberedProductsScreen())),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.backupNote),
        ),
      ])),
    );
  }
}
