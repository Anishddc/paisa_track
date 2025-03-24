import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/themes/app_theme.dart';
import 'package:paisa_track/core/themes/light_theme.dart';
import 'package:paisa_track/core/themes/dark_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString().split('.').last);
    
    notifyListeners();
  }
  
  // Light theme settings - use lightThemeData from core/themes/light_theme.dart
  ThemeData get lightTheme => lightThemeData;
  
  // Dark theme settings - use darkThemeData from core/themes/dark_theme.dart
  ThemeData get darkTheme => darkThemeData;
} 