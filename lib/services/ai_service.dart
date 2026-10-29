import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/categories.dart';
import '../models/unit.dart';

/// Talks to Claude through YOUR backend proxy so the API key never ships in the app.
/// Run with: flutter run --dart-define=AI_PROXY_URL=https://your-proxy/v1/messages
class AiService {
  AiService({http.Client? client, String? url, this.timeout = defaultTimeout})
      : _client = client ?? http.Client(),
        _url = url ?? const String.fromEnvironment('AI_PROXY_URL', defaultValue: 'http://10.0.2.2:8787/v1/messages');

  final http.Client _client;
  final String _url;
  static const _model = 'claude-sonnet-4-6';

  // Keys with what they cover, so the AI files oil under Condiments rather than guessing.
  static final _categories = [for (final c in kCategories) '$c (${kCategoryHints[c]})'].join(', ');
  static final _units = Unit.values.map((u) => u.name).join(',');
  static final _itemSchema = '{"name":string,"category":one of [$_categories],"quantity":number,'
      '"unit":one of [$_units] (count = number of packages or pieces),'
      '"shelf_life_days":int estimate if unopened,"expiry":"YYYY-MM-DD" only if a date is printed and legible, else null}';

  /// How long a request may take before it fails (a receipt read normally takes a few seconds).
  static const defaultTimeout = Duration(seconds: 45);
  final Duration timeout;

  Future<String> _ask(List<Map<String, dynamic>> content, String system, {int maxTokens = 1500}) async {
    final res = await _client.post(Uri.parse(_url),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'max_tokens': maxTokens,
          'system': system,
          'messages': [{'role': 'user', 'content': content}],
        }))
        // Never hang: an unreachable proxy (wrong address, not running) fails with a clear error.
        .timeout(timeout);
    if (res.statusCode != 200) throw Exception('AI error ${res.statusCode}');
    final blocks = jsonDecode(res.body)['content'] as List;
    return blocks.where((b) => b['type'] == 'text').map((b) => b['text']).join();
  }

  /// Asks for names/text in [language] while keeping the fixed enum values parseable.
  static String _lang(String? language) => language == null || language == 'English'
      ? ''
      : ' Write all names, titles and steps in $language, but keep category and unit values exactly as listed.';

  Map<String, dynamic> _image(Uint8List jpeg) =>
      {'type': 'image', 'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': base64Encode(jpeg)}};

  /// Parses JSON from a reply, tolerating ``` fences and stray prose around it.
  dynamic _json(String s) {
    final t = s.replaceAll(RegExp(r'```(json)?'), '').trim();
    try {
      return jsonDecode(t);
    } on FormatException {
      final start = t.indexOf(RegExp(r'[\[{]'));
      final end = t.lastIndexOf(RegExp(r'[\]}]'));
      if (start < 0 || end <= start) rethrow;
      return jsonDecode(t.substring(start, end + 1));
    }
  }

  /// Accepts a bare JSON array or an {"items": [...]} wrapper; drops non-object entries.
  List<Map<String, dynamic>> _items(String text) {
    final v = _json(text);
    final raw = v is Map ? (v['items'] ?? const []) : v;
    return [for (final e in raw as List) if (e is Map) Map<String, dynamic>.from(e)];
  }

  /// Vision: read a grocery receipt and return the food items bought.
  Future<List<Map<String, dynamic>>> parseReceipt(Uint8List jpeg, {String? language}) async {
    final text = await _ask([
      _image(jpeg),
      {'type': 'text', 'text': 'Extract the groceries from this receipt.'},
    ],
        'You read grocery receipts. List only food and drink items that were bought. Expand store abbreviations '
        'into plain product names (e.g. "GV WHL MLK 1GAL" -> "Whole milk"). Merge repeated lines and use the '
        'quantity. Sold-by-weight lines (e.g. "BANANAS 2.31 lb") use that weight and unit; packaged goods use '
        'unit count with the number of packages; do not turn package sizes into units. Skip bags, deposits, discounts, coupons, tax, totals and non-food items. Receipts have no '
        'expiry dates, so expiry is always null. Reply ONLY with a JSON array of $_itemSchema${_lang(language)}',
        maxTokens: 3000);
    return _items(text);
  }



}
