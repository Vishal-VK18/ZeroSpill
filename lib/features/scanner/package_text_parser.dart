import 'expiry_detector.dart';

class PackageTextParser {
  static final PackageTextParser _instance = PackageTextParser._internal();
  factory PackageTextParser() => _instance;
  PackageTextParser._internal();

  final _expiryDetector = HumanLikeExpiryDetector();

  PackageData parsePackageText(String ocrText) {
    final lines = ocrText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final productName = _extractProductName(lines);
    final expiryResult = _expiryDetector.detectExpiry(ocrText);

    return PackageData(
      productName: productName,
      expiryDate: expiryResult.date,
      expiryConfidence: expiryResult.confidence,
      detectionMethod: expiryResult.detectionMethod,
      matchedPhrase: expiryResult.matchedPhrase,
      rawText: ocrText,
    );
  }

  String? _extractProductName(List<String> lines) {
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      
      if (_isLikelyMetadata(line)) continue;
      
      if (line.length >= 3 && line.length <= 50) {
        final upperCount = line.split('').where((c) => c.toUpperCase() == c && c.toLowerCase() != c).length;
        if (upperCount > line.length * 0.3) {
          return _cleanProductName(line);
        }
      }
    }

    if (lines.isNotEmpty) {
      return _cleanProductName(lines.first);
    }

    return null;
  }

  String _cleanProductName(String name) {
    String cleaned = name;
    cleaned = cleaned.replaceAll(RegExp(r'\d+\s*(?:g|kg|ml|l|gm|gms)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'(?:MRP|PRICE|RS|₹)\s*\d+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  bool _isLikelyMetadata(String text) {
    final patterns = [
      RegExp(r'^\d+$'),
      RegExp(r'^[A-Z]{2,3}\s*\d+$'),
      RegExp(r'(?:BARCODE|CODE|BATCH|LOT)', caseSensitive: false),
      RegExp(r'^[0-9\s\-]+$'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) return true;
    }

    return false;
  }
}

class PackageData {
  final String? productName;
  final DateTime? expiryDate;
  final double expiryConfidence;
  final String? detectionMethod;
  final String? matchedPhrase;
  final String rawText;

  PackageData({
    this.productName,
    this.expiryDate,
    this.expiryConfidence = 0.0,
    this.detectionMethod,
    this.matchedPhrase,
    required this.rawText,
  });

  bool get hasHighConfidenceExpiry => expiryConfidence >= 0.7;
  bool get hasMediumConfidenceExpiry => expiryConfidence >= 0.4 && expiryConfidence < 0.7;
  bool get hasLowConfidenceExpiry => expiryConfidence > 0 && expiryConfidence < 0.4;
  bool get hasNoExpiry => expiryDate == null;
}

