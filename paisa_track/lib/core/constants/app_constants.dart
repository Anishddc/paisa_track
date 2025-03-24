class AppConstants {
  // App Info
  static const String appName = 'Paisa Track';
  static const String appVersion = '1.0.0';
  
  // Database Constants
  static const String databaseName = 'paisa_track_db';
  static const int databaseVersion = 1;
  
  // Hive Boxes
  static const String userProfileBox = 'userProfile';
  static const String accountsBox = 'accounts';
  static const String categoriesBox = 'categories';
  static const String transactionsBox = 'transactions';
  static const String budgetsBox = 'budgets';
  static const String settingsBox = 'settings';
  
  // Hive Type IDs
  static const int userProfileTypeId = 0;
  static const int accountTypeId = 1;
  static const int transactionTypeId = 2;
  static const int categoryTypeId = 3;
  static const int budgetTypeId = 4;
  static const int currencyTypeId = 5;
  static const int countryTypeId = 6;
  
  // Hive Type IDs for Models
  static const int accountModelId = 10;
  static const int categoryModelId = 11;
  static const int transactionModelId = 12;
  
  // SharedPreferences Keys
  static const String isFirstLaunchKey = 'isFirstLaunch';
  static const String themeKey = 'theme';
  static const String localeKey = 'locale';
  
  // Default Values
  static const List<String> defaultCurrencies = [
    'USD', 'EUR', 'GBP', 'INR', 'JPY', 'CNY', 'CAD', 'AUD'
  ];
  
  // API Constants
  static const String apiBaseUrl = 'https://example.com/api';
  static const int apiTimeout = 30; // in seconds
  
  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableDarkMode = true;
  static const bool enableNotifications = true;
  
  // Date Formats
  static const String dateFormatFull = 'EEEE, MMMM d, y';
  static const String dateFormatMedium = 'MMM d, y';
  static const String dateFormatShort = 'MM/dd/yyyy';
  static const String timeFormat = 'h:mm a';
  
  // Animation Durations
  static const int animationDurationShort = 200; // in milliseconds
  static const int animationDurationMedium = 350; // in milliseconds
  static const int animationDurationLong = 500; // in milliseconds
  
  // Update this value to match the new file name
  static const String currencyEnumFile = 'currency_type.g.dart';
} 