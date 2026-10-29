import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// One date found on a label.
class DateCandidate {
  const DateCandidate(this.date,
      {this.keyed = false, this.monthOnly = false, this.yearInferred = false, this.position = 0});
  final DateTime date;

  /// On a line with an expiry keyword (EXP, BEST BY, CAD, MHD, DLC…).
  final bool keyed;

  /// Printed as month + year only (03/2027, MAR 2027); [date] is the last day of that month.
  final bool monthOnly;

  /// Printed without a year ("MHD 15.03."); the next such date from today was assumed.
  final bool yearInferred;

  /// Character offset in the recognised text (keyed candidates keep reading order).
  final int position;

  @override
  String toString() => 'DateCandidate($date, keyed: $keyed, monthOnly: $monthOnly)';
}

/// What OCR read from a label: the raw text (shown when no date is found) and the dates in it.
class LabelReading {
  const LabelReading(this.text, this.dates);
  final String text;
  final List<DateCandidate> dates;
}

/// On-device OCR (works offline) + expiration-date parsing.
class OcrService {
  final _recognizer = TextRecognizer();

  /// The label's text and every date in it, best guess first (see [findDates]).
  /// [dayFirst]: read 03/04/2026 as 3 April (most of the world) instead of March 4 (US).
  Future<LabelReading> readLabel(String imagePath, {bool dayFirst = false}) async {
    final result = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    return LabelReading(result.text, findDates(result.text, dayFirst: dayFirst));
  }

  Future<List<DateCandidate>> readDates(String imagePath, {bool dayFirst = false}) async =>
      (await readLabel(imagePath, dayFirst: dayFirst)).dates;

  /// The best date on the label, or null.
  Future<DateTime?> readExpiry(String imagePath, {bool dayFirst = false}) async {
    final dates = await readDates(imagePath, dayFirst: dayFirst);
    return dates.isEmpty ? null : dates.first.date;
  }

  static final _keyword =
      RegExp(r'EXP|BEST|USE BY|SELL BY|BB|CAD|CONSUMIR|MHD|MINDESTENS|DLC|DLUO|À CONSOMMER|A CONSOMMER|VERBRAUCH');

  /// Month abbreviations in English, Spanish, German and French (upper case).
  static const _monthTokens = {
    'JANV': 1, 'JAN': 1, 'ENE': 1,
    'FÉVR': 2, 'FEVR': 2, 'FÉV': 2, 'FEV': 2, 'FEB': 2,
    'MARS': 3, 'MAR': 3, 'MRZ': 3, 'MÄR': 3,
    'AVR': 4, 'APR': 4, 'ABR': 4,
    'MAY': 5, 'MAI': 5,
    'JUIN': 6, 'JUN': 6,
    'JUIL': 7, 'JUL': 7,
    'AOÛ': 8, 'AOU': 8, 'AUG': 8, 'AGO': 8,
    'SEPT': 9, 'SEP': 9,
    'OCT': 10, 'OKT': 10,
    'NOV': 11,
    'DÉC': 12, 'DEC': 12, 'DIC': 12, 'DEZ': 12,
  };

  static final String _mon = () {
    final keys = _monthTokens.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    return '(${keys.join('|')})[A-ZÀ-Ý]*\\.?';
  }();

  // Applied in this order; each match is blanked out so later, looser patterns can't re-read it.
  static final _iso = RegExp(r'(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})(?!\d)');
  static const _sep = r'[\s\-/.]*'; // "12 MAR 2027", "12-MAR-2027", "12/MAR/2027", "12.MAR.27"
  static final _yMonD = RegExp('(20\\d{2})$_sep$_mon$_sep(\\d{1,2})(?!\\d)');
  static final _monDY = RegExp('\\b$_mon$_sep(\\d{1,2}),?\\s+(\\d{4})(?!\\d)');
  static final _dMonY = RegExp('(?<!\\d)(\\d{1,2})$_sep$_mon$_sep(\\d{4}|\\d{2})(?!\\d)');
  static final _num = RegExp(r'(?<!\d)(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})(?!\d)');
  static final _monY = RegExp('\\b$_mon$_sep(20\\d{2})(?!\\d)');
  static final _mY = RegExp(r'(?<![\d/.-])(0?[1-9]|1[0-2])[-/.](20\d{2})(?!\d)');
  // Day and month only ("MHD 15.03."): too ambiguous alone, so kept only right after a keyword.
  static final _dm = RegExp(r'(?<![\d/.,-])(\d{1,2})[./](\d{1,2})\.?(?![\d/,-])');

  // OCR misreads inside numbers: O→0 and I/L/| → 1, only where a digit is next to them.
  static final _ocrDigit = RegExp(r'(?<=[\d/.\-])[OIL|](?=\d)|(?<=\d)[OIL|](?=[/.\-]\d)');
  // Spaces OCR inserts around date separators: "12 / 03 / 2027" → "12/03/2027".
  static final _spacedSep = RegExp(r'(\d)\s*([/.\-])\s*(?=\d)');

  /// Undoes common OCR noise in one upper-cased line before looking for dates.
  static String normalizeLine(String line) {
    String fixDigits(String s) =>
        s.replaceAllMapped(_ocrDigit, (m) => m[0] == 'O' ? '0' : '1');
    var s = fixDigits(line);
    s = s.replaceAllMapped(_spacedSep, (m) => '${m[1]}${m[2]}');
    return fixDigits(s); // again: joining can bring a misread next to a digit
  }

