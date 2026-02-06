import 'package:flutter/material.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../shared/services/app_settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AppSettingsService _settings = AppSettingsService();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(icon: Icons.calendar_today_outlined, title: 'Track Expiry Dates', description: 'Pantrix automatically monitors your pantry and alerts you before items expire.'),
    OnboardingData(icon: Icons.qr_code_scanner, title: 'Scan or Add Groceries', description: 'Quickly log items by scanning barcodes or adding them manually to track expiry dates.'),
    OnboardingData(icon: Icons.restaurant_menu, title: 'Smart Recipe Suggestions', description: "Stop wondering what's for dinner. We'll suggest delicious recipes based on what's already in your pantry."),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _skip() => _completeOnboarding();

  void _completeOnboarding() {
    _settings.completeOnboarding();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (_currentPage > 0) GestureDetector(onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), child: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface, size: 20)) else const SizedBox(width: 20),
            GestureDetector(onTap: _skip, child: Text('Skip', style: TextStyle(color: _currentPage == _pages.length - 1 ? colorScheme.onSurface.withValues(alpha: 0.5) : colorScheme.primary, fontSize: 16))),
          ])),
          Expanded(child: PageView.builder(controller: _pageController, onPageChanged: (index) => setState(() => _currentPage = index), itemCount: _pages.length, itemBuilder: (context, index) => _buildPage(_pages[index], colorScheme))),
          Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: index == _currentPage ? 24 : 8, height: 8, decoration: BoxDecoration(color: index == _currentPage ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)))))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), child: GestureDetector(onTap: _nextPage, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)), if (_currentPage < _pages.length - 1) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward, color: Colors.black, size: 18)]])))),
        ]),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, ColorScheme colorScheme) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 200, height: 200, decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10)]), child: Center(child: Icon(data.icon, color: colorScheme.primary, size: 80))),
      const SizedBox(height: 48),
      Text(data.title, style: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(data.description, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, height: 1.5), textAlign: TextAlign.center),
    ]));
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  OnboardingData({required this.icon, required this.title, required this.description});
}
