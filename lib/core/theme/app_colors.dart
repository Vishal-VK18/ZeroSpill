import 'package:flutter/material.dart';

class AppColors {
  // ============================================
  // LIGHT MODE THEME TOKENS
  // ============================================
  
  // Primary - Exact Accent Green
  static const Color primary = Color(0xFF22C55E);           // Exact green #22C55E
  static const Color primaryLight = Color(0xFF4ADE80);      // Lighter green for hover/active states
  static const Color primaryDark = Color(0xFF16A34A);       // Darker green for pressed states
  
  // Accent - Use Primary variants instead of Purple
  static const Color accent = Color(0xFF1B5F52);
  static const Color accentLight = Color(0xFF2A7A6A);
  
  // Accent - Subtle tertiary accent
  static const Color accent = Color(0xFF9B7FC9);            // Purple accent
  static const Color accentLight = Color(0xFFBDA5DB);       // Light purple
  
  // Background - Soft neutral off-white
  static const Color background = Color(0xFFF8F8F6);        // Soft off-white (not pure white)
  static const Color surface = Color(0xFFFFFFFF);           // White for cards with subtle elevation
  
  // Text colors - Near-black and muted grays
  static const Color textPrimary = Color(0xFF1A1A1A);       // Near-black (not pure black)
  static const Color textSecondary = Color(0xFF5A5A5A);     // Muted gray
  static const Color textTertiary = Color(0xFF8A8A8A);      // Light gray for tertiary text
  
  // Dividers and borders
  static const Color divider = Color(0xFFE0E0E0);           // Subtle but visible divider
  static const Color border = Color(0xFFE8E8E8);            // Soft neutral gray border
  
  // Functional colors
  static const Color success = Color(0xFF22C55E);           // Exact green for success
  static const Color error = Color(0xFFD84848);             // Error red
  static const Color warning = Color(0xFFF5A623);           // Warning orange
  
  // Icon backgrounds - Light green tint derived from #22C55E
  static const Color iconBackground = Color(0xFFDCFCE7);    // Light green tint (low opacity from #22C55E)
  static const Color iconForeground = Color(0xFF22C55E);    // Exact green #22C55E
  
  // Toggle colors
  static const Color toggleOnTrack = Color(0xFF22C55E);     // Exact green track when ON
  static const Color toggleOffTrack = Color(0xFFE0E0E0);    // Light gray track when OFF
  
  // ============================================
  // DARK MODE THEME TOKENS
  // ============================================
  
  // Primary - Exact Accent Green (same for dark mode)
  static const Color darkPrimary = Color(0xFF22C55E);       // EXACTLY #22C55E
  static const Color darkPrimaryLight = Color(0xFF4ADE80);  // Lighter for hover states
  static const Color darkPrimaryDark = Color(0xFF16A34A);   // Darker for pressed states
  
  // Secondary - Warm neutral for dark mode
  static const Color darkSecondary = Color(0xFFE8D5A8);     // Soft cream (same as light)
  static const Color darkSecondaryLight = Color(0xFFF5EDD4);// Light cream
  
  // Accent - Purple for dark mode
  static const Color darkAccent = Color(0xFFBDA5DB);        // Light purple
  static const Color darkAccentLight = Color(0xFFCDB5EB);   // Even lighter purple
  
  // Background - Pure black
  static const Color darkBackground = Color(0xFF000000);    // Pure black
  static const Color darkSurface = Color(0xFF1E1E1E);       // Elevated dark gray (clearly distinct)
  
  // Text colors - Off-white and muted grays
  static const Color darkTextPrimary = Color(0xFFE8E8E8);   // Off-white (not pure white)
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Muted gray
  static const Color darkTextTertiary = Color(0xFF808080);  // Darker gray for tertiary
  
  // Dividers and borders - Visible against dark surfaces
  static const Color darkDivider = Color(0xFF2E2E2E);       // Visible dark divider
  static const Color darkBorder = Color(0xFF2A2A2A);        // Dark border
  
  // Icon backgrounds - Dark elevated green tint derived from #22C55E
  static const Color darkIconBackground = Color(0xFF14532D);// Dark green tint from #22C55E
  static const Color darkIconForeground = Color(0xFF22C55E);// EXACTLY #22C55E
  
  // Toggle colors
  static const Color darkToggleOnTrack = Color(0xFF22C55E); // EXACTLY #22C55E when ON
  static const Color darkToggleOffTrack = Color(0xFF3A3A3A);// Dark gray track when OFF
  
  AppColors._();
}
