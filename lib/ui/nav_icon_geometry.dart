import 'dart:math' as math;

/// Geometry for the animated tab icons, as plain numbers in a 24 × 24 box, for animation
/// progress `t` from 0 (tab not selected) to 1 (selected). Kept free of Flutter so it can be
/// tested and previewed on its own; `nav_icons.dart` paints it.

typedef P = ({double x, double y});

P _p(double x, double y) => (x: x, y: y);
double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;

/// 0→1 over [start, end] of the timeline.
double phase(double t, double start, double end) => _clamp01((t - start) / (end - start));

double easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
double easeInOutCubic(double t) => t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

/// Overshoots a little and settles (a soft landing).
double easeOutBack(double t) {
  const c1 = 1.70158, c3 = c1 + 1;
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
}

// -------------------------------------------------------------------------------------------------
// Pantry: a fridge whose door swings open and the light comes on.

class FridgeFrame {
  FridgeFrame({
    required this.feet,
    required this.body,
    required this.divider,
    required this.door,
    required this.handles,
    required this.light,
    required this.shelves,
    required this.food,
  });

  /// Two little feet under the cabinet (left, top, right, bottom).
  final List<({double l, double t, double r, double b})> feet;

  /// Cabinet: left, top, right, bottom.
  final ({double l, double t, double r, double b}) body;
  final double divider; // freezer / fridge split
  /// The door as a quadrilateral (hinge top, free top, free bottom, hinge bottom).
  final List<P> door;
  final List<(P, P)> handles; // drawn on the door while it faces us
  final double light; // 0..1 interior light
  final List<(P, P)> shelves;
  final List<({P c, double r, int kind})> food; // kind 0 round, 1 bottle, 2 box
}

FridgeFrame fridgeAt(double t) {
  const l = 5.0, top = 2.0, r = 19.0, b = 20.5, w = r - l;
  // Swings open with a small bounce past fully open, then settles.
  final open = easeOutBack(_clamp01(t));
  final a = open * 110 * math.pi / 180; // door angle
  final xe = l + w * math.cos(a); // free edge, crosses the hinge as it swings past 90°
  final grow = 1.8 * math.sin(a); // perspective: the free edge comes towards us
  final door = [_p(l, top), _p(xe, top - grow), _p(xe, b + grow), _p(l, b)];
  final facing = math.cos(a);
  final handles = <(P, P)>[
    if (facing > 0.25) ...[
      (_p(l + w * 0.82 * facing, 4.5), _p(l + w * 0.82 * facing, 7.0)),
      (_p(l + w * 0.82 * facing, 11.0), _p(l + w * 0.82 * facing, 14.5)),
    ],
  ];
  return FridgeFrame(
    feet: const [(l: 6.6, t: 20.5, r: 8.4, b: 22.6), (l: 15.6, t: 20.5, r: 17.4, b: 22.6)],
    body: (l: l, t: top, r: r, b: b),
    divider: 9,
    door: door,
    handles: handles,
    light: _clamp01((_clamp01(t) - 0.1) / 0.5),
    shelves: [(_p(l + 1.2, 14.3), _p(r - 1.2, 14.3))],
    // Few, bold shapes: at real size more would blur together.
    food: [
      (c: _p(9.7, 12.0), r: 2.0, kind: 0), // apple
      (c: _p(14.9, 11.4), r: 2.3, kind: 1), // bottle
      (c: _p(12.0, 17.4), r: 2.2, kind: 2), // box
    ],
  );
}

// -------------------------------------------------------------------------------------------------
// Recipes: fork and knife tap together, then lift apart, held up ready to eat.

class UtensilsFrame {
  UtensilsFrame({required this.fork, required this.knife, required this.spark});

  /// Where the handle ends (pivot) and the tilt in radians (positive leans right).
  final ({P base, double angle}) fork;
  final ({P base, double angle}) knife;

  /// 0..1 strength of the little "clink" sparkle, and where it is.
  final ({P at, double strength}) spark;

  /// The sparkle as tiny four-point stars: centre and size.
  List<({P c, double size})> get twinkles => [
        if (spark.strength > 0.05)
          for (final (dx, dy, s) in const [(-3.4, -0.6, 1.5), (3.4, -1.4, 1.2), (0.0, -3.4, 1.8)])
            (c: _p(spark.at.x + dx, spark.at.y + dy - spark.strength * 0.6), size: s * spark.strength),
      ];
}

/// Length from handle end to tip, in the 24 box.
const utensilLength = 17.0;

