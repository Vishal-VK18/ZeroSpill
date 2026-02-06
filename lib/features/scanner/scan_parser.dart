import 'dart:convert';

class ScanParser {
  static final ScanParser _instance = ScanParser._internal();
  factory ScanParser() => _instance;
  ScanParser._internal();

  ParsedScanData parse(String rawValue, String? format) {
    final isQrCode = _isQrCodeFormat(format);
    
    if (isQrCode) {
      return _parseQrCode(rawValue);
    } else {
      return _parseBarcode(rawValue, format);
    }
  }

  bool _isQrCodeFormat(String? format) {
    if (format == null) return false;
    final qrFormats = ['QR_CODE', 'QRCODE', 'QR'];
    return qrFormats.contains(format.toUpperCase());
  }

  ParsedScanData _parseQrCode(String rawValue) {
    Map<String, dynamic>? structuredData;
    
    // Try parsing as JSON
    try {
      structuredData = jsonDecode(rawValue) as Map<String, dynamic>;
    } catch (e) {
      // Not JSON, try key-value pairs
      structuredData = _parseKeyValuePairs(rawValue);
    }

    return ParsedScanData(
      rawValue: rawValue,
      isQrCode: true,
      structuredData: structuredData,
    );
  }

  Map<String, dynamic>? _parseKeyValuePairs(String text) {
    final Map<String, dynamic> data = {};
    
    // Try common separators: newline, semicolon, comma
    final lines = text.split(RegExp(r'[\n;,]'));
    
    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim().toLowerCase();
          final value = parts.sublist(1).join(':').trim();
          data[key] = value;
        }
      } else if (line.contains('=')) {
        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim().toLowerCase();
          final value = parts.sublist(1).join('=').trim();
          data[key] = value;
        }
      }
    }
    
    return data.isEmpty ? null : data;
  }

  ParsedScanData _parseBarcode(String rawValue, String? format) {
    return ParsedScanData(
      rawValue: rawValue,
      isQrCode: false,
      barcodeFormat: format,
    );
  }

  String? extractFromStructuredData(Map<String, dynamic>? data, List<String> possibleKeys) {
    if (data == null) return null;
    
    for (final key in possibleKeys) {
      final lowerKey = key.toLowerCase();
      for (final dataKey in data.keys) {
        if (dataKey.toLowerCase() == lowerKey) {
          return data[dataKey]?.toString();
        }
      }
    }
    
    return null;
  }
}

class ParsedScanData {
  final String rawValue;
  final bool isQrCode;
  final String? barcodeFormat;
  final Map<String, dynamic>? structuredData;

  ParsedScanData({
    required this.rawValue,
    required this.isQrCode,
    this.barcodeFormat,
    this.structuredData,
  });

  String? getField(List<String> possibleKeys) {
    return ScanParser().extractFromStructuredData(structuredData, possibleKeys);
  }
}
