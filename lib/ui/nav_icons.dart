import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'motion.dart';
import 'nav_icon_geometry.dart';

enum NavIconKind { pantry, recipes, shopping }

/// A tab icon that acts out its tab when selected: the fridge opens, the fork and knife tap
/// together and lift apart, the cart fills with groceries. Deselecting plays it back quickly.
/// With reduced motion it simply shows the end state.
class AnimatedNavIcon extends StatefulWidget {
  const AnimatedNavIcon({
    super.key,
    required this.kind,
    required this.selected,
    required this.color,
    required this.background,
    this.size = 28,
  });
  final NavIconKind kind;
  final bool selected;
  final Color color;

  /// What's behind the icon: the fridge door and cart basket are filled with it, so they hide
  /// what's behind them.
  final Color background;
  final double size;

  @override
  State<AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<AnimatedNavIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: widget.selected ? 1 : 0,
    duration: switch (widget.kind) {
      NavIconKind.pantry => const Duration(milliseconds: 520),
      NavIconKind.recipes => const Duration(milliseconds: 820),
      NavIconKind.shopping => const Duration(milliseconds: 900),
    },
    reverseDuration: const Duration(milliseconds: 240),
  );

  @override
  void didUpdateWidget(AnimatedNavIcon old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    if (Motion.reduced(context)) {
      _c.value = widget.selected ? 1 : 0;
    } else if (widget.selected) {
      _c.forward(from: 0);
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: NavIconPainter(widget.kind, _c, widget.color, widget.background),
        ),
      );
}

/// Draws the icons in a single colour (the label's), like the rest of the app's icons: depth
/// comes from paler tints of that colour, and overlapping shapes are separated by a thin gap in
/// the background colour.
class NavIconPainter extends CustomPainter {
  NavIconPainter(this.kind, this.progress, this.color, this.background) : super(repaint: progress);
  final NavIconKind kind;
  final Animation<double> progress;
  final Color color;
  final Color background;

  Offset _o(P p) => Offset(p.x, p.y);