  /// The best date in [raw], or null. Kept for callers that only want one.
  static DateTime? parseDate(String raw, {bool dayFirst = false, DateTime? now}) {
    final all = findDates(raw, dayFirst: dayFirst, now: now);
    return all.isEmpty ? null : all.first.date;
  }

  /// All dates in [raw], best first:
  /// 1. dates right after an expiry keyword (in reading order); "PACKED 01/02 EXP 08/09" keys
  ///    only the second date. If a line's keyword comes after its dates, they all count,
  /// 2. then plausible dates (up to 2 years ago … 15 years ahead) over implausible ones,
  /// 3. then, without a keyword, the latest date first (expiry usually follows packing).
  /// Numeric dates are month/day unless [dayFirst]; an impossible order falls back to the other.
  static List<DateCandidate> findDates(String raw, {bool dayFirst = false, DateTime? now}) {
    final today = now ?? DateTime.now();
    final found = <DateCandidate>[];
    var offset = 0;
    var keywordAbove = false; // "BEST BEFORE" alone on a line keys the first date on the next
    for (final rawLine in raw.toUpperCase().split('\n')) {
      final original = normalizeLine(rawLine);
      var line = original;
      final onLine = <(int start, int end, DateCandidate c)>[];

      void scan(RegExp re, DateCandidate? Function(RegExpMatch m) build) {
        for (final m in re.allMatches(line).toList()) {
          final c = build(m);
          if (c != null) onLine.add((m.start, m.end, c));
          line = line.replaceRange(m.start, m.end, ' ' * (m.end - m.start)); // blank it either way
        }
      }

      int n(RegExpMatch m, int g) => int.parse(m[g]!);
      int mon(RegExpMatch m, int g) => _monthTokens[m[g]!]!;
      DateCandidate? day(int y, int mo, int d) {
        final dt = _mk(y, mo, d);
        return dt == null ? null : DateCandidate(dt);
      }

      // Next occurrence of month/day: this year, or next year if it passed over a month ago.
      DateCandidate? noYear(int mo, int d) {
        final y = today.year;
        final dt = _mk(y, mo, d);
        if (dt == null) return null;
        final next = dt.isBefore(today.subtract(const Duration(days: 31))) ? _mk(y + 1, mo, d) : dt;
        return next == null ? null : DateCandidate(next, yearInferred: true);
      }

      DateCandidate? endOfMonth(int y, int mo) {
        if (y < 100) y += 2000;
        if (mo < 1 || mo > 12) return null;
        return DateCandidate(DateTime(y, mo + 1, 0), monthOnly: true);
      }

      scan(_iso, (m) => day(n(m, 1), n(m, 2), n(m, 3)));
      scan(_yMonD, (m) => day(n(m, 1), mon(m, 2), n(m, 3)));
      scan(_monDY, (m) => day(n(m, 3), mon(m, 1), n(m, 2)));
      scan(_dMonY, (m) => day(n(m, 3), mon(m, 2), n(m, 1)));
      scan(_num, (m) {
        final a = n(m, 1), b = n(m, 2), y = n(m, 3);
        return dayFirst ? (day(y, b, a) ?? day(y, a, b)) : (day(y, a, b) ?? day(y, b, a));
      });
      scan(_monY, (m) => endOfMonth(n(m, 2), mon(m, 1)));
      scan(_mY, (m) => endOfMonth(n(m, 2), n(m, 1)));
      scan(_dm, (m) {
        final a = n(m, 1), b = n(m, 2);
        return dayFirst ? (noYear(b, a) ?? noYear(a, b)) : (noYear(a, b) ?? noYear(b, a));
      });

      // A date is keyed when a keyword sits between the previous date (or line start) and it.
      onLine.sort((a, b) => a.$1.compareTo(b.$1));
      var segmentStart = 0;
      final keyedFlags = <bool>[];
      for (final (start, end, _) in onLine) {
        keyedFlags.add(_keyword.hasMatch(original.substring(segmentStart, start)));
        segmentStart = end;
      }
      final lineHasKeyword = _keyword.hasMatch(original);
      if (keywordAbove && keyedFlags.isNotEmpty && !keyedFlags.first) keyedFlags[0] = true;
      final anyKeyed = keyedFlags.any((k) => k);
      for (var i = 0; i < onLine.length; i++) {
        final (start, _, c) = onLine[i];
        final keyed = keyedFlags[i] || (lineHasKeyword && !anyKeyed); // "05/06/2026 EXP"
        if (c.yearInferred && !keyedFlags[i]) continue; // "1.5" next to nothing is not a date
        found.add(DateCandidate(c.date,
            keyed: keyed, monthOnly: c.monthOnly, yearInferred: c.yearInferred, position: offset + start));
      }
      if (original.trim().isNotEmpty) keywordAbove = lineHasKeyword && onLine.isEmpty;
      offset += original.length + 1;
    }

    bool plausible(DateTime d) =>
        d.isAfter(today.subtract(const Duration(days: 730))) && d.isBefore(today.add(const Duration(days: 365 * 15)));
    found.sort((a, b) {
      if (a.keyed != b.keyed) return a.keyed ? -1 : 1;
      final pa = plausible(a.date), pb = plausible(b.date);
      if (pa != pb) return pa ? -1 : 1;
      if (a.keyed) return a.position.compareTo(b.position);
      return b.date.compareTo(a.date);
    });
    final seen = <DateTime>{};
    return [for (final c in found) if (seen.add(c.date)) c];
  }

  static DateTime? _mk(int y, int mo, int d) {
    if (y < 100) y += 2000;
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final dt = DateTime(y, mo, d);
    return dt.month == mo ? dt : null; // rejects 31 April, 30 February…
  }
}
