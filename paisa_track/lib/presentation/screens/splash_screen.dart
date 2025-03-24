import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/constants/text_constants.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:paisa_track/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:paisa_track/presentation/screens/user_setup/user_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paisa_track/data/models/app_icon.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Check if it's first launch
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(AppConstants.isFirstLaunchKey) ?? true;
    
    // Check if user profile exists
    final userRepo = UserRepository();
    final userProfile = await userRepo.getUserProfile();
    
    if (isFirstLaunch) {
      // First time launch - show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            onFinish: () {
              // This callback is not used since the OnboardingScreen handles navigation
            },
          ),
        ),
      );
    } else if (userProfile == null) {
      // User hasn't set up profile yet - show user setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserSetupScreen()),
      );
    } else {
      // User is already set up - go to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon foreground on white background
            SizedBox(
              width: 180,
              height: 180,
              child: Image.asset(
                'assets/images/foreground.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              TextConstants.appName,
              style: const TextStyle(
                color: Color(0xFF2554C7), // Blue text on white background
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Developed by Anessh (Ozric)',
              style: TextStyle(
                color: Color(0xFF4A4A4A), // Dark gray text for subtitle
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 60),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2554C7)), // Blue spinner on white background
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 