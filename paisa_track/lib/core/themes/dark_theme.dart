import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';

final ThemeData darkThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ColorConstants.primaryColor,
    brightness: Brightness.dark,
    primary: ColorConstants.primaryLightColor,
    secondary: ColorConstants.accentLightColor,
    tertiary: ColorConstants.accentColor,
    surface: const Color(0xFF1E293B),
    background: const Color(0xFF0F172A),
    error: ColorConstants.errorColor,
    onSurface: ColorConstants.lightTextColor,
    onBackground: ColorConstants.lightTextColor,
    surfaceVariant: const Color(0xFF2C3E50),
    onSurfaceVariant: ColorConstants.lightTextColor.withOpacity(0.9),
  ),
  primaryColor: ColorConstants.primaryLightColor,
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  cardColor: const Color(0xFF1E293B),
  dividerColor: const Color(0xFF334155),
  
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Color(0xFF0F172A),
    foregroundColor: ColorConstants.lightTextColor,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ColorConstants.lightTextColor,
      letterSpacing: 0.2,
    ),
    iconTheme: IconThemeData(
      color: ColorConstants.primaryLightColor,
      size: 24,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorConstants.primaryLightColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: ColorConstants.primaryLightColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ColorConstants.primaryLightColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorConstants.primaryLightColor,
      side: const BorderSide(color: ColorConstants.primaryLightColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: ColorConstants.accentColor,
    foregroundColor: Colors.white,
    elevation: 4,
    splashColor: ColorConstants.accentLightColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E293B),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorConstants.primaryLightColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorConstants.errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: TextStyle(
      color: ColorConstants.lightTextColor.withOpacity(0.5),
      fontSize: 15,
    ),
    labelStyle: TextStyle(
      color: ColorConstants.lightTextColor.withOpacity(0.7),
      fontSize: 16,
    ),
  ),
  
  cardTheme: CardTheme(
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: const Color(0xFF1E293B),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    clipBehavior: Clip.antiAlias,
  ),
  
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0F172A),
    selectedItemColor: ColorConstants.primaryLightColor,
    unselectedItemColor: Color(0xFF94A3B8),
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
    ),
  ),
  
  dialogTheme: DialogTheme(
    backgroundColor: const Color(0xFF1E293B),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: TextStyle(
      color: ColorConstants.lightTextColor.withOpacity(0.9),
      fontSize: 16,
    ),
  ),
  
  listTileTheme: const ListTileThemeData(
    iconColor: ColorConstants.primaryLightColor,
    textColor: ColorConstants.lightTextColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return ColorConstants.primaryLightColor;
      }
      return Colors.grey;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return ColorConstants.primaryLightColor.withOpacity(0.5);
      }
      return Colors.grey.withOpacity(0.5);
    }),
  ),
  
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF334155),
    disabledColor: Colors.grey[700],
    selectedColor: ColorConstants.primaryLightColor,
    secondarySelectedColor: ColorConstants.accentLightColor,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    labelStyle: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontSize: 14,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
    brightness: Brightness.dark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  
  textTheme: TextTheme(
    displayLarge: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: const TextStyle(
      color: ColorConstants.lightTextColor,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: const TextStyle(
      color: ColorConstants.lightTextColor,
    ),
    bodyMedium: TextStyle(
      color: ColorConstants.lightTextColor.withOpacity(0.9),
    ),
    bodySmall: TextStyle(
      color: ColorConstants.lightTextColor.withOpacity(0.7),
      fontSize: 13,
    ),
  ),
); 