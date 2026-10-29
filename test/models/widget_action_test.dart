import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/widget_action.dart';

void main() {
  test('round-trips the used-one link', () {
    final uri = WidgetAction.useOneUri(12);
    expect(uri.toString(), 'pantrypal://used?id=12');
    expect(WidgetAction.parse(uri), const WidgetAction.useOne(12));
  });

  test('accepts the extra query iOS adds', () {
    expect(WidgetAction.parse(Uri.parse('pantrypal://used?id=7&homeWidget')), const WidgetAction.useOne(7));
  });

  test('ignores anything that is not a valid used-one link', () {
    for (final s in [
      'pantrypal://recipes?homeWidget',
      'pantrypal://pantry',
      'pantrypal://used',
      'pantrypal://used?id=',
      'pantrypal://used?id=abc',
      'pantrypal://used?id=0',
      'pantrypal://used?id=-3',
      'https://used?id=3',
      'otherapp://used?id=3',
    ]) {
      expect(WidgetAction.parse(Uri.parse(s)), isNull, reason: s);
    }
    expect(WidgetAction.parse(null), isNull);
  });
}
