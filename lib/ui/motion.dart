import 'package:flutter/material.dart';

/// Animation timings, in one place, that switch off when the user asks the system to reduce
/// motion (iOS "Reduce Motion", Android "Remove animations").
class Motion {
  Motion._();

  static const short = Duration(milliseconds: 150); // small state changes: counts, checkboxes
  static const medium = Duration(milliseconds: 250); // swaps: tabs, filters
  static const long = Duration(milliseconds: 400); // container transforms
  static const emphasized = Curves.easeOutCubic;

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero when the user prefers reduced motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// Keeps every page alive (like IndexedStack) but cross-fades between them, so switching tabs
/// feels continuous without losing scroll positions, typed text or loaded data.
///
/// Only the current page is interactive. During the fade the previous page is still drawn
/// underneath; once it ends, hidden pages go fully offstage (not painted, not hit-tested, not in
/// the accessibility tree) with their tickers paused, exactly like IndexedStack. Each child keeps
/// the same wrapper widgets at all times, so its state is never rebuilt from scratch.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  late final Animation<double> _in = CurvedAnimation(parent: _c, curve: Motion.emphasized);
  late final Animation<double> _out = ReverseAnimation(_in);
  static const _hidden = AlwaysStoppedAnimation<double>(0);
  static const _shown = AlwaysStoppedAnimation<double>(1);
  int? _leaving;

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _leaving = old.index;
    _c.duration = Motion.of(context, Motion.medium);
    _c.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) setState(() => _leaving = null);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fading = _leaving != null && _c.isAnimating;
    return Stack(fit: StackFit.expand, children: [
      for (var i = 0; i < widget.children.length; i++)
        Offstage(
          offstage: i != widget.index && !(fading && i == _leaving),
          child: TickerMode(
            enabled: i == widget.index,
            child: IgnorePointer(
              ignoring: i != widget.index,
              child: ExcludeSemantics(
                excluding: i != widget.index,
                child: FadeTransition(
                  opacity: i == widget.index
                      ? (fading ? _in : _shown)
                      : (fading && i == _leaving ? _out : _hidden),
                  child: widget.children[i],
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// Fades and slides a list item in the first time it appears; [index] staggers a batch
/// (capped, so long lists don't wait). Shown at once when motion is reduced.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.medium);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.emphasized);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 6)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _t,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_t),
          child: widget.child,
        ),
      );
}
