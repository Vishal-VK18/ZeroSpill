import '../models/pantry_item.dart';
import 'pantry_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final PantryService _pantryService = PantryService();

  List<PantryItem> getItemsNeedingNotification() {
    return _pantryService.getItems().where((item) => item.daysUntilExpiry <= 7 && item.daysUntilExpiry >= 0).toList()..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
  }

  List<PantryItem> getExpiredItems() {
    return _pantryService.getItems().where((item) => item.daysUntilExpiry < 0).toList()..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
  }

  List<NotificationMessage> generateNotificationMessages() {
    final items = getItemsNeedingNotification();
    return items.map((item) {
      String message;
      NotificationPriority priority;
      if (item.isExpiringToday) {
        message = '⚠️ ${item.name} expires TODAY! Use it now to avoid waste.';
        priority = NotificationPriority.urgent;
      } else if (item.daysUntilExpiry == 1) {
        message = '🔔 ${item.name} expires TOMORROW! Plan to use it soon.';
        priority = NotificationPriority.high;
      } else if (item.daysUntilExpiry <= 3) {
        message = '📅 ${item.name} expires in ${item.daysUntilExpiry} days. Consider using it this week.';
        priority = NotificationPriority.medium;
      } else {
        message = '📌 ${item.name} expires in ${item.daysUntilExpiry} days.';
        priority = NotificationPriority.low;
      }
      return NotificationMessage(itemId: item.id, itemName: item.name, message: message, daysUntilExpiry: item.daysUntilExpiry, priority: priority);
    }).toList();
  }

  String generateDailySummary() {
    final items = getItemsNeedingNotification();
    if (items.isEmpty) return 'All items are fresh! No expiring items this week.';
    final expiring = items.where((i) => i.isExpiringToday).length;
    final soon = items.where((i) => i.daysUntilExpiry > 0 && i.daysUntilExpiry <= 3).length;
    final later = items.where((i) => i.daysUntilExpiry > 3 && i.daysUntilExpiry <= 7).length;
    final parts = <String>[];
    if (expiring > 0) parts.add('$expiring item${expiring > 1 ? 's' : ''} expiring today');
    if (soon > 0) parts.add('$soon item${soon > 1 ? 's' : ''} expiring in 1-3 days');
    if (later > 0) parts.add('$later item${later > 1 ? 's' : ''} expiring this week');
    return '🛒 Pantry Alert: ${parts.join(', ')}.';
  }
}

enum NotificationPriority { urgent, high, medium, low }

class NotificationMessage {
  final String itemId;
  final String itemName;
  final String message;
  final int daysUntilExpiry;
  final NotificationPriority priority;

  NotificationMessage({required this.itemId, required this.itemName, required this.message, required this.daysUntilExpiry, required this.priority});
}
