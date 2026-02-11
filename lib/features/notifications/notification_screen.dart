import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/pantry_item.dart';
import '../../shared/services/app_settings_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('pantry')
            .orderBy('expiryDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          // Fetch notifyBeforeDays (default to 3 if not set, or use AppSettings)
          // Ideally we use the per-item setting if available, but for grouping we need a standard.
          // The user request says: "IF daysLeft <= notifyBeforeDays".
          // Let's use the global setting for consistency in this view, 
          // or we can check each item's specific setting if we stored it.
          // Since we didn't strictly enforce storing it on all items yet, global is safer.
          final int notifyDays = AppSettingsService().expiryAlertDays;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final docs = snapshot.data!.docs;
          final List<PantryItem> expiredItems = [];
          final List<PantryItem> todayItems = [];
          final List<PantryItem> soonItems = [];

          for (var doc in docs) {
            final item = PantryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            final expiry = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
            final difference = expiry.difference(today).inDays;

            if (expiry.isBefore(today)) {
              expiredItems.add(item);
            } else if (expiry.isAtSameMomentAs(today)) {
              todayItems.add(item);
            } else if (difference <= notifyDays) {
              soonItems.add(item);
            }
          }

          if (expiredItems.isEmpty && todayItems.isEmpty && soonItems.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expiredItems.isNotEmpty) ...[
                _buildSectionHeader(context, 'Expired', Colors.red),
                ...expiredItems.map((item) => _buildNotificationCard(context, item, NotificationType.expired)),
                const SizedBox(height: 24),
              ],
              if (todayItems.isNotEmpty) ...[
                _buildSectionHeader(context, 'Expires Today', Colors.green), // User requested Green accent for Today
                ...todayItems.map((item) => _buildNotificationCard(context, item, NotificationType.today)),
                const SizedBox(height: 24),
              ],
              if (soonItems.isNotEmpty) ...[
                _buildSectionHeader(context, 'Expiring Soon', Colors.orange),
                ...soonItems.map((item) => _buildNotificationCard(context, item, NotificationType.soon)),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).hintColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "🎉 No expiring products!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, PantryItem item, NotificationType type) {
    final colorScheme = Theme.of(context).colorScheme;
    Color accentColor;
    String statusText;
    IconData icon;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    final diff = expiry.difference(today).inDays;

    switch (type) {
      case NotificationType.expired:
        accentColor = Colors.red;
        statusText = 'Expired ${diff.abs()} days ago';
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.today:
        accentColor = Colors.green; // Per user request
        statusText = 'Expires Today';
        icon = Icons.event_available;
        break;
      case NotificationType.soon:
        accentColor = Colors.orange;
        statusText = 'Expires in $diff days';
        icon = Icons.timer_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
             Text(
                '${item.expiryDate.day}/${item.expiryDate.month}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

enum NotificationType { expired, today, soon }
