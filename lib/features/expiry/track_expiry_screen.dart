import 'package:flutter/material.dart';
import '../../shared/models/pantry_item.dart';
import '../../shared/services/pantry_service.dart';
import '../pantry/add_item_screen.dart';

class TrackExpiryScreen extends StatefulWidget {
  const TrackExpiryScreen({super.key});

  @override
  State<TrackExpiryScreen> createState() => _TrackExpiryScreenState();
}

class _TrackExpiryScreenState extends State<TrackExpiryScreen> {
  final PantryService _pantryService = PantryService();
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<PantryItem> get _allItems => _pantryService.getAllItems();

  List<PantryItem> get _filteredItems {
    var items = _allItems;
    if (_selectedStatus == 'Active') {
      items = items.where((item) => !item.isExpiringSoon && !item.isExpired).toList();
    } else if (_selectedStatus == 'Expiring Soon') {
      items = items.where((item) => item.isExpiringSoon && !item.isExpired).toList();
    } else if (_selectedStatus == 'Expired') {
      items = items.where((item) => item.isExpired).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()) || item.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    items.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return items;
  }

  int get _activeCount => _allItems.where((item) => !item.isExpiringSoon && !item.isExpired).length;
  int get _expiringSoonCount => _allItems.where((item) => item.isExpiringSoon && !item.isExpired).length;
  int get _expiredCount => _allItems.where((item) => item.isExpired).length;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _navigateToAddItem() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen())).then((_) => setState(() {}));
  }

  void _editItem(PantryItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddItemScreen(editItem: item))).then((_) => setState(() {}));
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(icon: Icon(Icons.arrow_back, color: colorScheme.onSurface), onPressed: () => Navigator.pop(context)) : null,
        title: Column(children: [Text('Track Expiry', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)), Text('${_allItems.length} items tracked', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12))]),
        centerTitle: true,
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
              child: Row(children: [_buildStatusChip('All', _allItems.length, colorScheme), const SizedBox(width: 8), _buildStatusChip('Active', _activeCount, colorScheme), const SizedBox(width: 8), _buildStatusChip('Expiring Soon', _expiringSoonCount, colorScheme), const SizedBox(width: 8), _buildStatusChip('Expired', _expiredCount, colorScheme)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [Expanded(child: _buildSummaryCard(icon: Icons.check_circle_outline, iconColor: colorScheme.primary, count: _activeCount, label: 'Active', bgColor: colorScheme.primary.withValues(alpha: 0.1), colorScheme: colorScheme)), const SizedBox(width: 12), Expanded(child: _buildSummaryCard(icon: Icons.warning_amber_rounded, iconColor: Colors.orange, count: _expiringSoonCount, label: 'Expiring Soon', bgColor: Colors.orange.withValues(alpha: 0.1), colorScheme: colorScheme)), const SizedBox(width: 12), Expanded(child: _buildSummaryCard(icon: Icons.cancel_outlined, iconColor: Colors.red, count: _expiredCount, label: 'Expired', bgColor: Colors.red.withValues(alpha: 0.1), colorScheme: colorScheme))]),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 64), const SizedBox(height: 16), Text(_searchQuery.isNotEmpty ? 'No items found' : _selectedStatus == 'All' ? 'No items in pantry' : 'No $_selectedStatus items', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16)), if (_allItems.isEmpty) ...[const SizedBox(height: 8), ElevatedButton(onPressed: _navigateToAddItem, style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary), child: const Text('Add First Item', style: TextStyle(color: Colors.black)))]]))
                : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filteredItems.length, itemBuilder: (context, index) => _buildExpiryItemCard(_filteredItems[index], colorScheme)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _navigateToAddItem, backgroundColor: colorScheme.primary, child: const Icon(Icons.add, color: Colors.black)),
    );
  }

  Widget _buildStatusChip(String status, int count, ColorScheme colorScheme) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? colorScheme.primary : colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(status, style: TextStyle(color: isSelected ? Colors.black : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isSelected ? Colors.black.withValues(alpha: 0.2) : colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text('$count', style: TextStyle(color: isSelected ? Colors.black : colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w600)))]),
      ),
    );
  }

  Widget _buildSummaryCard({required IconData icon, required Color iconColor, required int count, required String label, required Color bgColor, required ColorScheme colorScheme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1)),
      child: Column(children: [Icon(icon, color: iconColor, size: 28), const SizedBox(height: 8), Text('$count', style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)]),
    );
  }

  Widget _buildExpiryItemCard(PantryItem item, ColorScheme colorScheme) {
    Color statusColor = colorScheme.primary;
    if (item.isExpired) { statusColor = Colors.red; } else if (item.isExpiringToday) { statusColor = Colors.red; } else if (item.isExpiringSoon) { statusColor = Colors.orange; }
    return GestureDetector(
      onLongPress: () => _deleteItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: (item.isExpiringSoon || item.isExpired) ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5) : null, boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Icon(_getCategoryIcon(item.category), color: colorScheme.primary, size: 28))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)), const SizedBox(height: 4), Text('${item.quantity} ${item.unit} • ${item.category}', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(item.expiryStatus, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor))), const SizedBox(height: 8), GestureDetector(onTap: () => _editItem(item), child: Icon(Icons.edit_outlined, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 18))])]),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) { case 'Dairy': return Icons.water_drop; case 'Produce': return Icons.eco; case 'Bakery': return Icons.bakery_dining; case 'Meat': return Icons.set_meal; case 'Frozen': return Icons.ac_unit; case 'Beverages': return Icons.local_drink; default: return Icons.inventory_2; }
  }
}
