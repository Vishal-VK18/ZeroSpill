import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' show Size;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Parsed expiry information
class ExpiryData {
  final DateTime? expiryDate;
  final DateTime? manufacturingDate;
  final DateTime? packedDate;
  final String rawText;
  final double confidence;
  final ExpiryLabel? labelType;

  ExpiryData({
    this.expiryDate,
    this.manufacturingDate,
    this.packedDate,
    required this.rawText,
    required this.confidence,
    this.labelType,
  });

  bool get hasValidExpiry => expiryDate != null;
  bool get hasValidMfg => manufacturingDate != null;
  bool get hasValidPacked => packedDate != null;

  @override
  String toString() {
    final parts = <String>[];
    if (expiryDate != null) parts.add('Expiry: ${expiryDate!.toLocal()}');
    if (manufacturingDate != null) parts.add('Mfg: ${manufacturingDate!.toLocal()}');
    if (packedDate != null) parts.add('Packed: ${packedDate!.toLocal()}');
    return parts.isEmpty ? 'No dates found' : parts.join(', ');
  }
}

/// Expiry label types
enum ExpiryLabel {
  useBy,
  bestBefore,
  exp,
  mfg,
  pkd,
  dateValue,
}

/// Date candidate with label and confidence for multi-date selection
class DateCandidate {
  final DateTime date;
  final String label; // 'EXP', 'USE_BY', 'BEST_BEFORE', 'MFG', 'PKD', 'UNLABELED', 'MFG_ESTIMATED'
  final double confidence;
  final String source; // 'ML_REGION', 'FULL_IMAGE', 'MFG_ESTIMATED'
  
  DateCandidate({
    required this.date,
    required this.label,
    required this.confidence,
    required this.source,
  });
  
  /// Priority for date selection (higher is better)
  int get priority {
    switch (label) {
      case 'EXP':
      case 'USE_BY':
      case 'BEST_BEFORE':
        return 3; // Highest priority - actual expiry dates
      case 'MFG_ESTIMATED':
      case 'PKD_ESTIMATED':
        return 2; // Medium priority - calculated from MFG/PKD
      case 'MFG':
      case 'PKD':
        return 1; // Low priority - raw MFG/PKD dates (not expiry)
      case 'UNLABELED':
      default:
        return 1; // Lowest priority - unidentified dates
    }
  }
  
  @override
  String toString() {
    return '$label: ${date.toLocal().toString().substring(0, 10)} (conf: ${confidence.toStringAsFixed(2)}, src: $source, pri: $priority)';
  }
}

/// Select best expiry date from multiple candidates
class DateCandidateSelector {
  /// Select the best date candidate from a list
  static DateTime? selectBestCandidate(List<DateCandidate> candidates) {
    if (candidates.isEmpty) return null;
    
    print('📊 Evaluating ${candidates.length} date candidates:');
    for (var candidate in candidates) {
      print('   • $candidate');
    }
    
    // Filter future dates only (within reasonable range)
    final now = DateTime.now();
    final maxFuture = now.add(const Duration(days: 365 * 5)); // Max 5 years
    
    final futureDates = candidates.where((c) {
      return c.date.isAfter(now) && c.date.isBefore(maxFuture);
    }).toList();
    
    if (futureDates.isEmpty) {
      print('   ⚠️ No valid future dates found');
      return null;
    }
    
    print('   ✓ Found ${futureDates.length} valid future dates');
    
    // Sort by priority (descending), then by date (descending - latest first)
    futureDates.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.date.compareTo(a.date); // Latest date wins
    });
    
    final selected = futureDates.first;
    print('   ✅ Selected: $selected');
    
    return selected.date;
  }
}

