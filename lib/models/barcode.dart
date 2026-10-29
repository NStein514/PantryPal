/// True for an EAN-8, UPC-A (12), EAN-13 or GTIN-14 code with a correct check digit.
/// Used for typed codes; the camera scanner already validates what it reads.
bool isValidRetailBarcode(String code) {
  if (!RegExp(r'^(\d{8}|\d{12,14})$').hasMatch(code)) return false;
  final digits = [for (final c in code.split('')) int.parse(c)];
  final check = digits.removeLast();
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    final d = digits[digits.length - 1 - i]; // from the right, next to the check digit
    sum += i.isEven ? d * 3 : d;
  }
  return (10 - sum % 10) % 10 == check;
}
