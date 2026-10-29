import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../ui/motion.dart';

/// Three short screens on first launch: what PantryPal does, in plain words. Skippable.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next(int count) {
    if (_page >= count - 1) {
      widget.onDone();
      return;
    }
    final d = Motion.of(context, Motion.medium);
    d == Duration.zero ? _pages.jumpToPage(_page + 1) : _pages.nextPage(duration: d, curve: Motion.emphasized);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      (Icons.document_scanner_outlined, l.introAddTitle, l.introAddBody),
      (Icons.notifications_active_outlined, l.introRemindTitle, l.introRemindBody),
      (Icons.restaurant_menu, l.introCookTitle, l.introCookBody),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: Motion.of(context, Motion.short),
                child: TextButton(onPressed: last ? null : widget.onDone, child: Text(l.introSkip)),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final (icon, title, body) in pages)
                  // Scrolls on short landscape screens; centred at a comfortable width on tablets.
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
                            child: Icon(icon, size: 56, color: scheme.primary),
                          ),
                          const SizedBox(height: 32),
                          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          Text(body,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Page dots: the current one widens.
          Semantics(
            label: l.introPage(_page + 1, pages.length),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < pages.length; i++)
                AnimatedContainer(
                  duration: Motion.of(context, Motion.short),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _next(pages.length),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.short),
                    child: Text(last ? l.introStart : l.introNext, key: ValueKey(last)),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
