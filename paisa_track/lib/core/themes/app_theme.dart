import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/themes/dark_theme.dart';
import 'package:paisa_track/core/themes/light_theme.dart';

class AppTheme {
  static ThemeData lightTheme = lightThemeData;
  static ThemeData darkTheme = darkThemeData;
  
  static ThemeMode getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? ColorConstants.cardLightColor
        : ColorConstants.cardDarkColor;
  }
  
  static Color getScaffoldColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? ColorConstants.scaffoldLightColor
        : ColorConstants.scaffoldDarkColor;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? ColorConstants.primaryTextColor
        : ColorConstants.lightTextColor;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? ColorConstants.secondaryTextColor
        : ColorConstants.lightTextColor.withOpacity(0.7);
  }
} 