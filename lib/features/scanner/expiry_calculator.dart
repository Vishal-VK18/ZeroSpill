class ExpiryCalculator {
  static final ExpiryCalculator _instance = ExpiryCalculator._internal();
  factory ExpiryCalculator() => _instance;
  ExpiryCalculator._internal();

  final Map<String, int> _shelfLifeDays = {
    'tomato': 5,
    'tomatoes': 5,
    'onion': 7,
    'onions': 7,
    'potato': 14,
    'potatoes': 14,
    'carrot': 10,
    'carrots': 10,
    'cabbage': 7,
    'cauliflower': 7,
    'spinach': 3,
    'palak': 3,
    'brinjal': 5,
    'eggplant': 5,
    'lady finger': 4,
    'ladyfinger': 4,
    'bhindi': 4,
    'okra': 4,
    'apple': 14,
    'apples': 14,
    'banana': 5,
    'bananas': 5,
    'orange': 10,
    'oranges': 10,
    'mango': 7,
    'mangoes': 7,
    'grape': 7,
    'grapes': 7,
    'strawberry': 5,
    'strawberries': 5,
    'watermelon': 7,
    'papaya': 5,
    'guava': 7,
    'pomegranate': 10,
    'cucumber': 7,
    'capsicum': 7,
    'bell pepper': 7,
    'green beans': 5,
    'beans': 5,
    'peas': 3,
    'coriander': 3,
    'cilantro': 3,
    'mint': 3,
    'ginger': 21,
    'garlic': 30,
    'lemon': 14,
    'lemons': 14,
    'lime': 14,
    'beetroot': 14,
    'radish': 7,
    'lettuce': 3,
  };

  DateTime? calculateExpiry(String productName, {String? category}) {
    final lowerName = productName.toLowerCase().trim();
    
    if (_shouldCalculateExpiry(lowerName, category)) {
      final shelfLife = _getShelfLife(lowerName);
      if (shelfLife != null) {
        final today = DateTime.now();
        final expiryDate = today.add(Duration(days: shelfLife));
        return DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
      }
    }
    
    return null;
  }

  bool _shouldCalculateExpiry(String productName, String? category) {
    if (category != null) {
      final lowerCategory = category.toLowerCase();
      if (lowerCategory == 'vegetable' || 
          lowerCategory == 'fruit' ||
          lowerCategory == 'produce') {
        return true;
      }
    }
    
    return _getShelfLife(productName) != null;
  }

  int? _getShelfLife(String productName) {
    final lowerName = productName.toLowerCase().trim();
    
    if (_shelfLifeDays.containsKey(lowerName)) {
      return _shelfLifeDays[lowerName];
    }
    
    for (final entry in _shelfLifeDays.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }
    
    return null;
  }

  bool hasShelfLife(String productName) {
    return _getShelfLife(productName.toLowerCase().trim()) != null;
  }

  int? getShelfLifeDays(String productName) {
    return _getShelfLife(productName.toLowerCase().trim());
  }

  ExpiryCalculationResult calculateWithDetails(String productName, {String? category}) {
    final expiryDate = calculateExpiry(productName, category: category);
    final shelfLife = _getShelfLife(productName.toLowerCase().trim());
    
    return ExpiryCalculationResult(
      expiryDate: expiryDate,
      shelfLifeDays: shelfLife,
      isCalculated: expiryDate != null,
      calculationSource: expiryDate != null ? 'SHELF_LIFE_TABLE' : null,
    );
  }
}

class ExpiryCalculationResult {
  final DateTime? expiryDate;
  final int? shelfLifeDays;
  final bool isCalculated;
  final String? calculationSource;

  ExpiryCalculationResult({
    this.expiryDate,
    this.shelfLifeDays,
    required this.isCalculated,
    this.calculationSource,
  });
}
