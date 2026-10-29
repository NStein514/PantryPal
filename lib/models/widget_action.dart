/// An action triggered by a button on the home-screen widget, carried as a URI
/// (`pantrypal://used?id=12`). Parsing is strict because the URI arrives from outside the app.
class WidgetAction {
  const WidgetAction.useOne(this.itemId);

  /// Pantry item id (the SQLite row id).
  final int itemId;

  static const scheme = 'pantrypal';
  static const _useOneHost = 'used';

  /// The link the widget's "used one" button sends for [itemId].
  static Uri useOneUri(int itemId) => Uri(scheme: scheme, host: _useOneHost, queryParameters: {'id': '$itemId'});

  /// The action in [uri], or null for anything else (opening the app, recipes, junk).
  static WidgetAction? parse(Uri? uri) {
    if (uri == null || uri.scheme != scheme || uri.host != _useOneHost) return null;
    final id = int.tryParse(uri.queryParameters['id'] ?? '');
    return id == null || id <= 0 ? null : WidgetAction.useOne(id);
  }

  @override
  bool operator ==(Object other) => other is WidgetAction && other.itemId == itemId;
  @override
  int get hashCode => itemId.hashCode;
  @override
  String toString() => 'WidgetAction.useOne($itemId)';
}
