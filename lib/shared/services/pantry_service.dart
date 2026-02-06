import '../models/pantry_item.dart';

class PantryService {
  static final PantryService _instance = PantryService._internal();
  factory PantryService() => _instance;
  PantryService._internal();

  final List<PantryItem> _items = [];

  List<PantryItem> getItems() => List.unmodifiable(_items);

  void addItem(PantryItem item) {
    _items.add(item);
  }

  void addMultipleItems(List<PantryItem> items) {
    _items.addAll(items);
  }

  void updateItem(PantryItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  List<PantryItem> getItemsByCategory(String category) {
    if (category == 'All') return _items;
    return _items.where((item) => item.category == category).toList();
  }

  int get expiringSoonCount => _items.where((item) => item.isExpiringSoon || item.isExpired).length;
  int get totalItems => _items.length;

  List<String> get categories => [
    'Dairy', 'Produce', 'Bakery', 'Meat', 'Frozen', 
    'Beverages', 'Grains', 'Spices', 'Other'
  ];
}
