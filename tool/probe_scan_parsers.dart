// ignore_for_file: avoid_print — a command-line probe: printing is its output.
// Prints what the scan parsers make of messy, real-world input. Paste OCR text or typed
// lists from real use here to tune the date reader and list parser:
//   dart run tool/probe_scan_parsers.dart
import 'package:pantrypal/models/categories.dart';
import 'package:pantrypal/models/quick_list.dart';
import 'package:pantrypal/services/ocr_service.dart';

void main() {
  final now = DateTime(2026, 10, 28);
  const labels = {
    'keyword on the line above': 'PACKED 01/02/2027\nBEST BEFORE\n12/03/2027',
    'OCR letter O for zero': 'EXP 12/03/2O27',
    'OCR l for one': 'MHD 3l.12.2026',
    'spaces around slashes': 'BEST BY 12 / 03 / 2027',
    'hyphenated month name': 'EXP 12-MAR-2027',
    'slashed month name': 'BB 12/MAR/2027',
    'month name, dotted': 'EXP 12.MAR.27',
    'US style w/ comma': 'BEST IF USED BY MAR 12, 2027',
    'two-digit year US': 'SELL BY 03/12/27',
    'lot code + time': 'L6302 14:35 EXP 12/03/27',
  };
  for (final e in labels.entries) {
    final d = OcrService.findDates(e.value, dayFirst: e.key.contains('US') ? false : true, now: now);
    print('${e.key.padRight(28)} → ${d.map((c) => '${c.date.toIso8601String().substring(0, 10)}${c.keyed ? '*' : ''}').join(', ')}');
  }
  print('');
  const lists = ['milk 2x', 'eggs x 12', '1 dozen eggs', 'tomatoes 400g x2', '2 milk 1L', 'Milk (2)', 'MILK'];
  for (final l in lists) {
    final d = parseQuickList(l, today: now);
    print('${l.padRight(28)} → ${d.map((x) => '${x.name} ${x.quantityLabel} ${x.category}').join(' | ')}');
  }
  print('');
  for (final n in ['Peanut butter', 'Butternut squash', 'Buttermilk', 'Coconut milk', 'Sweet potatoes', 'Iced tea', 'Apple sauce']) {
    print('${n.padRight(28)} → ${guessCategory(n)}');
  }
}
