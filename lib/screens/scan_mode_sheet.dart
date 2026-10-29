import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/product_memory_db.dart';
import '../l10n/l10n.dart';
import '../models/scan_draft.dart';
import '../models/scan_mode.dart';
import '../services/ai_service.dart';
import '../services/batch_scan.dart';
import '../services/product_lookup_service.dart';
import 'barcode_screen.dart';
import 'batch_review_screen.dart';
import 'scan_screen.dart';

IconData scanModeIcon(ScanMode m) => switch (m) {
      ScanMode.barcode => Icons.qr_code_scanner,
      ScanMode.dateLabel => Icons.event_available,
      ScanMode.manual => Icons.edit_note,
      ScanMode.barcodeBatch => Icons.playlist_add,
      ScanMode.receipt => Icons.receipt_long,
    };

/// Shows the mode picker, then runs the chosen scan flow.
Future<void> showScanModeSheet(BuildContext context) async {
  final choice = await showModalBottomSheet<(ScanMode, ImageSource)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const ScanModeSheet(),
  );
  if (choice == null || !context.mounted) return;
  await startScan(context, choice.$1, source: choice.$2);
}

/// Runs one scan flow. Single-item modes open the add form (which starts the
/// capture itself); batch modes capture first, then open the review screen.
Future<void> startScan(BuildContext context, ScanMode mode, {ImageSource source = ImageSource.camera}) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;

  if (!mode.batch) {
    await nav.push(MaterialPageRoute<void>(builder: (_) => ScanScreen(initialMode: mode, imageSource: source)));
    return;
  }

  final String title;
  final Future<List<ScanDraft>> Function() load;
  if (mode == ScanMode.barcodeBatch) {
    final codes = await nav.push<Map<String, int>>(
        MaterialPageRoute(
            builder: (_) => BarcodeScreen(continuous: true, startWithPhoto: source == ImageSource.gallery)));
    if (codes == null || codes.isEmpty || !context.mounted) return;
    final lookup = context.read<ProductLookupService>();
    final memory = context.read<ProductMemoryDb?>();
    final language = Localizations.localeOf(context).languageCode;
    title = l.reviewScanned;
    load = () => draftsFromBarcodes(codes, lookup, memory: memory, language: language);
  } else {
    final shot = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 2400, imageQuality: 85);
    if (shot == null || !context.mounted) return;
    final ai = context.read<AiService>();
    final bytes = await shot.readAsBytes();
    title = l.reviewReceipt; // the receipt is the only photo-based batch mode
    load = () async {
      final raw = await ai.parseReceipt(bytes, language: l.aiLanguage);
      return [for (final m in raw) ScanDraft.fromAi(m)]..removeWhere((d) => d.name.isEmpty);
    };
  }

  final added = await nav.push<int>(MaterialPageRoute(builder: (_) => BatchReviewScreen(title: title, load: load)));
  if (added != null && added > 0) {
    messenger.showSnackBar(SnackBar(content: Text(l.addedToPantry(added))));
  }
}

class ScanModeSheet extends StatefulWidget {
  const ScanModeSheet({super.key});
  @override
  State<ScanModeSheet> createState() => _ScanModeSheetState();
}

class _ScanModeSheetState extends State<ScanModeSheet> {
  var _source = ImageSource.camera;

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );

  Widget _tile(ScanMode m) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(scanModeIcon(m)),
        ),
        title: Text(scanModeLabel(context.l10n, m)),
        subtitle: Text(scanModeDescription(context.l10n, m)),
        trailing: m.usesPhoto && _source == ImageSource.gallery ? const Icon(Icons.photo_library_outlined, size: 18) : null,
        onTap: () => Navigator.pop(context, (m, _source)),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(l.addToPantry, style: Theme.of(context).textTheme.titleLarge),
                  SegmentedButton<ImageSource>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: ImageSource.camera,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l.sourceCamera)),
                      ButtonSegment(
                          value: ImageSource.gallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l.sourcePhotos)),
                    ],
                    selected: {_source},
                    onSelectionChanged: (s) => setState(() => _source = s.first),
                  ),
                ],
              ),
            ),
            _header(l.oneItem),
            for (final m in ScanMode.values.where((m) => !m.batch)) _tile(m),
            _header(l.severalAtOnce),
            for (final m in ScanMode.values.where((m) => m.batch)) _tile(m),
            const SizedBox(height: 8),
          ]),
        ),
      );
  }
}
