import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'product_classifier.dart';
import 'expiry_calculator.dart';

class BillOcrParser {
  static final BillOcrParser _instance = BillOcrParser._internal();
  factory BillOcrParser() => _instance;
  BillOcrParser._internal();

  final _textRecognizer = TextRecognizer();
  final _productClassifier = ProductClassifier();
  final _expiryCalculator = ExpiryCalculator();

  Future<BillParseResult> parseBill(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final products = _extractProducts(recognizedText.text);
      
      return BillParseResult(
        products: products,
        rawText: recognizedText.text,
        success: true,
        errorMessage: null,
      );
    } catch (e) {
      return BillParseResult(
        products: [],
        rawText: null,
        success: false,
        errorMessage: 'Failed to process bill: ${e.toString()}',
      );
    }
  }

  List<DetectedProduct> _extractProducts(String text) {
    final lines = text.split('\n');
    final List<DetectedProduct> products = [];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine.isEmpty) continue;
      if (_shouldIgnoreLine(trimmedLine)) continue;
      if (!_containsAlphabets(trimmedLine)) continue;
      
      final productName = _normalizeName(trimmedLine);
      
      if (productName.length < 3) continue;
      
      final category = _productClassifier.classifyByKeywords(productName);
      
      DateTime? expiryDate;
      bool isAutoCalculated = false;
      
      if (category == 'Vegetable' || category == 'Fruit') {
        final expiryResult = _expiryCalculator.calculateWithDetails(productName, category: category);
        if (expiryResult.isCalculated) {
          expiryDate = expiryResult.expiryDate;
          isAutoCalculated = true;
        }
      }
      
      products.add(DetectedProduct(
        name: productName,
        category: category ?? 'Other',
        expiryDate: expiryDate,
        isExpiryAutoCalculated: isAutoCalculated,
        quantity: 1,
      ));
    }
    
    return _deduplicateProducts(products);
  }

  bool _shouldIgnoreLine(String line) {
    final lowerLine = line.toLowerCase();
    
    final ignoreKeywords = [
      'total',
      'subtotal',
      'sub total',
      'gst',
      'cgst',
      'sgst',
      'igst',
      'tax',
      'cash',
      'card',
      'credit',
      'debit',
      'upi',
      'payment',
      'amount',
      'rupee',
      'thank you',
      'thanks',
      'visit',
      'receipt',
      'bill',
      'invoice',
      'date',
      'time',
      'address',
      'phone',
      'mobile',
      'fssai',
      'gstin',
      'pan',
      'discount',
      'balance',
      'tender',
      'change',
      'qty',
      'quantity',
      'price',
      'rate',
      'mrp',
    ];
    
    for (final keyword in ignoreKeywords) {
      if (lowerLine.contains(keyword)) {
        return true;
      }
    }
    
    if (RegExp(r'^\d+[\s\.\-]*\d*$').hasMatch(lowerLine)) {
      return true;
    }
    
    if (RegExp(r'^[₹\$\s\d\.\,\-]+$').hasMatch(line)) {
      return true;
    }
    
    final digitCount = line.replaceAll(RegExp(r'[^\d]'), '').length;
    if (digitCount > line.length * 0.5) {
      return true;
    }
    
    return false;
  }

  bool _containsAlphabets(String text) {
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  String _normalizeName(String name) {
    String normalized = name;
    
    normalized = normalized.replaceAll(RegExp(r'[\d\₹\$\.\,\-]+'), ' ');
    
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), ' ');
    
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    normalized = _toTitleCase(normalized);
    
    return normalized;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  List<DetectedProduct> _deduplicateProducts(List<DetectedProduct> products) {
    final Map<String, DetectedProduct> uniqueProducts = {};
    
    for (final product in products) {
      final key = product.name.toLowerCase();
      
      if (!uniqueProducts.containsKey(key)) {
        uniqueProducts[key] = product;
      } else {
        final existing = uniqueProducts[key]!;
        uniqueProducts[key] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      }
    }
    
    return uniqueProducts.values.toList();
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class BillParseResult {
  final List<DetectedProduct> products;
  final String? rawText;
  final bool success;
  final String? errorMessage;

  BillParseResult({
    required this.products,
    this.rawText,
    required this.success,
    this.errorMessage,
  });
}

class DetectedProduct {
  final String name;
  final String category;
  final DateTime? expiryDate;
  final bool isExpiryAutoCalculated;
  final int quantity;

  DetectedProduct({
    required this.name,
    required this.category,
    this.expiryDate,
    this.isExpiryAutoCalculated = false,
    this.quantity = 1,
  });

  DetectedProduct copyWith({
    String? name,
    String? category,
    DateTime? expiryDate,
    bool? isExpiryAutoCalculated,
    int? quantity,
  }) {
    return DetectedProduct(
      name: name ?? this.name,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      isExpiryAutoCalculated: isExpiryAutoCalculated ?? this.isExpiryAutoCalculated,
      quantity: quantity ?? this.quantity,
    );
  }
}
