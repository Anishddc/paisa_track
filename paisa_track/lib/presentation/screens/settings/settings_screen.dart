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
        appBar: AppBar(
          title: const Text('Settings'),
          // If we came from tab navigation, show a home button instead of back
          leading: fromTab 
              ? IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.dashboard,
                      arguments: {'initialTab': 0}
                    );
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.settingsRoute);
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const SizedBox(height: 16),
                  _buildProfileSection(),
                  const Divider(),
                  _buildAppearanceSection(),
                  const Divider(),
                  _buildInterfaceSection(),
                  const Divider(),
                  _buildPreferencesSection(),
                  const Divider(),
                  _buildSecuritySection(),
                  const Divider(),
                  _buildDataSection(),
                  const Divider(),
                  _buildSupportSection(),
                  const Divider(),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                ],
              ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.dashboard),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.dashboard);
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_balance_wallet),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.accounts);
                },
              ),
              IconButton(
                icon: const Icon(Icons.category),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.categories);
                },
              ),
              const SizedBox(width: 40), // Space for FAB
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.reports);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    print('Building profile section. Profile: ${_userProfile?.name ?? 'None'}');
    
    // Add a more prominent visual indicator for the profile section
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: ColorConstants.primaryColor,
                child: _userProfile?.profileImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.file(
                        File(_userProfile!.profileImagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading profile image: $error');
                          return Text(
                            _userProfile?.name[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 24,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    ),
              ),
              title: Text(
                _userProfile?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to edit your profile',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Account created: ${_userProfile?.createdAt.toString().substring(0, 10) ?? 'Unknown'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Icon(
                  Icons.edit,
                  color: ColorConstants.primaryColor,
                ),
              ),
              onTap: () {
                print('Profile tile tapped, showing edit dialog');
                _showProfileEditDialog();
              },
            ),
          ),
        ),
        
        // Add a button to go to the full user setup flow
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              print('Navigating to user setup screen');
              Navigator.pushNamed(context, AppRouter.userSetup);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: ColorConstants.primaryColor,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Go to Complete Setup Wizard',
                    style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.public),
          title: const Text('Country'),
          subtitle: Row(
            children: [
              Text(_userProfile?.country?.flagEmoji ?? '🌍'),
              const SizedBox(width: 8),
              Text(_userProfile?.country?.displayName ?? 'Not set'),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showCountrySelector();
          },
        ),
        ListTile(
          leading: const Icon(Icons.currency_exchange),
          title: const Text('Default Currency'),
          subtitle: Text(_userProfile?.defaultCurrencyCode ?? 'USD'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showCurrencySelector();
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: Text(_userProfile?.locale ?? 'English (en_US)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showLanguageSelector();
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Appearance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Theme'),
          subtitle: Text(_getThemeModeName(_userProfile?.themeMode ?? 'system')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showThemeSelector();
          },
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('Dynamic Colors'),
          subtitle: const Text('Use system accent colors'),
          trailing: Switch(
            value: (_userProfile?.appColor == null),
            activeColor: ColorConstants.primaryColor,
            onChanged: (value) {
              _toggleDynamicColors(value);
            },
          ),
          onTap: () {
            _toggleDynamicColors(!(_userProfile?.appColor == null));
          },
        ),
      ],
    );
  }

  Widget _buildInterfaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Interface',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.fullscreen),
          title: const Text('Large FAB Size'),
          subtitle: const Text('Use larger floating action buttons'),
          trailing: Switch(
            value: _userProfile?.useLargeFab ?? true,
            activeColor: ColorConstants.primaryColor,
            onChanged: (value) {
              _toggleFabSize(value);
            },
          ),
          onTap: () {
            _toggleFabSize(!(_userProfile?.useLargeFab ?? true));
          },
        ),
        ListTile(
          leading: const Icon(Icons.dashboard_customize),
          title: const Text('Dashboard Layout'),
          subtitle: Text(_getDashboardLayoutName(_userProfile?.dashboardLayout ?? 'default')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showDashboardLayoutSelector();
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: Switch(
            value: _userProfile?.notificationsEnabled ?? true,
            activeColor: ColorConstants.primaryColor,
            onChanged: _toggleNotifications,
          ),
          onTap: () {
            _toggleNotifications(!(_userProfile?.notificationsEnabled ?? true));
          },
        ),
        ListTile(
          leading: const Icon(Icons.fingerprint),
          title: const Text('Biometric Authentication'),
          subtitle: const Text('Use fingerprint or face ID to secure app access'),
          trailing: Switch(
            value: _userProfile?.isBiometricEnabled ?? false,
            activeColor: ColorConstants.primaryColor,
            onChanged: _toggleBiometricAuthentication,
          ),
          onTap: () {
            _toggleBiometricAuthentication(!(_userProfile?.isBiometricEnabled ?? false));
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup Data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showBackupDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore Data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showRestoreDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
          title: const Text('Clear All Data'),
          subtitle: const Text('Permanently delete all your data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showClearDataDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Support Development'),
          subtitle: const Text('Help us improve Paisa Track'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement donation options
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Donation options coming soon!'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: const Text('Share App'),
          subtitle: const Text('Tell others about Paisa Track'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _shareApp();
          },
        ),
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('Send Feedback'),
          subtitle: const Text('Help us improve with your suggestions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showFeedbackDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About Paisa Track'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, AppRouter.about);
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showTermsOfService();
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showPrivacyPolicy();
          },
        ),
      ],
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

  void _toggleBiometricAuthentication(bool value) async {
    if (_userProfile == null) return;
    
    try {
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
                                  backupPath,
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
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light', 'light'),
            _buildThemeOption('Dark', 'dark'),
            _buildThemeOption('System Default', 'system'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String value) {
    final isSelected = _userProfile?.themeMode == value;
    
    return ListTile(
      title: Text(title),
      leading: Icon(
        value == 'light' 
          ? Icons.wb_sunny 
          : value == 'dark' 
            ? Icons.nights_stay 
            : Icons.settings_suggest,
      ),
      trailing: isSelected 
        ? const Icon(Icons.check, color: ColorConstants.primaryColor) 
        : null,
      onTap: () async {
        Navigator.of(context).pop();
        
        if (_userProfile == null) return;
        
        try {
          // Create updated user profile with the new theme
          final updatedProfile = _userProfile!.copyWith(
            themeMode: value,
          );
          
          // Save to repository
          await _repository.updateUserProfile(updatedProfile);
          
          // Reload profile
          _loadUserProfile();
          
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
    );
  }

  void _showLanguageSelector() {
    final languages = [
      {'name': 'English (US)', 'code': 'en_US'},
      {'name': 'Hindi', 'code': 'hi_IN'},
      {'name': 'Spanish', 'code': 'es_ES'},
      {'name': 'French', 'code': 'fr_FR'},
      {'name': 'German', 'code': 'de_DE'},
      {'name': 'Chinese', 'code': 'zh_CN'},
      {'name': 'Japanese', 'code': 'ja_JP'},
      {'name': 'Russian', 'code': 'ru_RU'},
      {'name': 'Arabic', 'code': 'ar_SA'},
      {'name': 'Portuguese', 'code': 'pt_BR'},
      {'name': 'Nepali', 'code': 'ne_NP'},
    ];
    
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
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final isSelected = _userProfile?.locale == language['code'];
                      
                      return ListTile(
                        title: Text(language['name']!),
                        trailing: isSelected 
                          ? const Icon(Icons.check, color: ColorConstants.primaryColor) 
                          : null,
                        onTap: () async {
                          Navigator.of(context).pop();
                          
                          if (_userProfile == null) return;
                          
                          try {
                            // Create updated user profile with the new language
                            final updatedProfile = _userProfile!.copyWith(
                              locale: language['code'],
                            );
                            
                            // Save to repository
                            await _repository.updateUserProfile(updatedProfile);
                            
                            // Reload profile
                            _loadUserProfile();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Language updated to ${language['name']}'),
                                  backgroundColor: ColorConstants.successColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating language: $e'),
                                  backgroundColor: ColorConstants.errorColor,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              
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
        ),
      ),
    );
  }

  void _shareApp() {
    // Mock implementation - would use share package in real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing Paisa Track with friends...'),
        backgroundColor: ColorConstants.successColor,
      ),
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help us improve Paisa Track by sharing your thoughts and suggestions:'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                hintText: 'Your feedback here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
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
              backgroundColor: ColorConstants.primaryColor,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              
              if (feedbackController.text.trim().isNotEmpty) {
                // Mock implementation - would send feedback to backend in real app
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: ColorConstants.successColor,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WARNING: This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'All your data including accounts, transactions, categories, budgets, and settings will be permanently deleted.',
            ),
            SizedBox(height: 12),
            Text(
              'We recommend creating a backup before proceeding.',
              style: TextStyle(fontStyle: FontStyle.italic),
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
              
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Data Deletion'),
                  content: const Text(
                    'Type "DELETE" to confirm you want to permanently erase all data:',
                  ),
                  actions: [
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Type DELETE here',
                      ),
                      onSubmitted: (value) {
                        if (value == 'DELETE') {
                          Navigator.of(context).pop();
                          _performDataClear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Type "DELETE" exactly to confirm'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
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
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }
  
  void _performDataClear() async {
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
            Text('Clearing all data...'),
          ],
        ),
      ),
    );
    
    try {
      // Use the database service to clear all data
      final databaseService = DatabaseService();
      await databaseService.clearAllData();
      
      // Simulate additional processing time
      await Future.delayed(const Duration(seconds: 1));
      
      // Reload profile
      await _loadUserProfile();
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been cleared successfully'),
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
            content: Text('Error clearing data: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
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
        return 'Unknown';
    }
  }

  void _showDashboardLayoutSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Dashboard Layout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDashboardLayoutOption('Default', 'default'),
            _buildDashboardLayoutOption('Compact', 'compact'),
            _buildDashboardLayoutOption('Expanded', 'expanded'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardLayoutOption(String title, String value) {
    final isSelected = _userProfile?.dashboardLayout == value;
    
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: ColorConstants.primaryColor) : null,
      onTap: () async {
        Navigator.of(context).pop();
        
        if (_userProfile == null) return;
        
        try {
          // Create updated user profile with the new dashboard layout
          final updatedProfile = _userProfile!.copyWith(
            dashboardLayout: value,
          );
          
          // Save to repository
          await _repository.updateUserProfile(updatedProfile);
          
          // Reload profile
          _loadUserProfile();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dashboard layout updated to $title'),
                backgroundColor: ColorConstants.successColor,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating dashboard layout: $e'),
                backgroundColor: ColorConstants.errorColor,
              ),
            );
          }
        }
      },
    );
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
                    trailing: isSelected ? const Icon(Icons.check, color: ColorConstants.primaryColor) : null,
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
  List<CurrencyType> _filteredCurrencies = [];
  
  @override
  void initState() {
    super.initState();
    _selectedCurrencyCode = widget.initialCurrencyCode;
    _filteredCurrencies = CurrencyType.values;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterCurrencies(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCurrencies = CurrencyType.values;
      });
      return;
    }
    
    setState(() {
      _filteredCurrencies = CurrencyType.values
          .where((currency) => 
            currency.displayName.toLowerCase().contains(query.toLowerCase()) ||
            currency.name.toUpperCase().contains(query.toUpperCase()))
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
                  final currencyCode = currency.name.toUpperCase();
                  final isSelected = currencyCode == _selectedCurrencyCode;
                  
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
                    title: Text(currency.displayName),
                    subtitle: Text(currencyCode),
                    trailing: isSelected ? const Icon(Icons.check, color: ColorConstants.primaryColor) : null,
                    onTap: () {
                      setState(() {
                        _selectedCurrencyCode = currencyCode;
                      });
                      
                      // Update the selected currency
                      widget.onSelect(currencyCode);
                      
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