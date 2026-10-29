class ShoppingItem {
  const ShoppingItem({this.id, required this.name, this.checked = false});
  final int? id;
  final String name;
  final bool checked;

  factory ShoppingItem.fromMap(Map<String, Object?> m) =>
      ShoppingItem(id: m['id'] as int?, name: m['name'] as String, checked: (m['checked'] as int) == 1);
}
