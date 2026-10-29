import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/ui/breakpoints.dart';

void main() {
  test('window size classes follow Material 3', () {
    expect([320.0, 599.0, 600.0, 839.0, 840.0, 1400.0].map(WindowSize.of).toList(),
        [WindowSize.compact, WindowSize.compact, WindowSize.medium, WindowSize.medium, WindowSize.expanded, WindowSize.expanded]);
  });

  test('columns: as many as fit, at least one, capped', () {
    expect(columnsFor(390), 1); // phone
    expect(columnsFor(692), 2); // exactly two 340s + gap
    expect(columnsFor(691), 1);
    expect(columnsFor(1200), 3);
    expect(columnsFor(5000), 3);
    expect(columnsFor(5000, max: 4), 4);
    expect(columnsFor(0), 1);
  });
}
