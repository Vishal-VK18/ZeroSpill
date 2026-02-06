import 'expiry_confidence.dart';

class HumanLikeExpiryDetector {
  static final HumanLikeExpiryDetector _instance = HumanLikeExpiryDetector._internal();
  factory HumanLikeExpiryDetector() => _instance;
  HumanLikeExpiryDetector._internal();

  final List<String> _primaryContextPhrases = [
    'use by',
    'best before',
    'expiry',
    'exp',
    'expires on',
  ];

  final List<String> _secondaryContextPhrases = [
    'bb',
    'consume before',
    'valid upto',
    'best if used by',
  ];

  ExpiryConfidence detectExpiry(String ocrText) {
    final lines = _splitIntoLines(ocrText);
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalizedLine = _normalizeLine(line);

      final contextMatch = _findContextPhrase(normalizedLine);
      if (contextMatch != null) {
        final result = _searchForDateNearContext(lines, i, contextMatch, normalizedLine);
        if (result.date != null) {
          return result;
        }
      }
    }

    final mfgResult = _findMfgDate(lines);
    if (mfgResult != null) {
      final expiryFromMfg = _calculateExpiryFromMfg(mfgResult, ocrText);
      if (expiryFromMfg != null) {
        return ExpiryConfidence.medium(
          expiryFromMfg,
          'CALCULATED_FROM_MFG',
          'Calculated from manufacturing date',
        );
      }
    }

    return ExpiryConfidence.none();
  }

  List<String> _splitIntoLines(String text) {
    return text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 2)
        .toList();
  }

  String _normalizeLine(String line) {
    return line.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\/\-\.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _findContextPhrase(String normalizedLine) {
    for (final phrase in _primaryContextPhrases) {
      if (normalizedLine.contains(phrase)) {
        return phrase;
      }
    }
    for (final phrase in _secondaryContextPhrases) {
      if (normalizedLine.contains(phrase)) {
        return phrase;
      }
    }
    return null;
  }

  ExpiryConfidence _searchForDateNearContext(
    List<String> lines,
    int contextLineIndex,
    String contextPhrase,
    String contextLine,
  ) {
    final sameLine = _extractDateFromLine(contextLine);
    if (sameLine != null && _isValidFutureDate(sameLine)) {
      return ExpiryConfidence.high(
        sameLine,
        'CONTEXT_SAME_LINE',
        '$contextPhrase on same line',
      );
    }

    if (contextLineIndex + 1 < lines.length) {
      final nextLine = _normalizeLine(lines[contextLineIndex + 1]);
      final nextLineDate = _extractDateFromLine(nextLine);
      if (nextLineDate != null && _isValidFutureDate(nextLineDate)) {
        return ExpiryConfidence.high(
          nextLineDate,
          'CONTEXT_NEXT_LINE',
          '$contextPhrase + next line',
        );
      }
    }

    if (contextLineIndex > 0) {
      final prevLine = _normalizeLine(lines[contextLineIndex - 1]);
      final prevLineDate = _extractDateFromLine(prevLine);
      if (prevLineDate != null && _isValidFutureDate(prevLineDate)) {
        return ExpiryConfidence.medium(
          prevLineDate,
          'CONTEXT_PREV_LINE',
          '$contextPhrase + previous line',
        );
      }
    }

    if (contextLineIndex + 2 < lines.length) {
      final secondNextLine = _normalizeLine(lines[contextLineIndex + 2]);
      final secondNextDate = _extractDateFromLine(secondNextLine);
      if (secondNextDate != null && _isValidFutureDate(secondNextDate)) {
        return ExpiryConfidence.medium(
          secondNextDate,
          'CONTEXT_NEARBY',
          '$contextPhrase + nearby line',
        );
      }
    }

    return ExpiryConfidence.none();
  }

  DateTime? _extractDateFromLine(String line) {
    final patterns = [
      RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})'),
      RegExp(r'(\d{1,2})[\/\-](\d{4})'),
      RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})'),
      RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*(\d{4})', caseSensitive: false),
      RegExp(r"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*'?(\d{2})", caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final date = _parseMatchedDate(match, line);
        if (date != null) {
          return date;
        }
      }
    }

    return null;
  }

  DateTime? _parseMatchedDate(RegExpMatch match, String line) {
    final group1 = match.group(1)!;
    
    if (_isMonthName(group1)) {
      final month = _monthNameToNumber(group1);
      final yearStr = match.group(2)!;
      int year = int.parse(yearStr);
      if (year < 100) year += 2000;
      return DateTime(year, month, _getLastDayOfMonth(year, month));
    }

    if (match.groupCount == 2) {
      final month = int.tryParse(group1);
      final year = int.tryParse(match.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return DateTime(year, month, _getLastDayOfMonth(year, month));
      }
    }

    if (match.groupCount == 3) {
      return _parseThreePartDate(group1, match.group(2)!, match.group(3)!);
    }

    return null;
  }

  DateTime? _parseThreePartDate(String p1, String p2, String p3) {
    try {
      int v1 = int.parse(p1);
      int v2 = int.parse(p2);
      int v3 = int.parse(p3);

      int year, month, day;

      if (v1 > 31) {
        year = v1;
        month = v2;
        day = v3;
      } else if (v3 > 31 || v3 < 100) {
        day = v1;
        month = v2;
        year = v3 < 100 ? 2000 + v3 : v3;
      } else {
        day = v1;
        month = v2;
        year = v3;
      }

      if (year < 100) year += 2000;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  bool _isMonthName(String text) {
    final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return months.contains(text.toLowerCase());
  }

  int _monthNameToNumber(String month) {
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  DateTime? _findMfgDate(List<String> lines) {
    for (final line in lines) {
      final normalized = _normalizeLine(line);
      if (normalized.contains('mfg') || normalized.contains('mfd') || 
          normalized.contains('pkd') || normalized.contains('packed on')) {
        final date = _extractDateFromLine(normalized);
        if (date != null) {
          return date;
        }
      }
    }
    return null;
  }

  DateTime? _calculateExpiryFromMfg(DateTime mfgDate, String fullText) {
    final durationPattern = RegExp(
      r'(?:best before|use within|consume within)\s+(\d+)\s+(months?|days?|years?)',
      caseSensitive: false,
    );

    final match = durationPattern.firstMatch(fullText);
    if (match != null) {
      final quantity = int.tryParse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();

      if (quantity != null) {
        if (unit.contains('month')) {
          return DateTime(mfgDate.year, mfgDate.month + quantity, mfgDate.day);
        } else if (unit.contains('day')) {
          return mfgDate.add(Duration(days: quantity));
        } else if (unit.contains('year')) {
          return DateTime(mfgDate.year + quantity, mfgDate.month, mfgDate.day);
        }
      }
    }

    return DateTime(mfgDate.year, mfgDate.month + 6, mfgDate.day);
  }

  bool _isValidFutureDate(DateTime date) {
    final now = DateTime.now();
    final tenYearsFromNow = now.add(const Duration(days: 3650));
    return date.isAfter(now.subtract(const Duration(days: 60))) && 
           date.isBefore(tenYearsFromNow);
  }

  int _getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
