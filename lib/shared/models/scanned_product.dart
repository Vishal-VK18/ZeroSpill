class ScannedProduct {
  final String? barcode; // Complete barcode value
  final String? rawBarcode; // Raw barcode value (same as barcode, kept for compatibility)
  final String? barcodeFormat; // Format: EAN13, EAN8, UPCA, QR_CODE, etc.
  final String? productName;
  final String? category;
  final DateTime? mfgDate;
  final DateTime? expiryDate;
  final String? ocrText; // Text extracted from package via OCR
  final String? detectionSource; // Source of detection: QR_DATA, OCR, KEYWORDS
  final double confidence;

  ScannedProduct({
    this.barcode,
    this.rawBarcode,
    this.barcodeFormat,
    this.productName,
    this.category,
    this.mfgDate,
    this.expiryDate,
    this.ocrText,
    this.detectionSource,
    this.confidence = 0.0,
  });

  bool get hasProductName => productName != null && productName!.isNotEmpty;
  bool get hasCategory => category != null && category!.isNotEmpty;
  bool get hasExpiryDate => expiryDate != null;
  bool get hasMfgDate => mfgDate != null;
  bool get hasOcrText => ocrText != null && ocrText!.isNotEmpty;
}
