import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  final String id;
  final String name;
  final String category;
  final DateTime expiryDate;
  final int quantity;
  final String unit;
  final String? imageAsset;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    required this.quantity,
    this.unit = 'Units',
    this.imageAsset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'imageAsset': imageAsset,
    };
  }

  factory PantryItem.fromMap(Map<String, dynamic> map, String documentId) {
    return PantryItem(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      expiryDate: map['expiryDate'] is Timestamp 
          ? (map['expiryDate'] as Timestamp).toDate() 
          : DateTime.tryParse(map['expiryDate'].toString()) ?? DateTime.now(),
      quantity: map['quantity']?.toInt() ?? 1,
      unit: map['unit'] ?? 'Units',
      imageAsset: map['imageAsset'],
    );
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpiringSoon => daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringToday => daysUntilExpiry == 0;

  String get expiryStatus {
    if (isExpired) return 'EXPIRED';
    if (isExpiringToday) return 'EXPIRING TODAY';
    if (daysUntilExpiry == 1) return '1 DAY LEFT';
    if (isExpiringSoon) return '$daysUntilExpiry DAYS LEFT';
    if (daysUntilExpiry <= 14) return '$daysUntilExpiry DAYS LEFT';
    return '${(daysUntilExpiry / 7).floor()} WEEKS LEFT';
  }

  PantryItem copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? expiryDate,
    int? quantity,
    String? unit,
    String? imageAsset,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}
