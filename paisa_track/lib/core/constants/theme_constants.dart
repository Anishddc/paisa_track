import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/themes/light_theme.dart';
import 'package:paisa_track/core/themes/dark_theme.dart';

class ThemeConstants {
  static const MaterialColor primaryIndigo = MaterialColor(
    0xFF4F46E5, // Updated to modern indigo
    <int, Color>{
      50: Color(0xFFEEF2FF),
      100: Color(0xFFE0E7FF),
      200: Color(0xFFC7D2FE),
      300: Color(0xFFA5B4FC),
      400: Color(0xFF818CF8),
      500: Color(0xFF4F46E5), // Primary indigo
      600: Color(0xFF4338CA),
      700: Color(0xFF3730A3),
      800: Color(0xFF312E81),
      900: Color(0xFF1E1B4B),
    },
  );

  // Use the theme data from our theme files
  static final ThemeData lightTheme = lightThemeData;
  static final ThemeData darkTheme = darkThemeData;
} 