import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/unit.dart';

void main() {
  test('parse accepts names, symbols and common spellings; unknown is count', () {
    expect(Unit.parse('kg'), Unit.kg);
    expect(Unit.parse('Litres'), Unit.l);
    expect(Unit.parse(' LBS. '), Unit.lb);
    expect(Unit.parse('grams'), Unit.g);
    expect(Unit.parse('each'), Unit.count);
    expect(Unit.parse('bushel'), Unit.count);
    expect(Unit.parse(null), Unit.count);
    for (final u in Unit.values) {
      expect(Unit.parse(u.name), u, reason: u.name); // stored values always round-trip
    }
  });

  test('formatNumber trims trailing zeros', () {
    expect(formatNumber(2), '2');
    expect(formatNumber(1.5), '1.5');
    expect(formatNumber(0.25), '0.25');
    expect(formatNumber(1 / 3), '0.33');
    expect(formatNumber(2.999), '3');
  });

  test('formatQuantity', () {
    expect(formatQuantity(3, Unit.count), '×3');
    expect(formatQuantity(500, Unit.g), '500 g');
    expect(formatQuantity(1.5, Unit.l), '1.5 L');
  });

  test('converts within a dimension only', () {
    expect(Unit.kg.convert(1.5, Unit.g), 1500);
    expect(Unit.ml.convert(250, Unit.l), 0.25);
    expect(Unit.lb.convert(1, Unit.oz), closeTo(16, 1e-9));
    expect(Unit.g.canConvertTo(Unit.lb), isTrue);
    expect(Unit.g.canConvertTo(Unit.ml), isFalse);
    expect(Unit.count.canConvertTo(Unit.g), isFalse);
    expect(() => Unit.g.convert(1, Unit.l), throwsArgumentError);
  });

  test('parsePackageSize reads common pack sizes', () {
    ({double quantity, Unit unit})? p(String? s) => parsePackageSize(s);
    expect(p('500 g'), (quantity: 500.0, unit: Unit.g));
    expect(p('1 L'), (quantity: 1.0, unit: Unit.l));
    expect(p('1,5 l'), (quantity: 1.5, unit: Unit.l));
    expect(p('75 cl'), (quantity: 750.0, unit: Unit.ml));
    expect(p('330ml'), (quantity: 330.0, unit: Unit.ml));
    expect(p('16 fl oz'), (quantity: 473.0, unit: Unit.ml));
    expect(p('12 oz'), (quantity: 12.0, unit: Unit.oz));
    expect(p('2 lbs'), (quantity: 2.0, unit: Unit.lb));
    expect(p('1.2 kg'), (quantity: 1.2, unit: Unit.kg));
    expect(p('6 x 330 ml'), (quantity: 6.0, unit: Unit.count));
    expect(p('4×125g'), (quantity: 4.0, unit: Unit.count));
    expect(p('about a dozen'), isNull);
    expect(p('12'), isNull);
    expect(p(null), isNull);
  });

  test('matchPackageSize reports where the size is', () {
    final m = matchPackageSize('Flour 1,5 kg bag')!;
    expect([m.quantity, m.unit, m.start, m.end], [1.5, Unit.kg, 6, 12]);
    expect('Flour 1,5 kg bag'.substring(m.start, m.end), '1,5 kg');
  });
}
