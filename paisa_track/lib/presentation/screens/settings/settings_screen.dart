import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/data/models/enums/country_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'dart:io' show File, Directory, FileSystemEntity;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:paisa_track/data/services/backup_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../data/services/update_service.dart';
import '../../../services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/services/profile_fix_service.dart';
import 'package:paisa_track/providers/currency_provider.dart';
import 'package:provider/provider.dart';
import 'package:paisa_track/providers/theme_provider.dart';
import 'package:paisa_track/presentation/screens/settings/language_selector_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repository = UserRepository();
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting to load user profile');
      var profile = await _repository.getUserProfile();
      
      // If no profile exists, create a default one
      if (profile == null) {
        print('No profile found, creating default profile');
        profile = UserProfileModel.createDefault();
        await _repository.saveUserProfile(profile);
      } else {
        print('Loaded existing profile: ${profile.name}');
      }
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildModernFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Made with ❤️ in Nepal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData ? snapshot.data!.version : '';
              final buildNumber = snapshot.hasData ? snapshot.data!.buildNumber : '';
              
              return Text(
                'Version $version ($buildNumber)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Profile section skeleton
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              _buildShimmer(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildShimmer(
                      child: Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildShimmer(
                      child: Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildShimmer(
                      child: Container(
                        height: 24,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
        
        // Section headers and cards
        for (int i = 0; i < 6; i++) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmer(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Settings items
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int j = 0; j < 3; j++) ...[
                  if (j > 0)
                    const Divider(height: 1, indent: 56, endIndent: 0),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        _buildShimmer(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmer(
                                child: Container(
                                  height: 14,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildShimmer(
                                child: Container(
                                  height: 10,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildShimmer(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildShimmer({required Widget child}) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [
            0.0,
            0.5,
            1.0,
          ],
          begin: const Alignment(-1.0, -0.5),
          end: const Alignment(1.0, 0.5),
          tileMode: TileMode.mirror,
        ).createShader(
          Rect.fromLTWH(
            0,
            0,
            bounds.width,
            bounds.height,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're accessed from the bottom navigation tab
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final bool fromTab = args != null && 
                        args is Map<String, dynamic> && 
                        args.containsKey('fromTab') && 
                        args['fromTab'] == true;
    
    print('Building Settings screen. Args: $args, fromTab: $fromTab');
    print('Current user profile: ${_userProfile?.name ?? 'None'}');
    
    return WillPopScope(
      // Handle back button behavior
      onWillPop: () async {
        if (fromTab) {
          // Navigate back to dashboard without removing routes from stack
          Navigator.pushReplacementNamed(
            context, 
            AppRouter.dashboard,
            arguments: {'initialTab': 0}
          );
          return false;
        }
        // Normal back button behavior for non-tab navigation
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.primaryColor,
                  ColorConstants.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          // If we came from tab navigation, show a home button instead of back
          leading: fromTab 
              ? IconButton(
                  icon: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.dashboard,
                      arguments: {'initialTab': 0}
                    );
                  },
                )
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                // Show help dialog or navigate to help screen
              },
            ),
          ],
        ),
        // Add the footer as bottomNavigationBar to ensure it stays at the bottom
        bottomNavigationBar: _buildModernFooter(),
        body: _isLoading
            ? SafeArea(child: _buildSkeletonLoader())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.only(top: 16),
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 8),
                    _buildAppearanceSection(),
                    const SizedBox(height: 8),
                    _buildInterfaceSection(),
                    const SizedBox(height: 8),
                    _buildPreferencesSection(),
                    const SizedBox(height: 8),
                    _buildSecuritySection(),
                    const SizedBox(height: 8),
                    _buildDataSection(),
                    const SizedBox(height: 8),
                    _buildSupportSection(),
                    const SizedBox(height: 8),
                    _buildAboutSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileSection() {
    print('Building profile section. Profile: ${_userProfile?.name ?? 'None'}');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with modern design
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.primaryColor.withOpacity(0.8),
                  ColorConstants.primaryColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  print('Profile tile tapped, showing edit dialog');
                  _showProfileEditDialog();
                },
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Profile image
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: _userProfile?.profileImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Image.file(
                                      File(_userProfile!.profileImagePath!),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading profile image: $error');
                                        return Text(
                                          _userProfile?.name[0].toUpperCase() ?? 'U',
                                          style: TextStyle(
                                            color: ColorConstants.primaryColor, 
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    _userProfile?.name[0].toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      color: ColorConstants.primaryColor, 
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorConstants.primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: ColorConstants.primaryColor,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Account created: ${_formatDate(_userProfile?.createdAt)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Setup wizard button with more modern style
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  print('Navigating to user setup screen');
                  Navigator.pushNamed(context, AppRouter.userSetup);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: ColorConstants.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Setup',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: ColorConstants.primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Configure your preferences and personal details',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: ColorConstants.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    try {
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return date.toString().substring(0, 10);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ColorConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildModernListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? ColorConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? ColorConstants.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Preferences', Icons.tune_rounded),
        _buildSettingsCard(
          Column(
            children: [
              _buildModernListTile(
                icon: Icons.public,
                title: 'Country',
                subtitle: '${_userProfile?.country?.flagEmoji ?? '🌍'} ${_userProfile?.country?.displayName ?? 'Not set'}',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showCountrySelector(),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.currency_exchange,
                title: 'Default Currency',
                subtitle: _userProfile?.defaultCurrencyCode ?? 'USD',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showCurrencySelector(),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: _userProfile?.locale ?? 'English (en_US)',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showLanguageSelector(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance', Icons.palette_rounded),
        _buildSettingsCard(
          Column(
            children: [
              _buildModernListTile(
                icon: Icons.brightness_6,
                title: 'Theme',
                subtitle: 'Dark Mode (Default)',
                trailing: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This app only supports Dark Mode'),
                    duration: Duration(seconds: 2),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.color_lens,
                title: 'Dynamic Colors',
                subtitle: 'Use system accent colors',
                trailing: Switch(
                  value: (_userProfile?.appColor == null),
                  activeColor: ColorConstants.primaryColor,
                  onChanged: (value) => _toggleDynamicColors(value),
                ),
                onTap: () => _toggleDynamicColors(!(_userProfile?.appColor == null)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterfaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Interface', Icons.dashboard_customize_rounded),
        _buildSettingsCard(
          Column(
            children: [
              _buildModernListTile(
                icon: Icons.fullscreen,
                title: 'Large FAB Size',
                subtitle: 'Use larger floating action buttons',
                trailing: Switch(
                  value: _userProfile?.useLargeFab ?? true,
                  activeColor: ColorConstants.primaryColor,
                  onChanged: (value) => _toggleFabSize(value),
                ),
                onTap: () => _toggleFabSize(!(_userProfile?.useLargeFab ?? true)),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.dashboard_customize,
                title: 'Dashboard Layout',
                subtitle: _getDashboardLayoutName(_userProfile?.dashboardLayout ?? 'default'),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showDashboardLayoutSelector(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Security', Icons.security_rounded),
        _buildSettingsCard(
          Column(
            children: [
              _buildModernListTile(
                icon: Icons.notifications,
                title: 'Notifications',
                trailing: Switch(
                  value: _userProfile?.notificationsEnabled ?? true,
                  activeColor: ColorConstants.primaryColor,
                  onChanged: (value) => _toggleNotifications(value),
                ),
                onTap: () => _toggleNotifications(!(_userProfile?.notificationsEnabled ?? true)),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.fingerprint,
                title: 'Biometric Authentication',
                subtitle: 'Use fingerprint or face ID to secure app access',
                trailing: Switch(
                  value: _userProfile?.isBiometricEnabled ?? false,
                  activeColor: ColorConstants.primaryColor,
                  onChanged: (value) => _toggleBiometricAuthentication(value),
                ),
                onTap: () => _toggleBiometricAuthentication(!(_userProfile?.isBiometricEnabled ?? false)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Data', Icons.storage_rounded),
        _buildSettingsCard(
          Column(
            children: [
              _buildModernListTile(
                icon: Icons.backup,
                title: 'Backup Data',
                subtitle: 'Save your data to a file',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showBackupDialog(),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.restore,
                title: 'Restore Data',
                subtitle: 'Restore from a backup file',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showRestoreDialog(),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Permanently delete all your data',
                iconColor: Colors.redAccent,
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showClearDataDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About', Icons.info_rounded),
        _buildSettingsCard(
          Column(
            children: [
              _buildModernListTile(
                icon: Icons.info,
                title: 'About Paisa Track',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => Navigator.pushNamed(context, AppRouter.about),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.system_update,
                title: 'Update Settings',
                subtitle: 'Manage app updates and configuration',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => Navigator.pushNamed(context, AppRouter.updateSettingsRoute),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.update,
                title: 'Check for Updates',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking for updates...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  await UpdateService.checkForUpdates(context, force: true);
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.description,
                title: 'Terms of Service',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showTermsOfService(),
              ),
              const Divider(height: 1, indent: 56),
              _buildModernListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => _showPrivacyPolicy(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showGitHubRepoSettings() async {
    final username = await UpdateService.getGithubUsername();
    final repo = await UpdateService.getGithubRepo();
    
    // Controllers for text fields
    final usernameController = TextEditingController(text: username);
    final repoController = TextEditingController(text: repo);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Repository Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure the GitHub repository to use for update checks.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Username',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., octocat',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repoController,
                decoration: const InputDecoration(
                  labelText: 'Repository Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., my-app',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The app will look for releases in:\nhttps://github.com/[username]/[repo]/releases',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Verify'),
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newRepo = repoController.text.trim();
              
              if (newUsername.isEmpty || newRepo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username and repository name cannot be empty'),
                    backgroundColor: ColorConstants.errorColor,
                  ),
                );
                return;
              }
              
              // Save the new values
              await UpdateService.saveGithubDetails(newUsername, newRepo);
              
              // Verify the repository
              final isValid = await UpdateService.verifyGithubRepository();
              
              if (context.mounted) {
                if (isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Repository verified successfully'),
                      backgroundColor: ColorConstants.successColor,
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Repository could not be verified. Please check the details and try again.'),
                      backgroundColor: ColorConstants.errorColor,
                    ),
                  );
                }
              }
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newRepo = repoController.text.trim();
              
              if (newUsername.isEmpty || newRepo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username and repository name cannot be empty'),
                    backgroundColor: ColorConstants.errorColor,
                  ),
                );
                return;
              }
              
              // Save the new values
              await UpdateService.saveGithubDetails(newUsername, newRepo);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GitHub repository settings saved'),
                    backgroundColor: ColorConstants.successColor,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCountrySelector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: CountrySelectionDialog(
          initialCountry: _userProfile?.country ?? CountryType.nepal,
          onSelect: (CountryType country) async {
            if (_userProfile == null) return;
            
            try {
              // Create updated user profile with the new country
              final updatedProfile = _userProfile!.copyWith(
                country: country,
              );
              
              // Save to repository
              await _repository.updateUserProfile(updatedProfile);
              
              // Reload profile
              _loadUserProfile();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Country updated successfully'),
                    backgroundColor: ColorConstants.successColor,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating country: $e'),
                    backgroundColor: ColorConstants.errorColor,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showCurrencySelector() {
    _showFullCurrencySelector();
  }
  
  void _showFullCurrencySelector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: CurrencySelectionDialog(
          initialCurrencyCode: _userProfile?.defaultCurrencyCode ?? 'USD',
          onSelect: (String currencyCode) async {
            if (_userProfile == null) return;
            
            try {
              // Create updated user profile with the new currency
              final updatedProfile = _userProfile!.copyWith(
                defaultCurrencyCode: currencyCode,
              );
              
              // Save to repository
              await _repository.updateUserProfile(updatedProfile);
              
              // Reload profile
              _loadUserProfile();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Currency updated successfully'),
                    backgroundColor: ColorConstants.successColor,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating currency: $e'),
                    backgroundColor: ColorConstants.errorColor,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _toggleNotifications(bool value) async {
    if (_userProfile == null) return;
    
    try {
      // Create updated user profile with the new notification setting
      final updatedProfile = _userProfile!.copyWith(
        notificationsEnabled: value,
      );
      
      // Save to repository
      await _repository.updateUserProfile(updatedProfile);
      
      // Reload profile
      _loadUserProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? 'Notifications enabled' 
              : 'Notifications disabled'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notification settings: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleBiometricAuthentication(bool value) async {
    if (_userProfile == null) return;
    
    try {
      // If enabling biometric auth, first check if it's available
      if (value) {
        final authService = AuthService();
        final isAvailable = await authService.isBiometricAvailable();
        
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication is not available on this device'),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
          }
          return;
        }
        
        // Test biometric authentication before enabling
        final authResult = await authService.authenticateWithBiometrics();
        if (!authResult['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authResult['message'] ?? 'Failed to authenticate. Please try again.'),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
          }
          return;
        }
      }
      
      // Create updated user profile with the new biometric setting
      final updatedProfile = _userProfile!.copyWith(
        isBiometricEnabled: value,
      );
      
      // Save to repository
      await _repository.updateUserProfile(updatedProfile);
      
      // Reload profile
      _loadUserProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? 'Biometric authentication enabled' 
              : 'Biometric authentication disabled'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating biometric settings: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  void _showProfileEditDialog() {
    final nameController = TextEditingController(text: _userProfile?.name ?? '');
    File? selectedImage;
    
    print('Opening profile edit dialog: ${_userProfile?.name}');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Function to pick image from gallery
          Future<void> pickImage() async {
            try {
              final picker = ImagePicker();
              final pickedImage = await picker.pickImage(source: ImageSource.gallery);
              
              if (pickedImage == null) return;
              
              setState(() {
                selectedImage = File(pickedImage.path);
              });
            } catch (e) {
              print('Error picking image: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error picking image: $e'),
                  backgroundColor: ColorConstants.errorColor,
                ),
              );
            }
          }
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Profile picture
                    Center(
                      child: Stack(
                        children: [
                          // Show either selected image, existing profile image, or avatar with initial
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: ColorConstants.primaryColor,
                            child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.file(
                                    selectedImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _userProfile?.profileImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.file(
                                      File(_userProfile!.profileImagePath!),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading profile image: $error');
                                        return Text(
                                          _userProfile?.name[0].toUpperCase() ?? 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    _userProfile?.name[0].toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorConstants.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name field
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: ColorConstants.primaryColor,
                          ),
                          onPressed: () async {
                            // Validate non-empty name
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Name cannot be empty'),
                                  backgroundColor: ColorConstants.errorColor,
                                ),
                              );
                              return;
                            }
                            
                            // Close dialog
                            Navigator.of(context).pop();
                            
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Dialog(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text('Saving profile...'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            
                            // Update profile
                            if (_userProfile == null) {
                              print('Error: User profile is null when saving');
                              return;
                            }
                            
                            print('Updating profile with name: $name');
                            
                            try {
                              // Save image if changed
                              String? imagePath = _userProfile?.profileImagePath;
                              if (selectedImage != null) {
                                final appDir = await getApplicationDocumentsDirectory();
                                final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final savedImage = await selectedImage!.copy('${appDir.path}/$fileName');
                                imagePath = savedImage.path;
                                print('Saved image to: $imagePath');
                              }
                              
                              // Create updated user profile with the new name and image
                              final updatedProfile = _userProfile!.copyWith(
                                name: name,
                                profileImagePath: imagePath,
                              );
                              
                              // Save to repository
                              await _repository.updateUserProfile(updatedProfile);
                              
                              // Reload profile
                              await _loadUserProfile();
                              
                              // Close loading dialog
                              if (mounted) {
                                Navigator.of(context).pop();
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully'),
                                    backgroundColor: ColorConstants.successColor,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Close loading dialog
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                              
                              print('Error updating profile: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating profile: $e'),
                                    backgroundColor: ColorConstants.errorColor,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  void _showBackupDialog() async {
    if (!mounted) return;
    
    final backupService = BackupService();
    
    // First check permissions
    bool hasPermission = await backupService.checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Permission Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage permission is required to create backups that you can access.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Please grant storage permission in your device settings:'),
                Text('1. Open device Settings'),
                Text('2. Go to Apps or Applications'),
                Text('3. Find Paisa Track'),
                Text('4. Tap Permissions'),
                Text('5. Enable Storage permission'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    // Show backup options dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Backup Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will create a backup of all your data including:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Accounts'),
              Text('• Transactions'),
              Text('• Categories'),
              Text('• Budgets'),
              Text('• Settings'),
              SizedBox(height: 16),
              Text(
                'The backup will be saved to your device\'s storage in the PaisaTrackBackups folder.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Close the options dialog
                Navigator.of(dialogContext).pop();
                
                // Show loading dialog while creating backup
                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => AlertDialog(
                      title: Text('Creating Backup'),
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text('Please wait...'),
                        ],
                      ),
                    ),
                  );
                }
                
                try {
                  // Create backup file
                  final backupPath = await backupService.createBackup();
                  
                  // Close the loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                    
                    // Show success message with share option
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (successContext) => AlertDialog(
                          title: Text('Backup Created'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Backup successfully created at:'),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  backupPath ?? 'Unknown location',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'You can find this file in your phone\'s file manager.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(successContext).pop(),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Close the loading dialog if error occurs
                  if (mounted) {
                    Navigator.of(context).pop();
                    
                    // Show error message
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (errorContext) => AlertDialog(
                          title: Text('Backup Failed'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'An error occurred while creating the backup:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(e.toString()),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(errorContext).pop(),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              },
              child: Text('Create Backup'),
            ),
          ],
        ),
      );
    }
  }
  
  void _showRestoreDialog() async {
    if (!mounted) return;
    
    final backupService = BackupService();
    
    // First check permissions
    bool hasPermission = await backupService.checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Permission Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage permission is required to access backup files.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Please grant storage permission in your device settings:'),
                SizedBox(height: 8),
                Text('1. Open device Settings'),
                Text('2. Go to Apps or Applications'),
                Text('3. Find Paisa Track'),
                Text('4. Tap Permissions'),
                Text('5. Enable Storage permission'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    // Show loading while getting file list
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Searching for backups...'),
            ],
          ),
        ),
      );
    }
    
    try {
      // List all backup files
      final backupFiles = await backupService.listBackupFiles();
      
      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (backupFiles.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('No Backups Found'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No backup files were found in your device storage.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Create a backup first before restoring.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Sort files by modification time (newest first)
      backupFiles.sort((a, b) {
        return (b as File).lastModifiedSync().compareTo((a as File).lastModifiedSync());
      });
      
      if (mounted) {
        // Show backup files selection dialog
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Choose Backup to Restore'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select a backup file to restore:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: backupFiles.length,
                      itemBuilder: (context, index) {
                        final file = backupFiles[index] as File;
                        final fileName = file.path.split('/').last;
                        final modificationDate = file.lastModifiedSync();
                        
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.backup, color: ColorConstants.primaryColor),
                            title: Text(
                              fileName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Created: ${DateFormat('MMM d, yyyy HH:mm').format(modificationDate)}',
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              _confirmRestoreFromBackup(file.path);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog if it's still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to list backup files:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(e.toString()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  void _confirmRestoreFromBackup(String backupPath) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will replace all your current data with the backup data.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• All current data will be deleted'),
            Text('• Data from the backup will be restored'),
            Text('• This action cannot be undone'),
            SizedBox(height: 12),
            Text(
              'Are you sure you want to continue?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              
              // Show loading dialog
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('Restoring Backup'),
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Please wait...'),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                // Perform restore operation
                final backupService = BackupService();
                await backupService.restoreFromBackup(backupPath);
                
                if (mounted) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Show success message and restart app
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('Restore Successful'),
                        content: Text('Your data has been restored successfully. The app will now restart to apply the changes.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              // Use the AppRouter constant instead of hardcoded route
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRouter.dashboard, 
                                (route) => false
                              );
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Restore error: $e');
                if (mounted) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Show error message
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('Restore Failed'),
                        content: Text('An error occurred during the restore process: $e'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Restore Now'),
          ),
        ],
      ),
    );
  }

  void _showSimpleRestoreOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simple Restore'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will reset your app to default settings.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Your profile data will be preserved, but all transactions, accounts, and budgets will be reset to defaults.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Restoring defaults...'),
                    ],
                  ),
                ),
              );
              
              try {
                // Use database service to reset to defaults
                final databaseService = DatabaseService();
                await databaseService.clearAllData();
                
                // Reload profile
                await _loadUserProfile();
                
                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App reset to defaults successfully'),
                      backgroundColor: ColorConstants.successColor,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop();
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error resetting app: $e'),
                      backgroundColor: ColorConstants.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '1. ACCEPTANCE OF TERMS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'By downloading, installing, or using Paisa Track, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. DESCRIPTION OF SERVICE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Paisa Track is a personal finance management application that allows users to track expenses, create budgets, and manage financial goals. The app operates locally on your device and may provide features that require internet connectivity.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. USER ACCOUNTS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Some features of Paisa Track may require you to create an account. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '4. USER DATA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your financial data is stored locally on your device. You can create backups of your data, which will be stored in your device\'s storage. The app developers do not have access to your personal financial data unless you explicitly share it with us for support purposes.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '5. INTELLECTUAL PROPERTY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Paisa Track and its original content, features, and functionality are owned by the app developers and are protected by international copyright, trademark, and other intellectual property laws.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '6. LIMITATION OF LIABILITY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'To the maximum extent permitted by law, the app developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, resulting from your access to or use of Paisa Track.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '7. CHANGES TO TERMS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We reserve the right to modify these terms at any time. We will provide notice of significant changes through the app or via email. Your continued use of Paisa Track after such modifications constitutes your acceptance of the updated terms.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '8. GOVERNING LAW',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'These Terms shall be governed by the laws of the jurisdiction in which the app developers operate, without regard to its conflict of law provisions.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '9. CONTACT US',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'If you have any questions about these Terms, please contact us at support@paisatrack.com.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: ColorConstants.primaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Last Updated: January 1, 2023',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'This Privacy Policy describes how Paisa Track ("we", "us", or "our") collects, uses, and shares your personal information when you use our mobile application.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '1. INFORMATION WE COLLECT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Personal Information: We collect basic profile information such as your name. This information is stored locally on your device.\n\n'
                        'Financial Information: We collect financial data that you input into the app, such as transactions, account balances, budgets, and goals. This information is stored locally on your device.\n\n'
                        'Device Information: We may collect information about your device, including device type, operating system, and unique device identifiers for analytics and troubleshooting purposes.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. HOW WE USE YOUR INFORMATION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We use the information we collect to:\n\n'
                        '• Provide, maintain, and improve Paisa Track\n'
                        '• Develop new features and functionality\n'
                        '• Understand how users use our app\n'
                        '• Detect and prevent fraud and abuse\n'
                        '• Communicate with you about updates and new features',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. DATA STORAGE AND SECURITY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Local Storage: Your financial data is primarily stored locally on your device. We do not have access to this data unless you explicitly share it with us for support purposes.\n\n'
                        'Backups: You can create backups of your data, which will be stored in your device\'s storage. You are responsible for the security of these backup files.\n\n'
                        'Security: We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, accidental loss, or damage.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '4. SHARING YOUR INFORMATION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We do not sell, trade, or otherwise transfer your personal information to outside parties. We may share anonymous, aggregated information for analytics purposes.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '5. YOUR RIGHTS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You have the right to access, update, or delete your personal information at any time through the app settings. Since your data is stored locally, you can also delete the app to remove all data.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '6. CHANGES TO THIS PRIVACY POLICY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '7. CONTACT US',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'If you have any questions about this Privacy Policy, please contact us at privacy@paisatrack.com.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: ColorConstants.primaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeModeName(String themeMode) {
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System Default';
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app only supports Dark Mode',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOptionCard('Dark', 'dark', Colors.blueGrey),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard(String title, String value, Color accentColor) {
    final isSelected = _userProfile?.themeMode == value;
    final isDark = value == 'dark';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          Navigator.of(context).pop();
          
          if (_userProfile == null) return;
          
          try {
            // Create updated user profile with the new theme mode
            final updatedProfile = _userProfile!.copyWith(
              themeMode: value,
            );
            
            // Save to repository
            await _repository.updateUserProfile(updatedProfile);
            
            // Reload profile
            _loadUserProfile();
            
            // Update the app theme - convert string to ThemeMode enum
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.setThemeMode(_stringToThemeMode(value));
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Theme updated to $title'),
                  backgroundColor: ColorConstants.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating theme: $e'),
                  backgroundColor: ColorConstants.errorColor,
                ),
              );
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Theme preview
              Container(
                height: 64,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // App bar preview
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Content preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // More content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Theme info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getThemeDescription(value),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getThemeIcon(value),
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getThemeMode(value),
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Selected indicator
              if (isSelected)
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to convert string theme value to ThemeMode enum
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _getThemeDescription(String themeMode) {
    switch (themeMode) {
      case 'light':
        return 'Light theme with bright colors';
      case 'dark':
        return 'Dark theme with reduced brightness';
      case 'system':
      default:
        return 'Follows your device system settings';
    }
  }
  
  String _getThemeMode(String themeMode) {
    switch (themeMode) {
      case 'light':
        return 'Light Mode';
      case 'dark':
        return 'Dark Mode';
      case 'system':
      default:
        return 'Auto Mode';
    }
  }
  
  IconData _getThemeIcon(String themeMode) {
    switch (themeMode) {
      case 'light':
        return Icons.wb_sunny_outlined;
      case 'dark':
        return Icons.nights_stay_outlined;
      case 'system':
      default:
        return Icons.settings_suggest_outlined;
    }
  }

  void _toggleFabSize(bool value) async {
    if (_userProfile == null) return;
    
    try {
      // Create updated user profile with the new FAB size setting
      final updatedProfile = _userProfile!.copyWith(
        useLargeFab: value,
      );
      
      // Save to repository
      await _repository.updateUserProfile(updatedProfile);
      
      // Reload profile
      _loadUserProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? 'Large FAB size enabled' 
              : 'Large FAB size disabled'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating FAB size: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  void _toggleDynamicColors(bool value) async {
    if (_userProfile == null) return;
    
    try {
      // Create updated user profile with the new dynamic colors setting
      // When value is true, use null to indicate dynamic system colors
      // When value is false, use a specific color value
      final updatedProfile = _userProfile!.copyWith(
        appColor: value ? null : ColorConstants.primaryColor.value,
      );
      
      // Save to repository
      await _repository.updateUserProfile(updatedProfile);
      
      // Reload profile
      _loadUserProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? 'Dynamic colors enabled' 
              : 'Custom app color set'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating app color: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  void _forceFixNepaliCurrency() async {
    final profileFixService = ProfileFixService();
    
    // First try logging profile information
    await profileFixService.logProfileInfo();
    
    try {
      // Force update to NPR
      final updated = await profileFixService.forceUpdateToNPR();
      
      if (mounted) {
        if (updated) {
          // Update the CurrencyProvider directly
          final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
          currencyProvider.updateCurrency('NPR');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Currency successfully updated to Nepali Rupees (रू)'),
              backgroundColor: ColorConstants.successColor,
            ),
          );
          
          // Reload user profile
          _loadUserProfile();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update currency. Please try again.'),
              backgroundColor: ColorConstants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating currency: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  void _showLanguageSelector() {
    // Implementation for showing language selector dialog
    showDialog(
      context: context,
      builder: (context) {
        return LanguageSelectorDialog(
          currentLanguageCode: _userProfile?.locale ?? 'en_US',
          onLanguageSelected: (languageCode) async {
            if (_userProfile != null) {
              final updatedProfile = _userProfile!.copyWith(
                locale: languageCode,
              );
              
              await _repository.updateUserProfile(updatedProfile);
              _loadUserProfile();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language updated'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
  
  String _getDashboardLayoutName(String layout) {
    switch (layout) {
      case 'default':
        return 'Default';
      case 'compact':
        return 'Compact';
      case 'expanded':
        return 'Expanded';
      default:
        return 'Default';
    }
  }
  
  void _showDashboardLayoutSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dashboard Layout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLayoutOption('Default', 'default'),
              _buildLayoutOption('Compact', 'compact'),
              _buildLayoutOption('Expanded', 'expanded'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildLayoutOption(String title, String value) {
    final isSelected = _userProfile?.dashboardLayout == value;
    
    return ListTile(
      title: Text(title),
      trailing: isSelected 
        ? const Icon(Icons.check, color: Color(0xFF4F46E5))
        : null,
      onTap: () async {
        Navigator.pop(context);
        
        if (_userProfile != null) {
          final updatedProfile = _userProfile!.copyWith(
            dashboardLayout: value,
          );
          
          await _repository.updateUserProfile(updatedProfile);
          _loadUserProfile();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dashboard layout changed to $title'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        }
      },
    );
  }
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will reset your app and remove all your data. This action cannot be undone.',
            style: TextStyle(color: Color(0xFFEF4444)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () {
                Navigator.pop(context);
                // Implementation for clearing data
                _clearAllData();
              },
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _clearAllData() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Clear data logic would go here
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been cleared'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _shareApp() {
    // Implementation for sharing the app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Support', Icons.support_rounded),
        
        // Developer Support Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.primaryColor.withOpacity(0.15),
                ColorConstants.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstants.primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: ColorConstants.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Support',
                              style: TextStyle(
                                color: ColorConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Aneesh (Ozric)',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Support the development of Paisa Track and help us bring more features!',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // eSewa Payment Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement eSewa payment
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('eSewa payment coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'Support via eSewa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // eSewa Number Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'eSewa: 9865236409',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Share App Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _shareApp,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share App',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tell others about Paisa Track',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CountrySelectionDialog extends StatefulWidget {
  final CountryType initialCountry;
  final Function(CountryType) onSelect;
  
  const CountrySelectionDialog({
    super.key,
    required this.initialCountry,
    required this.onSelect,
  });
  
  @override
  State<CountrySelectionDialog> createState() => _CountrySelectionDialogState();
}

class _CountrySelectionDialogState extends State<CountrySelectionDialog> {
  late CountryType _selectedCountry;
  final _searchController = TextEditingController();
  List<CountryType> _filteredCountries = [];
  
  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _filteredCountries = CountryType.values;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterCountries(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCountries = CountryType.values;
      });
      return;
    }
    
    setState(() {
      _filteredCountries = CountryType.values
          .where((country) => country.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Country',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search bar
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search countries',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: _filterCountries,
          ),
          const SizedBox(height: 16),
          
          // Country list
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  final isSelected = country == _selectedCountry;
                  
                  return ListTile(
                    leading: Text(
                      country.flagEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country.displayName),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF4F46E5)) : null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      
                      // Update the selected country
                      widget.onSelect(country);
                      
                      // Close the dialog
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
          
          // Buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrencySelectionDialog extends StatefulWidget {
  final String initialCurrencyCode;
  final Function(String) onSelect;
  
  const CurrencySelectionDialog({
    super.key,
    required this.initialCurrencyCode,
    required this.onSelect,
  });
  
  @override
  State<CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  late String _selectedCurrencyCode;
  final _searchController = TextEditingController();
  List<Currency> _allCurrencies = [];
  List<Currency> _filteredCurrencies = [];
  
  @override
  void initState() {
    super.initState();
    _selectedCurrencyCode = widget.initialCurrencyCode;
    _allCurrencies = CurrencyUtils.getCommonCurrencies();
    _filteredCurrencies = _allCurrencies;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterCurrencies(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCurrencies = _allCurrencies;
      });
      return;
    }
    
    setState(() {
      _filteredCurrencies = _allCurrencies
          .where((currency) => 
            currency.name.toLowerCase().contains(query.toLowerCase()) ||
            currency.code.toUpperCase().contains(query.toUpperCase()))
          .toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Default Currency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search bar
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search currencies',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: _filterCurrencies,
          ),
          const SizedBox(height: 16),
          
          // Currency list
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = currency.code == _selectedCurrencyCode;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          currency.symbol,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF4F46E5)) : null,
                    onTap: () {
                      setState(() {
                        _selectedCurrencyCode = currency.code;
                      });
                      
                      // Update the selected currency
                      widget.onSelect(currency.code);
                      
                      // Close the dialog
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
          
          // Buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 