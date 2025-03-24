import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';

final ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ColorConstants.primaryColor,
    brightness: Brightness.light,
    primary: ColorConstants.primaryColor,
    secondary: ColorConstants.accentColor,
    tertiary: ColorConstants.accentLightColor,
    surface: ColorConstants.cardLightColor,
    background: ColorConstants.scaffoldLightColor,
    error: ColorConstants.errorColor,
  ),
  primaryColor: ColorConstants.primaryColor,
  scaffoldBackgroundColor: ColorConstants.scaffoldLightColor,
  cardColor: ColorConstants.cardLightColor,
  dividerColor: const Color(0xFFE5E7EB),
  
  appBarTheme: AppBarTheme(
    elevation: 0,
    backgroundColor: ColorConstants.scaffoldLightColor,
    foregroundColor: ColorConstants.primaryTextColor,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ColorConstants.primaryTextColor,
    ),
    iconTheme: const IconThemeData(
      color: ColorConstants.primaryColor,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorConstants.primaryColor,
      foregroundColor: ColorConstants.lightTextColor,
      elevation: 0,
      shadowColor: ColorConstants.primaryColor.withOpacity(0.3),
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
      foregroundColor: ColorConstants.primaryColor,
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
      foregroundColor: ColorConstants.primaryColor,
      side: const BorderSide(color: ColorConstants.primaryColor),
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
    foregroundColor: ColorConstants.lightTextColor,
    elevation: 4,
    splashColor: ColorConstants.accentLightColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
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
      borderSide: const BorderSide(color: ColorConstants.primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorConstants.errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: TextStyle(
      color: ColorConstants.secondaryTextColor.withOpacity(0.7),
      fontSize: 15,
    ),
    labelStyle: const TextStyle(
      color: ColorConstants.secondaryTextColor,
      fontSize: 16,
    ),
  ),
  
  cardTheme: CardTheme(
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: ColorConstants.cardLightColor,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    clipBehavior: Clip.antiAlias,
  ),
  
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: ColorConstants.cardLightColor,
    selectedItemColor: ColorConstants.primaryColor,
    unselectedItemColor: ColorConstants.secondaryTextColor,
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
  
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: ColorConstants.primaryTextColor,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: ColorConstants.primaryTextColor,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: ColorConstants.primaryTextColor,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: ColorConstants.primaryTextColor,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      color: ColorConstants.primaryTextColor,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: ColorConstants.primaryTextColor,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: ColorConstants.primaryTextColor,
    ),
    bodyMedium: TextStyle(
      color: ColorConstants.secondaryTextColor,
    ),
  ),
); 