/// Advanced expiry text parser with human-like logic
class ExpiryTextParser {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Parse expiry information from image bytes using OCR
  static Future<ExpiryData> parseExpiryText(
    Uint8List imageBytes,
    String detectedClass,
  ) async {
    try {
      // Decode image to ensure it's valid
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        print('⚠️  Failed to decode image');
        return ExpiryData(rawText: '', confidence: 0.0);
      }

      // Convert to PNG format for ML Kit compatibility
      final pngBytes = Uint8List.fromList(img.encodePng(decodedImage));
      
      // Write to temporary file (ML Kit works better with files)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      // Create InputImage from file (more reliable than bytes)
      final inputImage = InputImage.fromFilePath(tempFile.path);

      // Run OCR
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      if (rawText.isEmpty) {
        return ExpiryData(
          rawText: '',
          confidence: 0.0,
        );
      }

      // Parse based on detected class
      final labelType = _classNameToLabel(detectedClass);
      final dates = _extractDates(rawText, labelType);

      return ExpiryData(
        expiryDate: dates['expiry'],
        manufacturingDate: dates['mfg'],
        packedDate: dates['packed'],
        rawText: rawText,
        confidence: recognizedText.blocks.isNotEmpty ? 0.8 : 0.0,
        labelType: labelType,
      );
    } catch (e) {
      print('Error parsing expiry text: $e');
      return ExpiryData(
        rawText: '',
        confidence: 0.0,
      );
    }
  }

  /// Parse expiry information from raw text (without image)
  static ExpiryData parseRawText(String text, {ExpiryLabel? labelHint}) {
    if (text.isEmpty) {
      return ExpiryData(rawText: '', confidence: 0.0);
    }

    final dates = _extractDates(text, labelHint);

    return ExpiryData(
      expiryDate: dates['expiry'],
      manufacturingDate: dates['mfg'],
      packedDate: dates['packed'],
      rawText: text,
      confidence: dates.isNotEmpty ? 0.7 : 0.0,
      labelType: labelHint,
    );
  }

  /// Convert class name to label type
  static ExpiryLabel? _classNameToLabel(String className) {
    switch (className.toLowerCase()) {
      case 'use_by':
        return ExpiryLabel.useBy;
      case 'best_before':
        return ExpiryLabel.bestBefore;
      case 'exp':
        return ExpiryLabel.exp;
      case 'mfg':
        return ExpiryLabel.mfg;
      case 'pkd':
        return ExpiryLabel.pkd;
      case 'date_value':
        return ExpiryLabel.dateValue;
      default:
        return null;
    }
  }

  /// Extract dates from text using multiple patterns
  static Map<String, DateTime?> _extractDates(String text, ExpiryLabel? labelType) {
    final result = <String, DateTime?>{
      'expiry': null,
      'mfg': null,
      'packed': null,
    };

    // Clean text - preserve dots for formats like "08 AUG. 26"
    final cleanText = text.replaceAll('\n', ' ').toUpperCase();

    // Comprehensive date patterns covering all real-world formats
    final patterns = [
      // === HIGH PRIORITY: Explicit keyword formats ===
      
      // "EXP 08 AUG. 26" or "EXP: 08 AUG 26" (with/without dots/colons)
      RegExp(r'(?:EXP|EXPIRY|BEST BEFORE|USE BY|BB)\s*:?\s*(\d{1,2})\s+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z.]*\s+(\d{2,4})', caseSensitive: false),
      
      // "EXP: 08/08/26" or "BEST BEFORE: 08-08-2026"
      RegExp(r'(?:EXP|EXPIRY|BEST BEFORE|USE BY|BB)\s*:?\s*(\d{1,2})[\/ \-\.](\d{1,2})[\/ \-\.](\d{2,4})', caseSensitive: false),
      
      // "BEST BEFORE AUG 2026" or "USE BY: SEP 2026"
      RegExp(r'(?:EXP|EXPIRY|BEST BEFORE|USE BY|BB)\s*:?\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z.]*\s+(\d{4})', caseSensitive: false),
      
      // "EXP 08/2026" or "BB: 08-2026"
      RegExp(r'(?:EXP|EXPIRY|BEST BEFORE|USE BY|BB)\s*:?\s*(\d{1,2})[\/ \-](\d{4})', caseSensitive: false),
      
      // === MEDIUM PRIORITY: Month name formats ===
      
      // "08 AUG. 26" or "08 AUG 2026" (with optional dot after month)
      RegExp(r'\b(\d{1,2})\s+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z.]*\s+(\d{2,4})\b', caseSensitive: false),
      
      // "AUG. 26" or "AUG 2026" (month + year only)
      RegExp(r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z.]*\s+(\d{2,4})\b', caseSensitive: false),
      
      // === STANDARD: Numeric formats ===
      
      // "08/08/26" or "08-08-2026" or "08.08.2026"
      RegExp(r'\b(\d{1,2})[\/ \-\.](\d{1,2})[\/ \-\.](\d{2,4})\b'),
      
      // "08/2026" or "08-2026" or "08.2026" (MM/YYYY)
      RegExp(r'\b(\d{1,2})[\/ \-\.](\d{4})\b'),
      
      // "08/26" or "08-26" (MM/YY)
      RegExp(r'\b(\d{1,2})[\/ \-](\d{2})\b'),
      
      // === ISO FORMAT ===
      
      // "2026-08-08" (YYYY-MM-DD)
      RegExp(r'\b(\d{4})[\/ \-](\d{1,2})[\/ \-](\d{1,2})\b'),
      
      // === COMPACT FORMATS (no separators) ===
      
      // "080826" or "08082026" (DDMMYY or DDMMYYYY)
      RegExp(r'\b(\d{2})(\d{2})(\d{2,4})\b'),
    ];

    // Try to find dates
    for (final pattern in patterns) {
      final matches = pattern.allMatches(cleanText);
      for (final match in matches) {
        final date = _parseMatch(match, pattern);
        if (date != null && _isPlausibleDate(date)) {
          // Assign based on label type
          if (labelType != null) {
            _assignDateByLabel(result, date, labelType);
          } else {
            // Default to expiry if no label hint
            result['expiry'] ??= date;
          }
        }
      }
    }

    return result;
  }

  /// Parse regex match into DateTime
  static DateTime? _parseMatch(RegExpMatch match, RegExp pattern) {
    try {
      final groups = match.groupCount;
      
      if (groups >= 2) {
        final str1 = match.group(1)!;
        final str2 = match.group(2)!;
        final str3 = groups >= 3 ? match.group(3) : null;

        // Check if month name format (case insensitive)
        if (_isMonthName(str2)) {
          final day = str3 != null ? int.tryParse(str1) ?? 1 : 1;
          final month = _monthNameToNumber(str2);
          var year = int.parse(str3 ?? str1);
          
          // Convert 2-digit year to 4-digit
          if (year < 100) {
            year += (year < 50) ? 2000 : 1900;
          }
          
          return DateTime(year, month, day);
        }

        // MMM YYYY format (only month and year)
        if (_isMonthName(str1) && str3 == null) {
          final month = _monthNameToNumber(str1);
          var year = int.parse(str2);
          if (year < 100) year += 2000;
          return DateTime(year, month, _getLastDayOfMonth(year, month));
        }

        // Try different date formats
        final num1 = int.tryParse(str1);
        final num2 = int.tryParse(str2);
        final num3 = str3 != null ? int.tryParse(str3) : null;

        if (num1 == null || num2 == null) return null;

        // Two-part date (MM/YYYY or MM/YY)
        if (num3 == null) {
          var year = num2;
          final month = num1;
          // If year is 2-digit, convert to 4-digit
          if (year < 100) {
            year += (year < 50) ? 2000 : 1900;
          }
          // Validate month
          if (month < 1 || month > 12) return null;
          return DateTime(year, month, _getLastDayOfMonth(year, month));
        }

        // Three-part date
        if (num3 != null) {
          // DD/MM/YYYY or DD-MM-YYYY
          if (num3 > 31) {
            final day = num1;
            final month = num2;
            final year = num3;
            if (month < 1 || month > 12 || day < 1 || day > 31) return null;
            return DateTime(year, month, day);
          }
          // DD/MM/YY
          else if (num3 < 100) {
            final day = num1;
            final month = num2;
            final year = num3 + (num3 < 50 ? 2000 : 1900);
            if (month < 1 || month > 12 || day < 1 || day > 31) return null;
            return DateTime(year, month, day);
          }
          // YYYY-MM-DD
          else if (num1 > 31) {
            final year = num1;
            final month = num2;
            final day = num3;
            if (month < 1 || month > 12 || day < 1 || day > 31) return null;
            return DateTime(year, month, day);
          }
          // Compact format DDMMYYYY or DDMMYY
          else {
            // Try DD/MM/YYYY interpretation
            final day = num1;
            final month = num2;
            final year = num3 > 31 ? num3 : (num3 < 50 ? 2000 + num3 : 1900 + num3);
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
              return DateTime(year, month, day);
            }
          }
        }
      }
    } catch (e) {
      // Parsing failed, return null
    }

    return null;
  }

  /// Get last day of month (handles leap years)
  static int _getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Check if string is a month name (handles dots and partial names)
  static bool _isMonthName(String str) {
    // Remove dots and trim
    final cleaned = str.replaceAll('.', '').trim().toUpperCase();
    
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    
    // Check exact match first
    if (months.contains(cleaned)) return true;
    
    // Check if it starts with a month abbreviation (handles AUGUST, SEPTEMBER, etc.)
    return months.any((month) => cleaned.startsWith(month));
  }

  /// Convert month name to number (handles dots and partial names)
  static int _monthNameToNumber(String month) {
    // Remove dots and trim
    final cleaned = month.replaceAll('.', '').trim().toUpperCase();
    
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,
      'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8,
      'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    };
    
    // Direct match
    if (months.containsKey(cleaned)) {
      return months[cleaned]!;
    }
    
    // Partial match (e.g., "AUGUST" starts with "AUG")
    for (var entry in months.entries) {
      if (cleaned.startsWith(entry.key)) {
        return entry.value;
      }
    }
    
    return 1; // Default to January if no match
  }

  /// Check if date is plausible (not too far in past/future)
  static bool _isPlausibleDate(DateTime date) {
    final now = DateTime.now();
    final minDate = DateTime(2020, 1, 1);
    final maxDate = DateTime(2040, 12, 31);

    return date.isAfter(minDate) && date.isBefore(maxDate);
  }

  /// Assign date to appropriate field based on label
  static void _assignDateByLabel(
    Map<String, DateTime?> result,
    DateTime date,
    ExpiryLabel label,
  ) {
    switch (label) {
      case ExpiryLabel.useBy:
      case ExpiryLabel.bestBefore:
      case ExpiryLabel.exp:
        result['expiry'] ??= date;
        break;
      case ExpiryLabel.mfg:
        result['mfg'] ??= date;
        break;
      case ExpiryLabel.pkd:
        result['packed'] ??= date;
        break;
      case ExpiryLabel.dateValue:
        // Use context - if near expiry keywords, it's expiry
        result['expiry'] ??= date;
        break;
    }
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}
