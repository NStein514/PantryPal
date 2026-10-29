import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/ui/nav_icon_geometry.dart';

void main() {
  test('fridge: closed and dark when not selected, door open and light on when selected', () {
    final closed = fridgeAt(0), open = fridgeAt(1);
    expect(closed.light, 0);
    expect(closed.door[1].x, closed.body.r); // the door covers the front
    expect(closed.handles, hasLength(2));
    expect(open.light, 1);
    expect(open.door[1].x, lessThan(open.body.l)); // swung past the hinge
    expect(open.handles, isEmpty); // seen edge-on
    // The door swings open with a small bounce: a little past fully open, then back.
    final widest = [for (var t = 0.0; t <= 1.0; t += 0.05) fridgeAt(t).door[1].x].reduce(math.min);
    expect(widest, lessThan(open.door[1].x));
    expect(open.door[1].x - widest, lessThan(3)); // a small bounce (about 11°), not a flap
  });

  test('utensils: they meet at the clink without crossing, then lift and spread', () {
    final rest = utensilsAt(0);
    expect([rest.fork.angle, rest.knife.angle], [0, 0]);
    // At the clink, the tip of the fork's outer prong reaches the top of the blade's back edge.
    final clink = utensilsAt(0.3);
    final prong = place([forkLines[1].last], clink.fork.base, clink.fork.angle).single;
    final blade = place([knifeBlade[1]], clink.knife.base, clink.knife.angle).single;
    expect(blade.x - prong.x, inInclusiveRange(-0.5, 0.5));
    expect(utensilsAt(0.4).spark.strength, greaterThan(0.2));
    expect(utensilsAt(0.4).twinkles, hasLength(3)); // little stars at the clink
    expect(utensilsAt(0).twinkles, isEmpty);
    final end = utensilsAt(1);
    expect(end.fork.angle, lessThan(0)); // fork leans left
    expect(end.knife.angle, greaterThan(0)); // knife leans right
    expect(end.fork.base.y, lessThan(rest.fork.base.y)); // held up
    expect(end.spark.strength, closeTo(0, 1e-9));
  });

  test('cart: empty, then four groceries land inside the icon', () {
    expect(cartAt(0).items, isEmpty);
    final full = cartAt(1);
    expect(full.items.map((i) => i.kind).toSet(), Grocery.values.toSet());
    expect(full.items.every((i) => i.squash.abs() < 1e-9), isTrue); // settled
    expect(full.bounce.abs(), lessThan(1e-9));
    // Somewhere along the way the cart dips as things land.
    expect([for (var t = 0.0; t <= 1.0; t += 0.02) cartAt(t).bounce].reduce(math.max), greaterThan(0.3));
    for (var t = 0.0; t <= 1.0; t += 0.05) {
      for (final i in cartAt(t).items) {
        expect(i.c.y, greaterThanOrEqualTo(-3.5), reason: 't=$t ${i.kind}'); // never above the icon's box
        expect(i.c.x, inInclusiveRange(0, 24));
      }
    }
    for (final i in full.items) {
      expect(i.opacity, 1);
      expect(i.c.y, lessThan(full.basket.first.y)); // sitting up out of the basket
    }
  });

  test('eases end where they should', () {
    for (final f in [easeOutCubic, easeInOutCubic, easeOutBack]) {
      expect(f(0), closeTo(0, 1e-9));
      expect(f(1), closeTo(1, 1e-9));
    }
    expect(phase(0.5, 0.25, 0.75), 0.5);
    expect(math.max(phase(-1, 0, 1), 0), 0);
  });
}
