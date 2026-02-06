class ExpiryConfidence {
  final DateTime? date;
  final double confidence;
  final String? detectionMethod;
  final String? matchedPhrase;

  ExpiryConfidence({
    required this.date,
    required this.confidence,
    this.detectionMethod,
    this.matchedPhrase,
  });

  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.4;

  static ExpiryConfidence high(DateTime date, String method, String phrase) {
    return ExpiryConfidence(
      date: date,
      confidence: 0.9,
      detectionMethod: method,
      matchedPhrase: phrase,
    );
  }

  static ExpiryConfidence medium(DateTime date, String method, String phrase) {
    return ExpiryConfidence(
      date: date,
      confidence: 0.6,
      detectionMethod: method,
      matchedPhrase: phrase,
    );
  }

  static ExpiryConfidence low(DateTime date, String method) {
    return ExpiryConfidence(
      date: date,
      confidence: 0.3,
      detectionMethod: method,
      matchedPhrase: null,
    );
  }

  static ExpiryConfidence none() {
    return ExpiryConfidence(
      date: null,
      confidence: 0.0,
      detectionMethod: null,
      matchedPhrase: null,
    );
  }
}
