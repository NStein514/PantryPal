import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_memory_db.dart';
import '../l10n/l10n.dart';
import '../models/known_product.dart';
import '../models/quick_list.dart';
import 'batch_review_screen.dart';
import '../ui/layout.dart';

/// "Add several at once": type a list, review it, save it. Pops with the number added.
class QuickListScreen extends StatefulWidget {
  const QuickListScreen({super.key});
  @override
  State<QuickListScreen> createState() => _QuickListScreenState();
}

class _QuickListScreenState extends State<QuickListScreen> {
  final _text = TextEditingController();
  Map<String, KnownProduct> _known = const {};

  @override
  void initState() {
    super.initState();
    _loadKnown();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _loadKnown() async {
    try {
      final all = await context.read<ProductMemoryDb?>()?.all() ?? const <KnownProduct>[];
      if (mounted) setState(() => _known = {for (final k in all) k.key: k});
    } catch (_) {}
  }

  Future<void> _review() async {
    final l = context.l10n;
    final drafts = parseQuickList(_text.text, known: _known);
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.quickListEmpty)));
      return;
    }
    final added = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => BatchReviewScreen(title: l.reviewList, load: () async => drafts)),
    );
    if (added != null && added > 0 && mounted) Navigator.pop(context, added);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.quickListTitle)),
      body: ReadableWidth(child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          key: const Key('quick-list'),
          controller: _text,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(hintText: l.quickListHint, border: const OutlineInputBorder()),
        ),
      )),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _review, icon: const Icon(Icons.checklist), label: Text(l.review)),
        ),
      ),
    );
  }
}