UtensilsFrame utensilsAt(double t) {
  t = _clamp01(t);
  const forkX = 8.5, knifeX = 15.5, restY = 21.5, liftedY = 19.0;
  // Lean in until the fork's outer prong just touches the blade (heads have width, so not the
  // centre lines): forkX + 2.6 + L sin a = knifeX - 1.3 - L sin a, with a hair of overlap.
  final meet = math.asin((knifeX - forkX - 2.6 - 1.3 + 0.3) / (2 * utensilLength));
  const apart = 14 * math.pi / 180;
  double angle;
  double y = restY;
  if (t <= 0.3) {
    angle = meet * easeInOutCubic(phase(t, 0, 0.3)); // lean in
  } else if (t <= 0.42) {
    angle = meet * (1 - 0.12 * math.sin(math.pi * phase(t, 0.3, 0.42))); // the clink, a tiny recoil
  } else {
    final p = easeOutBack(phase(t, 0.42, 1)); // lift and spread
    angle = _lerp(meet, -apart, p);
    y = _lerp(restY, liftedY, p);
  }
  final tipY = y - utensilLength * math.cos(angle);
  return UtensilsFrame(
    fork: (base: _p(forkX, y), angle: angle),
    knife: (base: _p(knifeX, y), angle: -angle),
    spark: (
      at: _p((forkX + knifeX) / 2, tipY - 1.2),
      strength: t < 0.26 ? 0 : math.sin(math.pi * phase(t, 0.26, 0.6)).clamp(0, 1).toDouble(),
    ),
  );
}

/// Fork outline in its own frame (base at 0,0, pointing up), as polylines.
const forkLines = <List<P>>[
  [(x: 0, y: 0), (x: 0, y: -9)], // handle
  [(x: -2.6, y: -17), (x: -2.6, y: -11.2), (x: -1.6, y: -9.6), (x: 0, y: -9), (x: 1.6, y: -9.6), (x: 2.6, y: -11.2), (x: 2.6, y: -17)],
  [(x: 0, y: -17), (x: 0, y: -10)], // middle prong
];

/// Knife: handle line, and the blade as a closed shape.
const knifeHandle = <P>[(x: 0, y: 0), (x: 0, y: -7)];
const knifeBlade = <P>[
  (x: -1.3, y: -7), (x: -1.3, y: -16.0), (x: -0.6, y: -17.2), (x: 0.6, y: -17.4), (x: 1.8, y: -16.4), (x: 2.6, y: -14.6), (x: 2.6, y: -7),
];

/// [pts] rotated by [angle] around the origin and moved to [base].
List<P> place(List<P> pts, P base, double angle) {
  final c = math.cos(angle), s = math.sin(angle);
  return [for (final p in pts) _p(base.x + p.x * c - p.y * s, base.y + p.x * s + p.y * c)];
}

// -------------------------------------------------------------------------------------------------
// Shopping: groceries drop into the cart until it's full.

enum Grocery { bread, milk, apple }

class CartFrame {
  CartFrame({required this.basket, required this.handle, required this.wheels, required this.items, this.bounce = 0});

  /// How far the whole cart dips as groceries land (in icon units; down is positive).
  final double bounce;
  final List<P> basket; // closed polygon, drawn in front of the groceries
  final List<P> handle;
  final List<({P c, double r})> wheels;
  final List<({Grocery kind, P c, double angle, double opacity, double squash})> items;
}

CartFrame cartAt(double t) {
  t = _clamp01(t);
  // Each item lands in turn; together they fill the cart.
  const plan = <(Grocery, double, double, double, double)>[
    // kind, final x, final y, angle, start
    (Grocery.bread, 9.8, 4.4, -0.55, 0.0),
    (Grocery.milk, 18.4, 3.6, 0.0, 0.2),
    (Grocery.apple, 14.6, 5.0, 0, 0.4),
  ];
  const fall = 0.36, settle = 0.14;
  // A soft bump: 0 → 1 → 0 just after an item lands.
  double bump(double start) => math.sin(math.pi * phase(t, start + fall * 0.55, start + fall * 0.55 + settle));
  var bounce = 0.0;
  for (final (_, _, _, _, start) in plan) {
    bounce += 0.7 * bump(start);
  }
  return CartFrame(
    basket: [_p(4.2, 7.6), _p(21.2, 7.6), _p(19.0, 15.6), _p(6.8, 15.6)],
    handle: [_p(1.0, 3.6), _p(3.2, 3.6), _p(6.8, 15.6), _p(7.2, 17.6), _p(19.4, 17.6)],
    wheels: [(c: _p(8.8, 20.6), r: 1.8), (c: _p(17.6, 20.6), r: 1.8)],
    bounce: bounce,
    items: [
      for (final (kind, x, y, angle, start) in plan)
        if (phase(t, start, start + fall) > 0)
          (
            kind: kind,
            // Drops in from just above the cart (the painter clips to the icon's box).
            c: _p(x, _lerp(-2.5, y, easeOutCubic(phase(t, start, start + fall * 0.55))) + 0.7 * bump(start)),
            angle: angle,
            opacity: _clamp01(phase(t, start, start + fall) * 5),
            squash: bump(start), // 0 normal, 1 most squashed
          ),
    ],
  );
}
