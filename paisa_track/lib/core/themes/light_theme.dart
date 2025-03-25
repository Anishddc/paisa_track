import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';

final ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: ColorConstants.primaryColor,
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  colorScheme: ColorScheme.light(
    primary: ColorConstants.primaryColor,
    secondary: ColorConstants.accentColor,
    surface: const Color(0xFFF8F9FA),
    background: const Color(0xFFF8F9FA),
    error: ColorConstants.errorColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFF8F9FA),
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardTheme(
    color: const Color(0xFFF8F9FA),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFFF8F9FA),
    selectedItemColor: ColorConstants.primaryColor,
    unselectedItemColor: Colors.black,
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: const Color(0xFFF8F9FA),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: const Color(0xFFF8F9FA),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: const Color(0xFFF8F9FA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.withOpacity(0.1),
    thickness: 1,
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