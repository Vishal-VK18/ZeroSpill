/// Estimates expiry dates from manufacturing dates based on product category
/// and industry-standard shelf-life rules
class ShelfLifeEstimator {
  /// Estimate expiry date from manufacturing date based on product category
  static DateTime? estimateExpiryFromMfg(
    DateTime mfgDate, {
    String? productCategory,
    String? productName,
  }) {
    // Get shelf-life in days based on category or product name
    final int shelfLifeDays = _getShelfLifeDays(
      productCategory,
      productName,
    );
    
    final estimatedExpiry = mfgDate.add(Duration(days: shelfLifeDays));
    
    // Ensure estimated expiry is in the future
    final now = DateTime.now();
    if (estimatedExpiry.isBefore(now)) {
      return null; // Don't return past dates
    }
    
    return estimatedExpiry;
  }
  
  /// Get shelf-life days based on product category or name
  static int _getShelfLifeDays(String? category, String? name) {
    final cat = category?.toLowerCase() ?? '';
    final prod = name?.toLowerCase() ?? '';
    final combined = '$cat $prod';
    
    // Dairy products: 7-14 days
    if (_containsAny(combined, [
      'dairy', 'milk', 'yogurt', 'yoghurt', 'curd',
      'paneer', 'cheese', 'butter', 'ghee', 'cream'
    ])) {
      return 14;
    }
    
    // Bakery products: 3-7 days
    if (_containsAny(combined, [
      'bakery', 'bread', 'bun', 'cake', 'pastry',
      'cookie', 'biscuit', 'muffin'
    ])) {
      return 7;
    }
    
    // Fresh produce: 5-10 days
    if (_containsAny(combined, [
      'vegetable', 'fruit', 'salad', 'greens',
      'fresh', 'produce'
    ])) {
      return 7;
    }
    
    // Meat & Poultry: 3-5 days (refrigerated)
    if (_containsAny(combined, [
      'meat', 'chicken', 'mutton', 'fish', 'seafood',
      'poultry', 'pork', 'beef'
    ])) {
      return 5;
    }
    
    // Frozen foods: 3-12 months
    if (_containsAny(combined, ['frozen'])) {
      return 180; // 6 months average
    }
    
    // Canned/Packaged: 6-24 months
    if (_containsAny(combined, [
      'canned', 'packaged', 'preserved', 'dry',
      'packet', 'instant', 'ready'
    ])) {
      return 365; // 12 months
    }
    
    // Beverages: 3-6 months
    if (_containsAny(combined, [
      'beverage', 'drink', 'juice', 'soda',
      'water', 'tea', 'coffee'
    ])) {
      return 120; // 4 months
    }
    
    // Condiments & Sauces: 6-12 months
    if (_containsAny(combined, [
      'sauce', 'ketchup', 'mayonnaise', 'pickle',
      'chutney', 'jam', 'jelly', 'condiment'
    ])) {
      return 270; // 9 months
    }
    
    // Grains & Cereals: 6-12 months
    if (_containsAny(combined, [
      'grain', 'cereal', 'rice', 'wheat', 'flour',
      'dal', 'lentil', 'pulse', 'oats'
    ])) {
      return 270; // 9 months
    }
    
    // Snacks: 3-6 months
    if (_containsAny(combined, [
      'snack', 'chips', 'namkeen', 'mixture',
      'nuts', 'crackers'
    ])) {
      return 120; // 4 months
    }
    
    // Default: 3 months for unknown products
    return 90;
  }
  
  /// Check if text contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Get human-readable shelf-life description
  static String getShelfLifeDescription(int days) {
    if (days < 7) {
      return '$days days';
    } else if (days < 30) {
      final weeks = (days / 7).round();
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else if (days < 365) {
      final months = (days / 30).round();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = (days / 365).round();
      return '$years year${years > 1 ? 's' : ''}';
    }
  }
}
