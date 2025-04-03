import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/constants/theme_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart' as core_router;
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/presentation/widgets/common/custom_app_bar.dart';
import 'package:paisa_track/presentation/widgets/common/custom_card.dart';
import 'package:paisa_track/presentation/widgets/common/custom_dialog.dart' hide ConfirmationDialog;
import 'package:paisa_track/presentation/widgets/common/error_view.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:paisa_track/providers/theme_provider.dart';
import 'package:paisa_track/providers/currency_provider.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'dart:io' show File, Platform;
import 'dart:math' show sin, pi;
import 'package:paisa_track/presentation/screens/settings/currency_selector_dialog.dart';
import 'package:paisa_track/presentation/screens/settings/country_selector_dialog.dart';
import 'package:paisa_track/presentation/screens/settings/language_selector_dialog.dart';
import 'package:paisa_track/presentation/screens/settings/color_picker_dialog.dart';
import 'package:paisa_track/presentation/screens/profile/profile_edit_screen.dart';
import 'package:paisa_track/presentation/widgets/common/confirmation_dialog.dart';
import 'package:paisa_track/presentation/screens/settings/notification_settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// Wave painter for the divider
class WavePainter extends CustomPainter {
  final Color color;
  
  WavePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final path = Path();
    final waveHeight = 8.0;
    final waveLength = size.width / 10;
    
    path.moveTo(0, size.height / 2);
    
