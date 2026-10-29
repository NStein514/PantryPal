import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/services/ocr_service.dart';

void main() {
  DateTime? parse(String s) => OcrService.parseDate(s);

  test('ISO date', () => expect(parse('BEST BY 2026-12-01'), DateTime(2026, 12, 1)));
  test('US numeric month/day/year', () => expect(parse('EXP 03/15/2026'), DateTime(2026, 3, 15)));
  test('two-digit year', () => expect(parse('USE BY 03.15.26'), DateTime(2026, 3, 15)));
  test('day + month name', () => expect(parse('12 MAR 2026'), DateTime(2026, 3, 12)));
  test('compact month name', () => expect(parse('EXP 15MAR26'), DateTime(2026, 3, 15)));
  test('is case-insensitive', () => expect(parse('exp 2026/01/09'), DateTime(2026, 1, 9)));

  test('prefers the line with an expiry keyword', () {
    expect(parse('PACKED 01/02/2025\nEXP 05/06/2026'), DateTime(2026, 5, 6));
  });
  test('falls back to any date when no keyword is present', () {
    expect(parse('LOT 4411\n08/09/2027'), DateTime(2027, 8, 9));
  });
  test('returns null when no date is present', () => expect(parse('Organic whole milk 1 gal'), isNull));
  test('rejects impossible months/days', () => expect(parse('EXP 13/45/2026'), isNull));

  group('dayFirst', () {
    DateTime? dmy(String s) => OcrService.parseDate(s, dayFirst: true);
    test('reads 03/04/2026 as 3 April', () => expect(dmy('EXP 03/04/2026'), DateTime(2026, 4, 3)));
    test('month names are unaffected', () => expect(dmy('12 MAR 2026'), DateTime(2026, 3, 12)));
    test('Spanish keyword line is preferred', () {
      expect(dmy('LOTE 01/02/2025\nCAD 15/06/2026'), DateTime(2026, 6, 15));
    });
  });

  test('impossible order falls back to the other one', () {
    expect(parse('EXP 25/03/2026'), DateTime(2026, 3, 25)); // month-first can't have month 25
    expect(OcrService.parseDate('EXP 03/25/2026', dayFirst: true), DateTime(2026, 3, 25));
  });

  group('findDates', () {
    final now = DateTime(2026, 10, 28);
    List<DateTime> dates(String s, {bool dayFirst = false}) =>
        [for (final c in OcrService.findDates(s, dayFirst: dayFirst, now: now)) c.date];

    test('month + year only means the end of that month', () {
      final c = OcrService.findDates('BEST BEFORE END 03/2027', now: now).single;
      expect([c.date, c.monthOnly], [DateTime(2027, 3, 31), true]);
      expect(dates('BB MAR 2027'), [DateTime(2027, 3, 31)]);
      expect(dates('EXP 02/2028'), [DateTime(2028, 2, 29)]); // leap year
    });

    test('month-name-first and year-first layouts', () {
      expect(dates('USE BY MAR 15 2027'), [DateTime(2027, 3, 15)]);
      expect(dates('BEST BY MAR 15, 2027'), [DateTime(2027, 3, 15)]);
      expect(dates('EXP 2027 MAR 15'), [DateTime(2027, 3, 15)]);
    });

    test('Spanish, German and French month names', () {
      expect(dates('CAD 15 ENE 2027'), [DateTime(2027, 1, 15)]);
      expect(dates('MHD 03 DEZ 2026'), [DateTime(2026, 12, 3)]);
      expect(dates('MHD 01 MÄRZ 2027'), [DateTime(2027, 3, 1)]);
      expect(dates('DLC 12 FÉVR. 2027'), [DateTime(2027, 2, 12)]);
      expect(dates('À CONSOMMER AVANT 05 AOÛT 2027'), [DateTime(2027, 8, 5)]);
    });

    test('an ISO date is not re-read as a shorter numeric date', () {
      expect(dates('EXP 2026-12-01'), [DateTime(2026, 12, 1)]);
    });

    test('all dates are returned, keyword line first, then latest plausible', () {
      expect(dates('PACKED 01/02/2026 EXP 08/09/2027'), [DateTime(2027, 8, 9), DateTime(2026, 1, 2)]); // keyword binds to the next date
      expect(dates('08/09/2027 EXP'), [DateTime(2027, 8, 9)]); // keyword after the date
      expect(dates('LOT 7 01/02/2026\nEXP 08/09/2027'), [DateTime(2027, 8, 9), DateTime(2026, 1, 2)]);
      expect(dates('01/02/2026 08/09/2027'), [DateTime(2027, 8, 9), DateTime(2026, 1, 2)]); // no keyword: latest
      expect(dates('08/09/1999 01/02/2027'), [DateTime(2027, 1, 2), DateTime(1999, 8, 9)]); // implausible last
    });

    test('rejects dates that do not exist', () {
      expect(dates('EXP 31/04/2027', dayFirst: true), isEmpty);
      expect(dates('EXP 30 FEB 2027'), isEmpty);
    });

    test('duplicates collapse', () => expect(dates('EXP 2027-01-05\nBB 2027-01-05'), [DateTime(2027, 1, 5)]));
  });

  group('day and month without a year', () {
    final now = DateTime(2026, 10, 28);
    List<DateCandidate> found(String s, {bool dayFirst = true}) => OcrService.findDates(s, dayFirst: dayFirst, now: now);

    test('read after a keyword, assuming the next such date', () {
      final c = found('MHD 15.03.').single;
      expect([c.date, c.yearInferred, c.keyed], [DateTime(2027, 3, 15), true, true]); // March has passed: next year
      expect(found('MHD 15.11.').single.date, DateTime(2026, 11, 15));
      expect(found('EXP 25.10.').single.date, DateTime(2026, 10, 25)); // just passed: still this year (expired)
      expect(found('BEST BY 03/15', dayFirst: false).single.date, DateTime(2027, 3, 15));
    });

    test('ignored without a keyword, so sizes are not misread as dates', () {
      expect(found('Milk 1.5 L'), isEmpty);
      expect(found('PACK 12.06.'), isEmpty);
    });

    test('a full date on the line wins over day-month', () {
      expect(found('MHD 15.03.2027').single.yearInferred, isFalse);
    });
  });

  group('real-world label noise (found by running the reader on messy samples)', () {
    final now = DateTime(2026, 10, 28);
    List<String> got(String s, {bool dayFirst = true}) => [
          for (final c in OcrService.findDates(s, dayFirst: dayFirst, now: now))
            '${c.date.toIso8601String().substring(0, 10)}${c.keyed ? '*' : ''}'
        ];

    test('OCR letters inside numbers', () {
      expect(got('EXP 12/03/2O27'), ['2027-03-12*']);
      expect(got('MHD 3l.12.2026'), ['2026-12-31*']);
      expect(got('BB 1O/O3/2027'), ['2027-03-10*']);
    });

    test('spaces around separators', () => expect(got('BEST BY 12 / 03 / 2027'), ['2027-03-12*']));

    test('month names joined by hyphens, slashes or dots', () {
      expect(got('EXP 12-MAR-2027'), ['2027-03-12*']);
      expect(got('BB 12/MAR/2027'), ['2027-03-12*']);
      expect(got('EXP 12.MAR.27'), ['2027-03-12*']);
      expect(got('EXP 2027-MAR-12'), ['2027-03-12*']);
      expect(got('BB MAR-2027'), ['2027-03-31*']);
    });

    test('a keyword alone on a line keys the date below it', () {
      expect(got('PACKED 01/02/2027\nBEST BEFORE\n12/03/2027'), ['2027-03-12*', '2027-02-01']);
      expect(got('BEST BEFORE\n\nLOT 7\n12/03/2027'), ['2027-03-12']); // only the next non-empty line
    });

    test('clean-up leaves sizes, lot codes and words alone', () {
      expect(OcrService.normalizeLine('MILK 1.5L'), 'MILK 1.5L');
      expect(OcrService.normalizeLine('1L.'), '1L.');
      expect(OcrService.normalizeLine('LOT L6302 OIL'), 'LOT L6302 OIL');
      expect(got('MILK 1.5L 2 PACK'), isEmpty);
    });
  });
}
