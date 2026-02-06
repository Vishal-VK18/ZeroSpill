import '../models/scanned_product.dart';
import '../../features/scanner/product_classifier.dart';
import '../../features/scanner/expiry_calculator.dart';
import '../../features/scanner/package_text_parser.dart';

class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  final _productClassifier = ProductClassifier();
  final _expiryCalculator = ExpiryCalculator();
  final _packageParser = PackageTextParser();

  Future<ScannedProduct> parseBarcode(
    String rawValue, {
    String? format,
    String? ocrText,
  }) async {
    String? productName;
    String? category;
    DateTime? expiryDate;
    String? detectionSource;
    double confidence = 0.2;

    if (ocrText != null && ocrText.isNotEmpty) {
      final packageData = _packageParser.parsePackageText(ocrText);
      
      productName = packageData.productName;
      expiryDate = packageData.expiryDate;
      detectionSource = packageData.detectionMethod ?? 'PACKAGE_OCR';

      if (packageData.hasHighConfidenceExpiry) {
        confidence = 0.9;
      } else if (packageData.hasMediumConfidenceExpiry) {
        confidence = 0.6;
      } else if (packageData.hasLowConfidenceExpiry) {
        confidence = 0.4;
      }

      if (productName != null) {
        category = _productClassifier.classifyByKeywords(productName);
        if (category != null) {
          confidence = confidence * 0.7 + 0.3;
        }
      }
    }

    if (category == null) {
      category = 'Packaged Food';
    }

    if (expiryDate == null && productName != null) {
      final calculatedExpiry = _expiryCalculator.calculateExpiry(productName, category: category);
      if (calculatedExpiry != null) {
        expiryDate = calculatedExpiry;
        detectionSource = 'AUTO_CALCULATED';
        confidence = 0.5;
      }
    }

    return ScannedProduct(
      barcode: rawValue,
      rawBarcode: rawValue,
      barcodeFormat: format,
      productName: productName,
      category: category,
      expiryDate: expiryDate,
      ocrText: ocrText,
      detectionSource: detectionSource,
      confidence: confidence,
    );
  }

  void dispose() {
    _productClassifier.dispose();
  }
}

