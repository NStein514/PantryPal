import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/product_memory_db.dart';
import '../l10n/l10n.dart';
import '../models/categories.dart';
import '../models/known_product.dart';
import '../models/pantry_item.dart';
import '../models/scan_mode.dart';
import '../models/unit.dart';
import '../services/batch_scan.dart';
import '../services/ocr_service.dart';
import '../services/product_lookup_service.dart';
import '../state/pantry_store.dart';
import '../widgets/category_style.dart';
import '../widgets/quantity_field.dart';
import '../widgets/scan_errors.dart';
import 'barcode_screen.dart';
import 'quick_list_screen.dart';
import '../ui/layout.dart';

/// Where the current expiry date came from (decides the note under the date).
/// confirmed = read from the label or chosen by the user; history = estimated from past items.
enum _DateSource { none, confirmed, history }

/// Add or edit a single item. With [initialMode] it starts that scan as soon as it opens.
///
/// Every mode fills the same form, and each one checks the user's own product memory
/// ([ProductMemoryDb]) so things they've added before are recognised and pre-filled.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.existing, this.initialMode, this.imageSource = ImageSource.camera});
  final PantryItem? existing;
  final ScanMode? initialMode;

  /// Camera or photo library for the AI photo and date-label scans.
  final ImageSource imageSource;
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _qty = TextEditingController(text: '1');
  String _category = 'Other';
  bool _categoryTouched = false; // set by the user or a scan: stop guessing from the name
  Unit _unit = Unit.count;
  DateTime? _expiry;
  _DateSource _dateSource = _DateSource.none;
  bool _busy = false;

  // Scan results shown in the card at the top.
  String? _found;
  String? _scannedCode; // remembered with the item, so the next scan of it is instant
  List<DateCandidate> _dateOptions = const [];
  bool _offerDateScan = false;

  List<KnownProduct> _known = const [];
  Map<String, KnownProduct> _knownByKey = const {};

  bool get _estimated => _dateSource == _DateSource.history;
  ProductMemoryDb? get _memory => context.read<ProductMemoryDb?>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _qty.text = formatNumber(e.quantity);
      _unit = e.unit;
      _category = normalizeCategory(e.category);
      _categoryTouched = true;
      _expiry = e.expiry;
      if (e.expiry != null) _dateSource = _DateSource.confirmed;
    }
    _name.addListener(_onNameChanged);
    _loadKnown();
    final mode = widget.initialMode;
    if (mode != null && mode != ScanMode.manual) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runMode(mode);
      });
    }
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _name.dispose();
    _nameFocus.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _loadKnown() async {
    final memory = _memory;
    if (memory == null) return;
    try {
      final known = await memory.all();
      if (mounted) setState(() => _setKnown(known));
    } catch (_) {
      // memory unavailable: autocomplete just stays empty
    }
  }

  void _setKnown(List<KnownProduct> known) {
    _known = known;
    _knownByKey = {for (final k in known) k.key: k};
  }

  /// Typing a name suggests a category until the user (or a scan) picks one.
  void _onNameChanged() {
    if (_categoryTouched) return;
    final guess = _knownByKey[KnownProduct.keyFor(_name.text)]?.category ?? guessCategory(_name.text);
    if (guess != null && guess != _category) setState(() => _category = guess);
  }

  Future<void> _runMode(ScanMode m) => switch (m) {
        ScanMode.barcode => _scanBarcode(),
        ScanMode.dateLabel => _scanDate(),
        _ => Future<void>.value(),
      };

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) _snack(friendlyScanError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static Future<T?> _quiet<T>(Future<T?>? Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  DateTime _inDays(int n) {
    final t = DateTime.now();
    return DateTime(t.year, t.month, t.day + n);
  }

  /// Fills the form from a remembered product (autocomplete pick, known barcode, photo match).
  void _applyKnown(KnownProduct k) {
    setState(() {
      _categoryTouched = true; // before the name changes, so the listener doesn't re-guess
      if (_name.text != k.name) _name.text = k.name;
      _category = k.category;
      _unit = k.unit;
      _qty.text = formatNumber(k.quantity);
      if (_expiry == null && k.shelfDays != null) {
        _expiry = _inDays(k.shelfDays!);
        _dateSource = _DateSource.history;
      }
    });
  }

  // ---- Barcode ------------------------------------------------------------------------------

  Future<void> _scanBarcode() => _run(() async {
        final code = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => BarcodeScreen(startWithPhoto: widget.imageSource == ImageSource.gallery)),
        );
        if (code == null || !mounted) return;
        final l = context.l10n;
        final language = Localizations.localeOf(context).languageCode;
        final lookup = context.read<ProductLookupService>();
        final memory = _memory;
        setState(() {
          _scannedCode = code;
        });

        // 1. The user's own memory: instant, offline, and knows products OFF doesn't.
        final known = await _quiet(() => memory?.byBarcode(code));
        if (!mounted) return;
        if (known != null) {
          _applyKnown(known);
          setState(() {
            _found = l.barcodeRemembered(known.name);
            _offerDateScan = _dateSource != _DateSource.confirmed;
          });
          return;
        }

        // 2. Open Food Facts, through the local cache (works offline for anything seen before).
        final info = await lookupWithCache(code, lookup, memory: memory, language: language);
        if (!mounted) return;
        if (info == null) {
          setState(() => _found = null);
          _snack(l.barcodeNotFoundLearn(code));
          _nameFocus.requestFocus();
          return;
        }
        final history = await _quiet(() => memory?.byName(info.name));
        if (!mounted) return;
        setState(() {
          _categoryTouched = true;
          _name.text = info.name;
          _category = history?.category ?? info.category;
          if (info.unit != null && info.quantity != null) {
            _unit = info.unit!;
            _qty.text = formatNumber(info.quantity!);
          }
          if (_expiry == null && history?.shelfDays != null) {
            _expiry = _inDays(history!.shelfDays!);
            _dateSource = _DateSource.history;
          }
          final detail = [
            if (info.brand != null) info.brand!,
            if (info.unit != null && info.quantity != null) formatQuantity(info.quantity!, info.unit!),
          ].join(', ');
          _found = l.foundFromBarcode(detail.isEmpty ? info.name : '${info.name} ($detail)');
          _offerDateScan = _dateSource != _DateSource.confirmed; // a barcode never carries the date
        });
      });

  // ---- Date label (on-device OCR) -----------------------------------------------------------

  Future<void> _scanDate() => _run(() async {
        final shot = await _picker.pickImage(source: widget.imageSource);
        if (shot == null || !mounted) return;
        final ocr = context.read<OcrService>();
        final l = context.l10n;
        final reading = await ocr.readLabel(shot.path, dayFirst: dateFormatIsDayFirst());
        final dates = reading.dates;
        if (!mounted) return;
        if (dates.isEmpty) {
          await _noDateFound(reading.text);
          return;
        }
        setState(() {
          _useDate(dates.first);
          _dateOptions = dates.length > 1 ? dates.take(5).toList() : const [];
          _found = l.readDate(_describeDate(l, dates.first));
          _offerDateScan = false;
        });
      });

  /// No date in the photo: show what OCR did read, so the user can see why and pick by hand.
  Future<void> _noDateFound(String text) async {
    final l = context.l10n;
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.noDateFoundTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text.trim().isEmpty ? l.nothingReadable : l.noDateFoundBody),
          if (text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: SelectableText(text.trim(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(d, 'retry'), child: Text(l.tryAgain)),
          FilledButton(onPressed: () => Navigator.pop(d, 'pick'), child: Text(l.pickDate)),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'retry') {
      // _run is still busy with this scan; start the next one after it finishes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanDate();
      });
    } else if (choice == 'pick') {
      final d = await showDatePicker(
          context: context, initialDate: _expiry ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
      if (d != null) _setExpiry(d);
    }
  }

  void _useDate(DateCandidate c) {
    _expiry = c.date;
    _dateSource = _DateSource.confirmed;
  }

  String _describeDate(AppLocalizations l, DateCandidate c) => c.monthOnly
      ? l.endOfMonth(DateFormat.yMMM().format(c.date))
      : c.yearInferred
          ? l.dateYearAssumed(DateFormat.yMMMd().format(c.date))
          : DateFormat.yMMMd().format(c.date);

  // ---- Form ---------------------------------------------------------------------------------

  void _bumpQty(int direction) {
    final current = double.tryParse(_qty.text.replaceAll(',', '.')) ?? 1;
    final next = current + direction * _unit.step;
    _qty.text = formatNumber(next < _unit.step ? _unit.step : (next * 1000).roundToDouble() / 1000);
  }

  void _setExpiry(DateTime? d, {_DateSource source = _DateSource.confirmed}) => setState(() {
        _expiry = d;
        _dateSource = d == null ? _DateSource.none : source;
      });

  /// Saves the item and teaches the product memory. Returns false if nothing was saved.
  Future<bool> _persist() async {
    final l = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack(l.nameFirst);
      _nameFocus.requestFocus();
      return false;
    }
    final store = context.read<PantryStore>();
    final memory = _memory;
    final parsed = double.tryParse(_qty.text.replaceAll(',', '.'));
    final raw = parsed == null || parsed <= 0 ? 1.0 : parsed;
    final qty = _unit.isCount ? raw.roundToDouble().clamp(1.0, 999.0).toDouble() : raw;
    final e = widget.existing;
    final PantryItem item;
    if (e != null) {
      item = e.copyWith(
          name: name, category: _category, quantity: qty, unit: _unit, expiry: _expiry, clearExpiry: _expiry == null);
      await store.update(item);
    } else {
      item = PantryItem(name: name, category: _category, quantity: qty, unit: _unit, expiry: _expiry);
      await store.add(item);
    }
    await _quiet(() => memory?.remember(item, barcode: _scannedCode, expiryEstimated: _estimated));
    return true;
  }

  Future<void> _save() async {
    if (await _persist() && mounted) Navigator.pop(context);
  }

  Future<void> _saveAndAddAnother() async {
    final name = _name.text.trim();
    if (!await _persist() || !mounted) return;
    _snack(context.l10n.savedItem(name));
    _name.clear();
    _qty.text = '1';
    setState(() {
      _category = 'Other';
      _categoryTouched = false;
      _unit = Unit.count;
      _expiry = null;
      _dateSource = _DateSource.none;
      _found = null;
      _scannedCode = null;
      _dateOptions = const [];
      _offerDateScan = false;
    });
    _nameFocus.requestFocus();
    _loadKnown(); // includes what was just saved
  }

  Future<void> _addSeveral() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final added = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const QuickListScreen()));
    if (added == null || added == 0 || !mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l.addedToPantry(added))));
  }

  Future<void> _delete() async {
    await context.read<PantryStore>().remove(widget.existing!);
    if (mounted) Navigator.pop(context);
  }

  // ---- UI -----------------------------------------------------------------------------------

  Widget _resultCard(AppLocalizations l, ColorScheme scheme) {
    final hasResult = _found != null || _offerDateScan;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.fillAutomatically, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
                onPressed: _busy ? null : _scanBarcode, icon: const Icon(Icons.qr_code_scanner), label: Text(l.modeBarcode)),
            FilledButton.tonalIcon(
                onPressed: _busy ? null : _scanDate, icon: const Icon(Icons.event_available), label: Text(l.scanDate)),
          ]),
          if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
          if (hasResult && !_busy) ...[
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_found != null) ...[
                Icon(Icons.check_circle, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_found != null) Text(_found!),
                ]),
              ),
            ]),
            if (_offerDateScan)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _scanDate,
                  icon: const Icon(Icons.event_available),
                  label: Text(l.addExpiryNow),
                ),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _nameField(AppLocalizations l) => RawAutocomplete<KnownProduct>(
        textEditingController: _name,
        focusNode: _nameFocus,
        displayStringForOption: (k) => k.name,
        optionsBuilder: (value) {
          final q = KnownProduct.keyFor(value.text);
          if (q.isEmpty) return const Iterable<KnownProduct>.empty();
          return _known.where((k) => k.key.contains(q)).take(6);
        },
        onSelected: _applyKnown,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
          key: const Key('item-name'),
          controller: controller,
          focusNode: focusNode,
          autofocus: widget.initialMode == ScanMode.manual,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.fieldName, border: const OutlineInputBorder()),
          onSubmitted: (_) => onSubmitted(),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
              child: ListView(padding: EdgeInsets.zero, shrinkWrap: true, children: [
                for (final k in options)
                  ListTile(
                    dense: true,
                    leading: Icon(categoryIcon(k.category)),
                    title: Text(k.name),
                    subtitle: Text([
                      categoryLabel(l, k.category),
                      k.quantityLabel,
                      if (k.shelfDays != null) l.usuallyLasts(k.shelfDays!),
                    ].join(' · ')),
                    onTap: () => onSelected(k),
                  ),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final usual = _knownByKey[KnownProduct.keyFor(_name.text)]?.shelfDays;
    final adding = widget.existing == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(adding ? l.addItem : l.editItem),
        actions: [
          if (adding)
            IconButton(tooltip: l.addSeveral, icon: const Icon(Icons.playlist_add), onPressed: _addSeveral),
          if (!adding) IconButton(tooltip: l.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ReadableWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
        _resultCard(l, scheme),
        const SizedBox(height: 20),
        _nameField(l),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('item-category'),
          isExpanded: true, // fills the row; long names shorten instead of overflowing
          value: _category,
          decoration: InputDecoration(labelText: l.fieldCategory, border: const OutlineInputBorder()),
          items: [
            for (final c in kCategories)
              DropdownMenuItem(
                value: c,
                child: Row(children: [
                  Icon(categoryIcon(c), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(categoryLabel(l, c), overflow: TextOverflow.ellipsis)),
                ]),
              ),
          ],
          onChanged: (v) => setState(() {
            _category = v ?? _category;
            _categoryTouched = true;
          }),
        ),
        const SizedBox(height: 12),
        // Label above, controls below: wraps instead of overflowing with large text or narrow screens.
        Text(l.fieldQuantity, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton.outlined(tooltip: l.less, onPressed: () => _bumpQty(-1), icon: const Icon(Icons.remove)),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: TextField(
                controller: _qty,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(tooltip: l.more, onPressed: () => _bumpQty(1), icon: const Icon(Icons.add)),
          ]),
          UnitDropdown(value: _unit, onChanged: (u) => setState(() => _unit = u)),
        ]),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline), borderRadius: BorderRadius.circular(4)),
          title: Text(_expiry == null ? l.setExpiry : l.expiresOn(DateFormat.yMMMd().format(_expiry!))),
          subtitle: switch (_dateSource) {
            _DateSource.history => Text(l.estimatedFromHistory),
            _ => null,
          },
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_expiry != null)
              IconButton(tooltip: l.clearDate, icon: const Icon(Icons.clear), onPressed: () => _setExpiry(null)),
            const Icon(Icons.event),
          ]),
          onTap: () async {
            final d = await showDatePicker(
                context: context, initialDate: _expiry ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
            if (d != null) _setExpiry(d);
          },
        ),
        if (_dateOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.otherDatesFound, style: Theme.of(context).textTheme.bodySmall),
          Wrap(spacing: 6, children: [
            for (final c in _dateOptions)
              ChoiceChip(
                label: Text(_describeDate(l, c)),
                selected: _expiry == c.date,
                onSelected: (_) => setState(() => _useDate(c)),
              ),
          ]),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          if (usual != null)
            ActionChip(
              avatar: const Icon(Icons.history, size: 18),
              label: Text(l.usuallyLasts(usual)),
              onPressed: () => _setExpiry(_inDays(usual), source: _DateSource.history),
            ),
          for (final (label, days) in [(l.quick3Days, 3), (l.quick1Week, 7), (l.quick2Weeks, 14), (l.quick1Month, 30)])
            ActionChip(label: Text(label), onPressed: () => _setExpiry(_inDays(days))),
        ]),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_alt),
          label: Text(adding ? l.saveToPantry : l.saveChanges),
        ),
        if (adding) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _saveAndAddAnother,
            icon: const Icon(Icons.playlist_add),
            label: Text(l.saveAndAddAnother),
          ),
        ],
      ])),
    );
  }
}
