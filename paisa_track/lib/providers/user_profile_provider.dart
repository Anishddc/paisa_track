import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  
  UserProfileModel? _userProfile;
  
  UserProfileModel? get userProfile => _userProfile;
  
  Future<void> initialize() async {
    try {
      _userProfile = await _userRepository.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Error initializing user profile provider: $e');
    }
  }
  
  Future<void> updateUserProfile(UserProfileModel updatedProfile) async {
    try {
      await _userRepository.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
  
  Future<void> updateUserName(String name) async {
    try {
      if (_userProfile != null) {
        await _userRepository.updateUserName(name);
        _userProfile = await _userRepository.getUserProfile();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user name: $e');
    }
  }
  
  Future<void> updateProfileImage(String path) async {
    try {
      if (_userProfile != null) {
        await _userRepository.updateProfileImage(path);
        _userProfile = await _userRepository.getUserProfile();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating profile image: $e');
    }
  }
  
  Future<String?> saveImageToLocal(File imageFile) async {
    try {
      final imagePath = await _userRepository.saveImageToLocal(imageFile);
      
      if (imagePath != null && _userProfile != null) {
        await _userRepository.updateProfileImage(imagePath);
        _userProfile = await _userRepository.getUserProfile();
        notifyListeners();
      }
      
      return imagePath;
    } catch (e) {
      print('Error saving image to local: $e');
      return null;
    }
  }
  
  Future<void> updateCurrencyCode(String currencyCode) async {
    try {
      if (_userProfile != null) {
        await _userRepository.updateDefaultCurrency(currencyCode);
        _userProfile = await _userRepository.getUserProfile();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating currency code: $e');
    }
  }
  
  Future<void> updateThemeMode(String themeMode) async {
    try {
      if (_userProfile != null) {
        await _userRepository.updateThemeMode(themeMode);
        _userProfile = await _userRepository.getUserProfile();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating theme mode: $e');
    }
  }
  
  Future<void> updateWeeklyGoalPercentage(int percentage) async {
    try {
      if (_userProfile != null) {
        final updatedProfile = _userProfile!.copyWith(weeklyGoalPercentage: percentage);
        await _userRepository.updateUserProfile(updatedProfile);
        _userProfile = updatedProfile;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating weekly goal percentage: $e');
    }
  }
  
  Future<void> toggleNotifications(bool enabled) async {
    try {
      if (_userProfile != null) {
        final updatedProfile = _userProfile!.copyWith(notificationsEnabled: enabled);
        await _userRepository.updateUserProfile(updatedProfile);
        _userProfile = updatedProfile;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling notifications: $e');
    }
  }
} 