import 'package:flutter/material.dart';
import '../../shared/models/pantry_item.dart';
import '../../shared/services/pantry_service.dart';
import 'add_item_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<PantryItem> get _filteredItems {
    var items = _pantryService.getItemsByCategory(_selectedCategory);
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()) || item.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return items;
  }

  List<PantryItem> get _expiringSoonItems => _filteredItems.where((item) => item.isExpiringSoon || item.isExpired).toList()..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
  List<PantryItem> get _regularItems => _filteredItems.where((item) => !item.isExpiringSoon && !item.isExpired).toList()..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _navigateToAddItem() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen())).then((_) => setState(() {}));
  }

  void _deleteItem(PantryItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Delete Item', style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Remove ${item.name} from pantry?', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)))),
          TextButton(onPressed: () { _pantryService.removeItem(item.id); Navigator.pop(context); setState(() {}); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _editItem(PantryItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddItemScreen(editItem: item))).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(icon: Icon(Icons.arrow_back, color: colorScheme.onSurface), onPressed: () => Navigator.pop(context)) : IconButton(icon: Icon(Icons.menu, color: colorScheme.onSurface), onPressed: () {}),
        title: Column(children: [Text('Pantry Inventory', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)), Text('${_pantryService.expiringSoonCount} items expiring soon', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12))]),
        centerTitle: true,
        actions: [Stack(children: [IconButton(icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface), onPressed: () {}), if (_pantryService.expiringSoonCount > 0) Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))])],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))]),
              child: TextField(controller: _searchController, onChanged: (value) => setState(() => _searchQuery = value), decoration: InputDecoration(hintText: 'Search items...', hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)), prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.4)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['All', ..._pantryService.categories].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? colorScheme.primary : colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Text(category, style: TextStyle(color: isSelected ? Colors.black : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)), if (category == 'All' && isSelected) ...[const SizedBox(width: 4), const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18)]])),
                ));
              }).toList()),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 64), const SizedBox(height: 16), Text('No items in pantry', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16)), const SizedBox(height: 8), ElevatedButton(onPressed: _navigateToAddItem, style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary), child: const Text('Add First Item', style: TextStyle(color: Colors.black)))]))
                : ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                    if (_expiringSoonItems.isNotEmpty) ...[Padding(padding: const EdgeInsets.only(top: 16, bottom: 12), child: Text('Expiring Soon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface))), ..._expiringSoonItems.map((item) => _buildPantryItemCard(item, isExpiring: true))],
                    if (_regularItems.isNotEmpty) ...[Padding(padding: const EdgeInsets.only(top: 24, bottom: 12), child: Text('Full Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface))), ..._regularItems.map((item) => _buildPantryItemCard(item))],
                    const SizedBox(height: 80),
                  ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _navigateToAddItem, backgroundColor: colorScheme.primary, child: const Icon(Icons.add, color: Colors.black)),
    );
  }

  Widget _buildPantryItemCard(PantryItem item, {bool isExpiring = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor = colorScheme.primary;
    if (item.isExpired) { statusColor = Colors.red; } else if (item.isExpiringToday) { statusColor = Colors.red; } else if (item.isExpiringSoon) { statusColor = Colors.orange; }
    
    return GestureDetector(
      onLongPress: () => _deleteItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: isExpiring ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5) : null, boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Icon(_getCategoryIcon(item.category), color: colorScheme.primary, size: 28))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)), const SizedBox(height: 4), Text('${item.quantity} ${item.unit} • ${item.category}', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(item.expiryStatus, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor))), const SizedBox(height: 8), GestureDetector(onTap: () => _editItem(item), child: Icon(Icons.edit_outlined, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 18))]),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) { case 'Dairy': return Icons.water_drop; case 'Produce': return Icons.eco; case 'Bakery': return Icons.bakery_dining; case 'Meat': return Icons.set_meal; case 'Frozen': return Icons.ac_unit; case 'Beverages': return Icons.local_drink; default: return Icons.inventory_2; }
  }
}
