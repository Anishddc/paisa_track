import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';

class UserRepository {
  static const String _userProfileBoxName = 'user_profile';
  static const String _loginStreakKey = 'login_streak';
  static const String _lastLoginDateKey = 'last_login_date';
  static const String _hasNewFeaturesKey = 'has_new_features';
  
  // Singleton instance
  static final UserRepository _instance = UserRepository._internal();
  
  // Factory constructor
  factory UserRepository() {
    return _instance;
  }
  
  // Private constructor
  UserRepository._internal();
  
  final DatabaseService _databaseService = DatabaseService();
  
  // Check if user profile exists
  Future<bool> hasUserProfile() async {
    final profile = await getUserProfile();
    return profile != null;
  }
  
  // Get current user profile
  Future<UserProfileModel?> getUserProfile() async {
    final box = await Hive.openBox<UserProfileModel>(_userProfileBoxName);
    if (box.isEmpty) {
      return null;
    }
    return box.getAt(0);
  }
  
  // Get the user's currency type
  Future<CurrencyType> getUserCurrencyType() async {
    final userProfile = await getUserProfile();
    final currencyCode = userProfile?.defaultCurrencyCode ?? 'USD';
    return CurrencyType.fromCode(currencyCode);
  }
  
  // Update user profile
  Future<void> updateUserProfile(UserProfileModel profile) async {
    await saveUserProfile(profile);
  }
  
  // Create new user profile
  Future<void> createUserProfile(UserProfileModel userProfile) async {
    final userBox = _databaseService.userProfileBox;
    await userBox.add(userProfile);
  }
  
  // Save user profile (create or update)
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final box = await Hive.openBox<UserProfileModel>(_userProfileBoxName);
    if (box.isEmpty) {
      await box.add(profile);
    } else {
      await box.putAt(0, profile);
    }
  }
  
  // Update user name
  Future<void> updateUserName(String name) async {
    final profile = await getUserProfile();
    if (profile != null) {
      profile.name = name;
      await saveUserProfile(profile);
    }
  }
  
  // Update user profile image
  Future<void> updateProfileImage(String? imagePath) async {
    final user = await getUserProfile();
    if (user != null) {
      final updatedUser = user.copyWith(profileImagePath: imagePath);
      await updateUserProfile(updatedUser);
    }
  }
  
  // Update currency
  Future<void> updateCurrency(String currencyCode) async {
    final profile = await getUserProfile();
    if (profile != null) {
      profile.defaultCurrencyCode = currencyCode;
      await saveUserProfile(profile);
    }
  }
  
  // Update default currency
  Future<void> updateDefaultCurrency(String currencyCode) async {
    await updateCurrency(currencyCode);
  }
  
  // Update locale
  Future<void> updateLocale(String locale) async {
    final user = await getUserProfile();
    if (user != null) {
      final updatedUser = user.copyWith(locale: locale);
      await updateUserProfile(updatedUser);
    }
  }
  
  // Update theme mode
  Future<void> updateThemeMode(String themeMode) async {
    final profile = await getUserProfile();
    if (profile != null) {
      profile.themeMode = themeMode;
      await saveUserProfile(profile);
    }
  }
  
  // Toggle biometric authentication
  Future<void> toggleBiometricAuth(bool isEnabled) async {
    final user = await getUserProfile();
    if (user != null) {
      final updatedUser = user.copyWith(isBiometricEnabled: isEnabled);
      await updateUserProfile(updatedUser);
    }
  }
  
  // Reset user profile to defaults
  Future<void> resetUserProfile() async {
    final userBox = _databaseService.userProfileBox;
    await userBox.clear();
    await userBox.add(UserProfileModel.createDefault());
  }
  
  // Delete user profile
  Future<void> deleteUserProfile(UserProfileModel user) async {
    final userBox = _databaseService.userProfileBox;
    await userBox.delete(user.id);
  }
  
  Future<String?> saveImageToLocal(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await imageFile.copy('${appDir.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }
  
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
  
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
  }
  
  // Streak tracking methods
  Future<int?> getLoginStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loginStreakKey);
  }
  
  Future<void> saveLoginStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginStreakKey, streak);
  }
  
  Future<DateTime?> getLastLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastLoginDateKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  
  Future<void> saveLastLoginDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastLoginDateKey, date.millisecondsSinceEpoch);
  }
  
  // Notification methods
  Future<bool?> hasNewFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasNewFeaturesKey);
  }
  
  Future<void> markFeaturesAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasNewFeaturesKey, false);
  }
  
  Future<void> setNewFeaturesAvailable(bool available) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasNewFeaturesKey, available);
  }
} 