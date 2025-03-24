import 'package:flutter/foundation.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  
  UserProfileModel? _user;
  bool _isAuthenticated = false;
  
  bool get isAuthenticated => _isAuthenticated;
  UserProfileModel? get user => _user;
  
  Future<void> initialize() async {
    try {
      final userProfile = await _userRepository.getUserProfile();
      if (userProfile != null) {
        _user = userProfile;
        _isAuthenticated = true;
      }
      notifyListeners();
    } catch (e) {
      print('Error initializing auth provider: $e');
    }
  }
  
  Future<void> login() async {
    try {
      final userProfile = await _userRepository.getUserProfile();
      if (userProfile != null) {
        _user = userProfile;
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error logging in: $e');
    }
  }
  
  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
  }
  
  Future<void> updateUser(UserProfileModel updatedUser) async {
    try {
      await _userRepository.updateUserProfile(updatedUser);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
    }
  }
} 