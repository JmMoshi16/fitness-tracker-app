import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── PREMIUM COLOR SYSTEM ─────────────────────────────────────────────────────
// Orange Gradient (Primary Accent)
const kOrange      = Color(0xFFFF6B35);
const kOrangeLight = Color(0xFFFF8C5A);
const kOrangeDark  = Color(0xFFE04E1A);
const kOrangeGlow  = Color(0xFFFF6B35);

// Dark Mode (Premium Black)
const kDarkBg      = Color(0xFF0D0D0D);  // Deep black
const kDarkSurface = Color(0xFF1A1A1A);  // Slightly lighter
const kDarkCard    = Color(0xFF1E1E1E);  // Card background
const kDarkBorder  = Color(0xFF2A2A2A);  // Subtle borders
const kDarkText    = Color(0xFFFFFFFF);  // Pure white
const kDarkSubtext = Color(0xFF9E9E9E);  // Gray text
const kDarkTertiary = Color(0xFF666666); // Tertiary text

// Light Mode (Clean White)
const kLightBg      = Color(0xFFF8F9FA);  // Soft gray bg
const kLightSurface = Color(0xFFFFFFFF);  // Pure white
const kLightCard    = Color(0xFFFFFFFF);  // Card white
const kLightBorder  = Color(0xFFE5E7EB);  // Light border
const kLightText    = Color(0xFF1A1A1A);  // Almost black
const kLightSubtext = Color(0xFF6B7280);  // Gray text
const kLightTertiary = Color(0xFF9CA3AF); // Tertiary text

// Workout Type Colors
const kCardio      = Color(0xFFEF5350);
const kStrength    = Color(0xFF42A5F5);
const kFlexibility = Color(0xFF66BB6A);
const kHIIT        = Color(0xFFFF7043);
const kSports      = Color(0xFFAB47BC);
const kOther       = Color(0xFF78909C);

// Status Colors
const kSuccess = Color(0xFF10B981);
const kWarning = Color(0xFFF59E0B);
const kError   = Color(0xFFEF4444);
const kInfo    = Color(0xFF3B82F6);

class AppTheme {
  // ── DARK THEME (PREMIUM) ───────────────────────────────────────────────────
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kDarkBg,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: kOrange,
      secondary: kOrangeLight,
      surface: kDarkSurface,
      onPrimary: Colors.white,
      onSurface: kDarkText,
      error: kError,
    ),
    cardColor: kDarkCard,
    dividerColor: kDarkBorder,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkBg,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(color: kDarkText, size: 24),
      titleTextStyle: TextStyle(
        color: kDarkText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kOrange,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    
    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDarkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kDarkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kError, width: 2),
      ),
      labelStyle: const TextStyle(color: kDarkSubtext, fontSize: 14),
      hintStyle: const TextStyle(color: kDarkTertiary, fontSize: 14),
      errorStyle: const TextStyle(color: kError, fontSize: 12),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: kDarkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kDarkSurface,
      selectedItemColor: kOrange,
      unselectedItemColor: kDarkSubtext,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // ── LIGHT THEME (CLEAN) ────────────────────────────────────────────────────
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: kLightBg,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: kOrange,
      secondary: kOrangeLight,
      surface: kLightSurface,
      onPrimary: Colors.white,
      onSurface: kLightText,
      error: kError,
    ),
    cardColor: kLightCard,
    dividerColor: kLightBorder,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: kLightBg,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: kLightText, size: 24),
      titleTextStyle: TextStyle(
        color: kLightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kOrange,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    
    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kLightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kLightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kError, width: 2),
      ),
      labelStyle: const TextStyle(color: kLightSubtext, fontSize: 14),
      hintStyle: const TextStyle(color: kLightTertiary, fontSize: 14),
      errorStyle: const TextStyle(color: kError, fontSize: 12),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: kLightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kLightSurface,
      selectedItemColor: kOrange,
      unselectedItemColor: kLightSubtext,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
  
  // ── HELPER METHODS ──────────────────────────────────────────────────────────
  static Color getWorkoutColor(String type) {
    switch (type) {
      case 'Cardio': return kCardio;
      case 'Strength': return kStrength;
      case 'Flexibility': return kFlexibility;
      case 'HIIT': return kHIIT;
      case 'Sports': return kSports;
      default: return kOther;
    }
  }
  
  static IconData getWorkoutIcon(String type) {
    switch (type) {
      case 'Cardio': return Icons.directions_run_rounded;
      case 'Strength': return Icons.fitness_center_rounded;
      case 'Flexibility': return Icons.self_improvement_rounded;
      case 'HIIT': return Icons.flash_on_rounded;
      case 'Sports': return Icons.sports_rounded;
      default: return Icons.sports_gymnastics_rounded;
    }
  }
}