    for (int i = 0; i < 20; i++) {
      path.quadraticBezierTo(
        waveLength * (i + 0.5), 
        size.height / 2 + (i.isEven ? waveHeight : -waveHeight), 
        waveLength * (i + 1), 
        size.height / 2
      );
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ModernSettingsScreen extends StatefulWidget {
  const ModernSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends State<ModernSettingsScreen> with SingleTickerProviderStateMixin {
  final _repository = UserRepository();
  UserProfileModel? _userProfile;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  
  bool _useBiometrics = false;
  bool _isDarkMode = true;
  bool _isDynamicColor = false;
  bool _useSmallFab = false;
  bool _useVerticalAccounts = true;
  
  String _appLanguage = 'English';
  String _currencySign = 'NPR';
  String _dateFormat = 'MM/dd/yyyy';
  String _selectedTheme = 'System';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  int _streakCount = 7;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: ThemeConstants.mediumAnimationDuration,
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _loadUserProfile();
    _loadSettings();
    _checkStreak();
  }
  
  void _loadSettings() {
    // Load from theme provider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _isDarkMode = themeProvider.isDarkMode;
    _isDynamicColor = false;
    
    // Load from currency provider
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    _currencySign = currencyProvider.currencySymbol;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      var profile = await _repository.getUserProfile();
      
      // If no profile exists, create a default one
      if (profile == null) {
        profile = UserProfileModel.createDefault();
        await _repository.saveUserProfile(profile);
      }
      
      setState(() {
        _userProfile = profile;
        _useBiometrics = profile?.isBiometricEnabled ?? false;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load user profile: $e';
      });
    }
  }

  Future<void> _checkStreak() async {
    // In a real app, this would check the last login date and calculate the streak
    // For now, we're just using a placeholder value
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streakCount = prefs.getInt('user_streak') ?? 7;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're accessed from the bottom navigation tab
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final bool fromTab = args != null && 
                        args is Map<String, dynamic> && 
                        args.containsKey('fromTab') && 
                        args['fromTab'] == true;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121214),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121214),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: fromTab ? null : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: LoadingIndicator(),
        ),
      );
    }
    
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF121214),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121214),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: fromTab ? null : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ErrorView(
          message: _errorMessage,
          onRetry: _loadUserProfile,
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: fromTab ? null : IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF0A0A0A), Color(0xFF111111)],
          ),
        ),
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildSettingsSections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1117),
            const Color(0xFF161B22),
            const Color(0xFF21262D),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, core_router.AppRouter.profileEditRoute)
            .then((_) {
              _loadUserProfile();
            }),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _userProfile?.profileImagePath != null && _userProfile!.profileImagePath!.isNotEmpty
                  ? CircleAvatar(
                      radius: 32,
                      backgroundImage: FileImage(File(_userProfile!.profileImagePath!)),
                    )
                  : CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF21262D),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userProfile?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _userProfile?.email ?? 'Update your profile',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Tooltip(
                              message: '$_streakCount day streak! Keep using the app daily to increase your streak.',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$_streakCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('App Settings'),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingItem(
            icon: Icons.color_lens_outlined,
            title: 'Theme',
            subtitle: 'Dark Mode (Default)',
            hasSwitch: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This app only supports Dark Mode'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: _appLanguage,
            onTap: () async {
              final selectedLanguage = await LanguageSelectorDialog.show(
                context: context,
                currentLanguageCode: _userProfile?.locale ?? 'en_US',
              );
              if (selectedLanguage != null) {
                setState(() {
                  _appLanguage = selectedLanguage;
                });
              }
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.attach_money,
            title: 'Currency',
            subtitle: _currencySign,
            onTap: () async {
              final result = await CurrencySelectorDialog.show(
                context: context,
                currentCurrencyCode: _userProfile?.defaultCurrencyCode ?? 'NPR',
              );
              if (result != null) {
                setState(() {
                  _currencySign = result;
                });
                final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
                currencyProvider.setCurrency(result);
              }
            },
          ),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Configure reminders and alerts',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.notificationSettingsRoute),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Secure app with fingerprint/face ID',
            hasSwitch: true,
            switchValue: _useBiometrics,
            onSwitchChanged: (value) {
              _toggleBiometricAuthentication(value);
            },
          ),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Data Management'),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingItem(
            icon: Icons.backup_rounded,
            title: 'Backup & Restore',
            subtitle: 'Backup your data or restore from backup',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.backupRestoreRoute),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.download_rounded,
            title: 'Export Transaction History',
            subtitle: 'Download or share your transactions as PDF',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.transactionHistoryExport),
          ),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('About'),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About App',
            subtitle: 'Version 1.0.0',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.about),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.system_update,
            title: 'Update Settings',
            subtitle: 'Manage app updates and configure sources',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.updateSettingsRoute),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'View privacy policy',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.termsAndPolicyRoute),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.support_outlined,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () => Navigator.pushNamed(context, core_router.AppRouter.supportRoute),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.coffee_outlined,
            title: 'Buy Me a Coffee',
            subtitle: 'Support the developer',
            onTap: () => _showBuyMeACoffeeDialog(),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.share_outlined,
            title: 'Share App',
            subtitle: 'Share Paisa Track with friends',
            onTap: () => _shareApp(),
          ),
        ]),
        
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Paisa Track',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Made with ❤️ from Nepal by Aneesh',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool hasSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF58A6FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasSwitch)
                Switch(
                  value: switchValue,
                  onChanged: onSwitchChanged,
                  activeColor: const Color(0xFF58A6FF),
                  activeTrackColor: const Color(0xFF58A6FF).withOpacity(0.4),
                )
              else if (onTap != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 0,
    );
  }

  Future<void> _toggleBiometricAuthentication(bool value) async {
    if (value) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking biometric availability...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        print('[SETTINGS] Starting biometric check...');
        final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
        print('[SETTINGS] Can check biometrics: $canCheckBiometrics');
        
        final bool isDeviceSupported = await _localAuth.isDeviceSupported();
        print('[SETTINGS] Is device supported: $isDeviceSupported');
        
        if (!canCheckBiometrics || !isDeviceSupported) {
          print('[SETTINGS] Device does not support biometrics');
          _showErrorSnackbar('Biometric authentication is not available on this device.');
          return;
        }
        
        final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
        print('[SETTINGS] Available biometrics: $availableBiometrics');
        
        if (availableBiometrics.isEmpty) {
          print('[SETTINGS] No biometrics enrolled');
          _showErrorSnackbar('No biometrics are enrolled on this device. Please set up fingerprint or face recognition in your device settings.');
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please authenticate to enable biometric login'),
            duration: Duration(seconds: 2),
          ),
        );
        
        print('[SETTINGS] Attempting authentication...');
        
        final bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        
        print('[SETTINGS] Authentication result: $authenticated');
        
        if (!authenticated) {
          print('[SETTINGS] Authentication failed or cancelled');
          _showErrorSnackbar('Authentication failed or cancelled. Biometric authentication was not enabled.');
          return;
        }
        
        print('[SETTINGS] Authentication successful');
      } catch (e) {
        print('[SETTINGS] Error during biometric setup: $e');
        _showErrorSnackbar('Failed to set up biometric authentication: $e');
        return;
      }
    }
    
    print('[SETTINGS] Proceeding to update user profile with biometrics: $value');
    
    if (_userProfile != null) {
      try {
        final updatedProfile = _userProfile!.copyWith(isBiometricEnabled: value);
        print('[SETTINGS] Created updated profile with biometrics: ${updatedProfile.isBiometricEnabled}');
        
        await _repository.saveUserProfile(updatedProfile);
        print('[SETTINGS] Saved profile via repository');
        
        setState(() {
          _useBiometrics = value;
          _userProfile = updatedProfile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
                ? 'Biometric authentication enabled' 
                : 'Biometric authentication disabled'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } catch (e) {
        print('[SETTINGS] Error saving biometric settings: $e');
        _showErrorSnackbar('Failed to update biometric settings: $e');
      }
    } else {
      print('[SETTINGS] User profile is null, cannot save settings');
      _showErrorSnackbar('Cannot save settings: User profile not found.');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF5252),
        ),
      );
    }
  }

  Future<void> _shareApp() async {
    final String appUrl = 'https://play.google.com/store/apps/details?id=com.paisatrack.app';
    final String message = 'Check out Paisa Track - Your Personal Finance Manager!\n\n$appUrl';
    
    try {
      await Share.share(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App shared successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share app'),
            backgroundColor: Color(0xFFE83F5B),
          ),
        );
      }
    }
  }

  Future<void> _showBuyMeACoffeeDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDD00).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.coffee,
                color: Color(0xFFFFDD00),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Buy Me a Coffee',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.coffee,
                  color: Color(0xFFFFDD00),
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Support Paisa Track Development',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If you enjoy using Paisa Track, please consider buying me a coffee. Your support helps me continue improving the app with new features and updates!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final Uri coffeeUrl = Uri.parse('https://www.buymeacoffee.com/paisatrack');
              
              if (await canLaunchUrl(coffeeUrl)) {
                await launchUrl(coffeeUrl, mode: LaunchMode.externalApplication);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open link'),
                    backgroundColor: Color(0xFFE83F5B),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFDD00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Buy Coffee', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }
} 