  Paint _stroke(double w, [Color? c]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c ?? color;

  Paint _fill(Color c) => Paint()..color = c;

  /// A thin outline in the background colour, so shapes that overlap stay distinct.
  Paint get _gap => _stroke(1.0, background);

  Path _poly(List<P> pts, {bool close = true}) {
    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (final p in pts.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    if (close) path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    // Room above for the sparkle and falling groceries, but nothing spills out of the tab.
    canvas.clipRect(const Rect.fromLTWH(-1, -3.5, 26, 28.5));
    switch (kind) {
      case NavIconKind.pantry:
        _fridge(canvas, fridgeAt(progress.value));
      case NavIconKind.recipes:
        _utensils(canvas, utensilsAt(progress.value));
      case NavIconKind.shopping:
        _cart(canvas, cartAt(progress.value));
    }
    canvas.restore();
  }

  void _fridge(Canvas canvas, FridgeFrame f) {
    for (final ft in f.feet) {
      canvas.drawRRect(RRect.fromLTRBR(ft.l, ft.t, ft.r, ft.b, const Radius.circular(0.9)), _fill(color));
    }
    final body = RRect.fromLTRBR(f.body.l, f.body.t, f.body.r, f.body.b, const Radius.circular(3.2));
    if (f.light > 0) {
      canvas.drawRRect(body, _fill(color.withValues(alpha: 0.24 * f.light))); // the inside, softly lit
      final inside = color.withValues(alpha: f.light);
      for (final (a, b) in f.shelves) {
        canvas.drawLine(_o(a), _o(b), _stroke(1.4, inside));
      }
      canvas.drawLine(Offset(f.body.l, f.divider), Offset(f.body.r, f.divider), _stroke(1.4, inside));
      for (final food in f.food) {
        final paint = _fill(inside);
        final c = _o(food.c), r = food.r;
        switch (food.kind) {
          case 0: // apple with a leaf
            canvas.drawCircle(c, r, paint);
            canvas.drawOval(Rect.fromLTRB(c.dx + 0.2, c.dy - r - 0.9, c.dx + 1.4, c.dy - r + 0.2), paint);
          case 1: // bottle with a neck
            canvas.drawRRect(RRect.fromLTRBR(c.dx - r * 0.62, c.dy - r * 0.7, c.dx + r * 0.62, c.dy + r * 1.15, Radius.circular(r * 0.35)), paint);
            canvas.drawRRect(RRect.fromLTRBR(c.dx - r * 0.28, c.dy - r * 1.2, c.dx + r * 0.28, c.dy - r * 0.5, Radius.circular(r * 0.12)), paint);
          default: // box
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 2, height: r * 1.6), Radius.circular(r * 0.35)), paint);
        }
      }
    }
    canvas.drawRRect(body, _stroke(2));
    // The door, drawn over the inside so it hides what it covers.
    final door = _poly(f.door);
    canvas.drawPath(door, _fill(background));
    canvas.drawPath(door, _stroke(2));
    // Its freezer split follows the door as it swings.
    final d = f.door;
    P on(P a, P b, double y) {
      final u = (y - a.y) / (b.y - a.y);
      return (x: a.x + (b.x - a.x) * u, y: y);
    }
    canvas.drawLine(_o(on(d[0], d[3], f.divider)), _o(on(d[1], d[2], f.divider)), _stroke(1.6));
    for (final (a, b) in f.handles) {
      canvas.drawLine(_o(a), _o(b), _stroke(2.2));
    }
  }

  /// A little four-point twinkle star.
  Path _star(Offset c, double size) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? size : size * 0.32;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _utensils(Canvas canvas, UtensilsFrame u) {
    for (final w in u.twinkles) {
      canvas.drawPath(_star(_o(w.c), w.size), _fill(color));
    }
    for (final line in forkLines) {
      canvas.drawPath(_poly(place(line, u.fork.base, u.fork.angle), close: false), _stroke(2.1));
    }
    canvas.drawPath(_poly(place(knifeHandle, u.knife.base, u.knife.angle), close: false), _stroke(2.6));
    canvas.drawPath(_poly(place(knifeBlade, u.knife.base, u.knife.angle)), _fill(color));
  }

  void _cart(Canvas canvas, CartFrame c) {
    for (final item in c.items) {
      final at = _o(item.c);
      final paint = _fill(color.withValues(alpha: item.opacity));
      // Squash a little on landing: wider and shorter, then back.
      final sx = 1 + 0.12 * item.squash, sy = 1 - 0.16 * item.squash;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(sx, sy);
      switch (item.kind) {
        case Grocery.bread:
          canvas.rotate(item.angle);
          final loaf = RRect.fromRectAndRadius(const Rect.fromLTRB(-5.8, -1.8, 5.8, 1.8), const Radius.circular(1.8));
          canvas.drawRRect(loaf, paint);
          canvas.drawRRect(loaf, _gap);
        case Grocery.milk:
          final bottle = RRect.fromLTRBR(-1.9, -2.4, 1.9, 3.6, const Radius.circular(0.9));
          final neck = RRect.fromLTRBR(-0.9, -3.8, 0.9, -2.2, const Radius.circular(0.35));
          for (final r in [bottle, neck]) {
            canvas.drawRRect(r, paint);
            canvas.drawRRect(r, _gap);
          }
        case Grocery.apple:
          canvas.drawCircle(Offset.zero, 2.7, paint);
          canvas.drawCircle(Offset.zero, 2.7, _gap);
          const leaf = Rect.fromLTRB(0.3, -4.0, 1.9, -2.6);
          canvas.drawOval(leaf, paint);
          canvas.drawOval(leaf, _gap);
      }
      canvas.restore();
    }
    // The cart dips a little as each item lands.
    canvas.save();
    canvas.translate(0, c.bounce);
    final basket = _poly(c.basket);
    canvas.drawPath(basket, _fill(background)); // in front, so the groceries sit inside it
    canvas.drawPath(basket, _stroke(2));
    canvas.drawLine(const Offset(5.6, 11.6), const Offset(20.1, 11.6), _stroke(1.4)); // a slat
    canvas.drawPath(_poly(c.handle, close: false), _stroke(2));
    for (final w in c.wheels) {
      canvas.drawCircle(_o(w.c), w.r, _fill(color));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(NavIconPainter old) =>
      old.kind != kind || old.color != color || old.background != background || old.progress != progress;
}
