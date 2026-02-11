import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';

class StitchOnboardingScreen extends StatefulWidget {
  const StitchOnboardingScreen({super.key});

  @override
  State<StitchOnboardingScreen> createState() => _StitchOnboardingScreenState();
}

class _StitchOnboardingScreenState extends State<StitchOnboardingScreen> {
  final PageController _controller = PageController(initialPage: 0);
  int _currentPage = 0;

  // Colors extracted from Tailwind config
  static const Color primary = Color(0xFF2bee6c); // Neon Green
  static const Color deepCharcoal = Color(0xFF0a0a0a);
  static const Color charcoal = Color(0xFF121212);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingLoginScreen()), 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCharcoal,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.only(top: 24, right: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView Content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildScanItemsSlide(),
                  _buildTrackExpirySlide(),
                  _buildSmartRecipesSlide(),
                ],
              ),
            ),
            
            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDot(active: index == _currentPage, primary: primary)),
            ),
            
            // Action Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _currentPage == 2 ? _navigateToLogin : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: primary.withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 2 ? 'Get Started' : 'Next',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentPage != 2) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.black),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool active, Color? primary}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? primary : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: active ? [BoxShadow(color: primary!.withOpacity(0.5), blurRadius: 8)] : null,
      ),
    );
  }

  // Slide 1: Scan Items
  Widget _buildScanItemsSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic
          SizedBox(
            height: 320,
             child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 80)],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const  Icon(Icons.qr_code_scanner, size: 80, color: primary),
                ),
                Positioned(
                  top: 20, right: 0,
                  child: _buildFloatingIcon(Icons.barcode_reader, -10),
                ),
                Positioned(
                  bottom: 40, left: 10,
                  child: _buildFloatingIcon(Icons.eco, 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Scan or Add Groceries',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quickly log items by scanning barcodes or adding them manually to track expiry dates.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.6),
              fontSize: 17,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  // Slide 2: Track Expiry (Original Implementation)
  Widget _buildTrackExpirySlide() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Graphic (Reused from previous implementation)
            SizedBox(
              height: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 192, height: 192,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: primary, blurRadius: 60, spreadRadius: 0)],
                    ),
                  ),
                  Transform.rotate(
                    angle: -0.035, 
                    child: Container(
                      width: 240, height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            decoration: const BoxDecoration(color: Color(0xFF252525), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                             child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle))),
                              ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: GridView.count(
                                crossAxisCount: 7, mainAxisSpacing: 12, crossAxisSpacing: 12,
                                children: List.generate(14, (index) {
                                  if (index == 2) return Container(decoration: BoxDecoration(color: primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: primary.withOpacity(0.5))), child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: primary, shape: BoxShape.circle))));
                                  return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)));
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(right: 20, top: 60, child: _buildFloatingIcon(Icons.notifications_active, 15)),
                ],
              ),
            ),
             const SizedBox(height: 32),
            Text(
              'Track Expiry Dates',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pantrix automatically monitors your pantry and alerts you before items expire.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.6),
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
  }

  // Slide 3: Smart Recipes
  Widget _buildSmartRecipesSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           SizedBox(
             height: 320,
             child: Stack(
               alignment: Alignment.center,
               children: [
                 Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 90)],
                    ),
                  ),
                  // Recipe Card 1
                  Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      width: 200, height: 260,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20)],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: const Center(child: Icon(Icons.restaurant_menu, size: 48, color: Colors.white24)),
                            ),
                          ),
                          Expanded(flex: 2, child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5))),
                                const SizedBox(height: 8),
                                Container(width: 120, height: 8, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                   Positioned(bottom: 20, right: 10, child: _buildFloatingIcon(Icons.thumb_up, 10)),
               ],
             ),
           ),
           const SizedBox(height: 32),
            Text(
              'Smart Recipe Suggestions',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stop wondering what\'s for dinner. We\'ll suggest delicious recipes based on what\'s already in your pantry.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.6),
                fontSize: 17,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, double rotateAngle) {
     return Transform.rotate(
      angle: rotateAngle * 3.14 / 180,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Icon(icon, color: primary, size: 28),
      ),
    );
  }
}
