import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'scan_parser.dart';

class ProductClassifier {
  static final ProductClassifier _instance = ProductClassifier._internal();
  factory ProductClassifier() => _instance;
  ProductClassifier._internal();

  final _textRecognizer = TextRecognizer();

  Future<ProductClassificationResult> classify(ParsedScanData scanData, {String? imagePath}) async {
    String? productName;
    String? category;
    String? source;
    double confidence = 0.0;

    // Priority 1: Extract from QR structured data
    if (scanData.isQrCode && scanData.structuredData != null) {
      productName = scanData.getField(['name', 'product_name', 'productname', 'product', 'title']);
      category = scanData.getField(['category', 'type', 'product_type', 'producttype']);
      
      if (productName != null || category != null) {
        source = 'QR_DATA';
        confidence = 0.9;
      }
    }

    // Priority 2: OCR text from package
    // Note: Image capture from camera will be implemented as a separate feature
    String? ocrText;
    if (imagePath != null) {
      ocrText = await _extractTextFromImage(imagePath);
      
      if (productName == null && ocrText != null) {
        productName = _extractProductNameFromOcr(ocrText);
        if (productName != null) {
          source = 'OCR';
          confidence = 0.7;
        }
      }
    }

    // Priority 3: Keyword-based classification
    if (category == null) {
      final textForClassification = productName ?? ocrText ?? scanData.rawValue;
      category = classifyByKeywords(textForClassification);
      if (category != null && confidence < 0.5) {
        confidence = 0.5;
      }
    }

    return ProductClassificationResult(
      productName: productName,
      category: category,
      ocrText: ocrText,
      source: source,
      confidence: confidence,
    );
  }

  Future<String?> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return null;
    }
  }

  String? _extractProductNameFromOcr(String ocrText) {
    // Get the first few lines which typically contain product name
    final lines = ocrText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) return null;

    // Look for brand names or product names (typically in first 3 lines)
    for (int i = 0; i < 3 && i < lines.length; i++) {
      final line = lines[i].trim();
      // Filter out lines that are likely just dates, codes, or very short
      if (line.length > 3 && !_isLikelyMetadata(line)) {
        return line;
      }
    }

    return lines.first;
  }

  bool _isLikelyMetadata(String text) {
    // Check if text is likely a date, barcode, or other metadata
    final patterns = [
      RegExp(r'^\d+$'), // Just numbers
      RegExp(r'^\d{1,2}[\s\/\-]\d{1,2}[\s\/\-]\d{2,4}$'), // Date format
      RegExp(r'^[A-Z]{2,3}\s*\d+$'), // Code like "MRP 100"
      RegExp(r'(?:EXP|MFG|MRP|NET|BEST)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) return true;
    }

    return false;
  }

  String? classifyByKeywords(String text) {
    final lowerText = text.toLowerCase();

    // Category keyword mappings
    final categoryKeywords = {
      'Dairy': ['milk', 'curd', 'yogurt', 'cheese', 'butter', 'ghee', 'paneer', 'cream', 'lassi', 'dahi'],
      'Grain': ['rice', 'wheat', 'atta', 'flour', 'bread', 'roti', 'chapati', 'maida', 'rava', 'sooji', 'oats', 'quinoa'],
      'Vegetable': ['tomato', 'onion', 'potato', 'carrot', 'spinach', 'cabbage', 'broccoli', 'cauliflower', 'capsicum', 'brinjal', 'bhindi', 'palak'],
      'Fruit': ['apple', 'banana', 'orange', 'mango', 'grape', 'strawberry', 'watermelon', 'papaya', 'guava', 'pomegranate'],
      'Meat': ['chicken', 'mutton', 'lamb', 'beef', 'pork', 'fish', 'prawn', 'shrimp', 'egg'],
      'Packaged': ['biscuit', 'chips', 'namkeen', 'snack', 'cookie', 'wafer', 'sauce', 'ketchup', 'jam', 'pickle', 'paste'],
      'Frozen': ['ice cream', 'frozen', 'peas'],
      'Beverages': ['juice', 'coffee', 'tea', 'cola', 'soda', 'water', 'drink'],
      'Spices': ['turmeric', 'chili', 'cumin', 'coriander', 'garam masala', 'pepper', 'salt', 'mustard'],
    };

    // Count matches for each category
    String? bestCategory;
    int maxMatches = 0;

    for (final entry in categoryKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          matches++;
        }
      }
      
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class ProductClassificationResult {
  final String? productName;
  final String? category;
  final String? ocrText;
  final String? source;
  final double confidence;

  ProductClassificationResult({
    this.productName,
    this.category,
    this.ocrText,
    this.source,
    required this.confidence,
  });
}
