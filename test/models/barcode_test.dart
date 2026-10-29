import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/barcode.dart';

void main() {
  test('accepts valid EAN-13, UPC-A and EAN-8 check digits', () {
    for (final c in ['4006381333931', '036000291452', '96385074', '012345678905', '5901234123457']) {
      expect(isValidRetailBarcode(c), isTrue, reason: c);
    }
  });

  test('rejects wrong check digits, wrong lengths and non-digits', () {
    for (final c in ['4006381333932', '1234567', '12345678901', 'ABCDEFGH', '', '4006 381333931']) {
      expect(isValidRetailBarcode(c), isFalse, reason: c);
    }
  });
}
