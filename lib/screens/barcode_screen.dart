import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/l10n.dart';
import '../models/barcode.dart';

/// Live barcode scanner.
///
/// Single mode pops with the first code (`String`). Continuous mode keeps
/// scanning and pops with `Map<String, int>` (code → times scanned) on Done.
class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key, this.continuous = false, this.startWithPhoto = false});
  final bool continuous;

  /// Open the photo picker straight away (the user chose "Photos" in the scan sheet).
  /// The live camera stays available behind it.
  final bool startWithPhoto;
  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );
  final _codes = <String, int>{}; // insertion-ordered
  String? _last;
  DateTime _lastAt = DateTime(0);
  bool _done = false;
  bool _torch = false;

  @override
  void initState() {
    super.initState();
    if (widget.startWithPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fromPhoto();
      });
    }
  }

  /// Reads a barcode from a saved photo: handy for glossy or curved packs the live camera
  /// struggles with, and on emulators.
  Future<void> _fromPhoto() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final shot = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (shot == null || !mounted) return;
    BarcodeCapture? capture;
    try {
      capture = await _controller.analyzeImage(shot.path);
    } catch (_) {
      capture = null;
    }
    if (!mounted) return;
    String? code;
    for (final b in capture?.barcodes ?? const <Barcode>[]) {
      if (b.rawValue != null && b.rawValue!.isNotEmpty) {
        code = b.rawValue;
        break;
      }
    }
    if (code == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.noBarcodeInPhoto)));
      return;
    }
    _last = null; // deliberate, like a typed code
    _accept(code);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _total => _codes.values.fold(0, (a, b) => a + b);

  void _accept(String code) {
    if (!widget.continuous) {
      if (_done) return;
      _done = true;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, code);
      return;
    }
    // The camera reports the same code many times a second; count it once per 2 s.
    final now = DateTime.now();
    if (code == _last && now.difference(_lastAt) < const Duration(seconds: 2)) return;
    _last = code;
    _lastAt = now;
    HapticFeedback.selectionClick();
    setState(() => _codes[code] = (_codes[code] ?? 0) + 1);
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final code = b.rawValue;
      if (code != null && code.isNotEmpty) {
        _accept(code);
        return;
      }
    }
  }

  Future<void> _typeCode() async {
    final ctrl = TextEditingController();
    final l = context.l10n;
    final code = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.enterBarcode),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l.barcodeDigitsHint),
          onSubmitted: (v) => Navigator.pop(d, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: Text(l.add)),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    if (!isValidRetailBarcode(code)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.invalidBarcode)));
      return;
    }
    _last = null; // a typed code is always deliberate
    _accept(code);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) setState(() => _torch = !_torch);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.continuous ? l.modeBarcodeRun : l.scanBarcode),
          actions: [
            IconButton(
              tooltip: _torch ? l.torchOff : l.torchOn,
              icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleTorch,
            ),
            IconButton(tooltip: l.barcodeFromPhoto, icon: const Icon(Icons.photo_library_outlined), onPressed: _fromPhoto),
            IconButton(tooltip: l.typeCode, icon: const Icon(Icons.keyboard), onPressed: _typeCode),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
              const IgnorePointer(child: CustomPaint(painter: _ViewfinderPainter())),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Text(
                  widget.continuous ? l.runInstructions : l.singleInstructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 4)]),
                ),
              ),
            ]),
          ),
          if (widget.continuous) _RunPanel(
            codes: _codes,
            total: _total,
            onRemove: (c) => setState(() => _codes.remove(c)),
            onDone: () => Navigator.pop(context, Map<String, int>.of(_codes)),
          ),
        ]),
      );
  }
}

class _RunPanel extends StatelessWidget {
  const _RunPanel({required this.codes, required this.total, required this.onRemove, required this.onDone});
  final Map<String, int> codes;
  final int total;
  final void Function(String) onRemove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final entries = codes.entries.toList().reversed.toList(); // newest first
    final l = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: Text(
                  total == 0 ? l.nothingScanned : l.scannedSummary(total, codes.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton(onPressed: codes.isEmpty ? null : onDone, child: Text(l.review)),
            ]),
            if (entries.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView(shrinkWrap: true, children: [
                  for (final e in entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.qr_code_2),
                      title: Text(e.key),
                      subtitle: e.value > 1 ? Text('×${e.value}') : null,
                      trailing: IconButton(
                        tooltip: l.remove,
                        icon: const Icon(Icons.close),
                        onPressed: () => onRemove(e.key),
                      ),
                    ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Dims the camera preview outside a rounded scan window.
class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.8;
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(center: size.center(Offset(0, -size.height * 0.05)), width: w, height: w * 0.55),
      const Radius.circular(16),
    );
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(window),
    );
    canvas.drawPath(shade, Paint()..color = Colors.black54);
    canvas.drawRRect(
      window,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
