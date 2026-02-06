import 'package:flutter/material.dart';

class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;
  AppSettingsService._internal();

  bool _onboardingCompleted = false;
  String _selectedRegion = 'Tamil Nadu';
  int _expiryAlertDays = 7;

  bool get onboardingCompleted => _onboardingCompleted;
  String get selectedRegion => _selectedRegion;
  int get expiryAlertDays => _expiryAlertDays;

  void completeOnboarding() {
    _onboardingCompleted = true;
    notifyListeners();
  }

  void setRegion(String region) {
    if (_selectedRegion != region) {
      _selectedRegion = region;
      notifyListeners();
    }
  }

  void setExpiryAlertDays(int days) {
    if (_expiryAlertDays != days) {
      _expiryAlertDays = days;
      notifyListeners();
    }
  }

  bool shouldAlert(int daysUntilExpiry) {
    return daysUntilExpiry <= _expiryAlertDays && daysUntilExpiry >= 0;
  }

  List<String> get availableRegions => [
    'Tamil Nadu',
    'Karnataka',
    'Andhra Pradesh',
    'Kerala',
    'Uttar Pradesh',
    'Maharashtra',
    'Gujarat',
    'Punjab',
    'West Bengal',
    'Rajasthan',
  ];
}
