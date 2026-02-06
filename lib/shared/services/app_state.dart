class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  bool _onboardingCompleted = false;
  String _selectedRegion = 'Tamil Nadu';

  bool get onboardingCompleted => _onboardingCompleted;
  String get selectedRegion => _selectedRegion;

  void completeOnboarding() {
    _onboardingCompleted = true;
  }

  void setRegion(String region) {
    _selectedRegion = region;
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
