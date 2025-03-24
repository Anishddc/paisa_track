import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/constants/text_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/core/utils/validation_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/country_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paisa_track/core/utils/app_router.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({Key? key}) : super(key: key);

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // User data
  final _nameController = TextEditingController();
  File? _profileImage;
  CountryType _selectedCountry = CountryType.nepal;
  CurrencyType _selectedCurrency = CurrencyType.npr;
  
  // Account setup data
  bool _setupCashAccount = true;
  bool _setupBankAccount = false;
  bool _setupDigitalWalletAccount = false;
  
  // Repositories
  final UserRepository _userRepository = UserRepository();
  final AccountRepository _accountRepository = AccountRepository();
  
  // State
  bool _isLoading = false;
  bool _isNameValid = false;
  
  // Theme colors
  final List<Color> _pageColors = [
    Colors.blue.shade600,
    Colors.green.shade600,
    Colors.purple.shade600,
    Colors.teal.shade600,
    Colors.orange.shade600,
  ];
  
  // Setup step icons
  final List<IconData> _stepIcons = [
    Icons.person_rounded,
    Icons.public_rounded,
    Icons.photo_camera_rounded,
    Icons.currency_exchange_rounded,
    Icons.account_balance_rounded,
  ];
  
  // Setup step titles
  final List<String> _stepTitles = [
    'Create Profile',
    'Select Country',
    'Add Photo',
    'Select Currency',
    'Setup Accounts',
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishSetup();
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedImage == null) return;
      
      // Create a File from the picked image path
      final pickedFile = File(pickedImage.path);
      
      // Create a permanent copy in the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await pickedFile.copy('${appDir.path}/$fileName');
      
      print('Saved profile image to: ${savedImage.path}');
      
      setState(() {
        _profileImage = savedImage;
      });
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _finishSetup() async {
    // Check if at least one account is selected
    if (!_setupCashAccount && !_setupBankAccount && !_setupDigitalWalletAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one account type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Creating user profile with country: ${_selectedCountry.displayName}');
      
      // Create user profile
      final userProfile = UserProfileModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        profileImagePath: _profileImage?.path,
        defaultCurrencyCode: _selectedCurrency.name.toUpperCase(),
        country: _selectedCountry,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(), // Add lastUpdated to ensure it's initialized
        locale: 'en_US', // Make sure all fields have values
        themeMode: 'system',
        isBiometricEnabled: false,
      );
      
      print('User profile created, saving to repository...');
      
      // Save user profile
      await _userRepository.saveUserProfile(userProfile);
      
      print('User profile saved, creating selected accounts...');
      
      // Create selected accounts with default names
      if (_setupCashAccount) {
        final cashAccount = AccountModel(
          name: 'Cash',
          type: AccountType.cash,
          balance: 0.0,
          currency: _selectedCurrency,
          isArchived: false,
          createdAt: DateTime.now(),
        );
        await _accountRepository.addAccount(cashAccount);
      }
      
      if (_setupBankAccount) {
        final bankAccount = AccountModel(
          name: 'Bank Account',
          type: AccountType.bank,
          balance: 0.0,
          currency: _selectedCurrency,
          isArchived: false,
          createdAt: DateTime.now(),
          // Add these fields for bank accounts
          bankName: 'My Bank',
          accountNumber: '',
          accountHolderName: _nameController.text.trim(),
        );
        await _accountRepository.addAccount(bankAccount);
      }
      
      if (_setupDigitalWalletAccount) {
        final digitalWalletAccount = AccountModel(
          name: 'Digital Wallet',
          type: AccountType.digitalWallet,
          balance: 0.0,
          currency: _selectedCurrency,
          isArchived: false,
          createdAt: DateTime.now(),
        );
        await _accountRepository.addAccount(digitalWalletAccount);
      }
      
      print('Accounts created, navigating to dashboard...');
      
      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    } catch (e) {
      print('Error setting up user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          // If not on the first page, go back to the previous page
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
          return false; // Don't allow actual pop
        } else {
          // On first page, navigate back to onboarding
          Navigator.pushReplacementNamed(context, AppRouter.onboarding);
          return false; // Don't allow actual pop
        }
      },
      child: Scaffold(
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: _pageColors[_currentPage],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Setting up your account...',
                      style: TextStyle(
                        fontSize: 16,
                        color: _pageColors[_currentPage],
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Colored background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _pageColors[_currentPage],
                          _pageColors[_currentPage].withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // White content area
                  SafeArea(
                    child: Column(
                      children: [
                        // Header with step indicators
                        _buildStepIndicator(),
                        
                        // Main content
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                children: [
                                  _buildNamePage(),
                                  _buildCountryPage(),
                                  _buildProfileImagePage(),
                                  _buildCurrencyPage(),
                                  _buildAccountPage(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Bottom navigator
                        _buildBottomNavigator(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final isActive = index == _currentPage;
          final isCompleted = index < _currentPage;
          
          return GestureDetector(
            onTap: () {
              if (index < _currentPage) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive 
                      ? Colors.white 
                      : isCompleted 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                      ? const Icon(Icons.check, color: Colors.green)
                      : Icon(
                          _stepIcons[index],
                          color: isActive 
                            ? _pageColors[_currentPage]
                            : Colors.grey,
                          size: 20,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildNamePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step title
            Text(
              _stepTitles[0],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _pageColors[0],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us your name to personalize your experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            
            // Name input
            TextField(
              controller: _nameController,
              onChanged: (value) {
                setState(() {
                  _isNameValid = value.trim().length > 1;
                });
              },
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline, color: _pageColors[0]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _pageColors[0], width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            Text(
              'This is how we\'ll address you in the app.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Continue button will be in the bottom navigator
          ],
        ),
      ),
    );
  }
  
  Widget _buildCountryPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step title
            Text(
              _stepTitles[1],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _pageColors[1],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Which country are you from?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Country Grid with popular countries
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                // Most popular countries
                _buildCountryButton(CountryType.nepal),
                _buildCountryButton(CountryType.india),
                _buildCountryButton(CountryType.unitedStates),
                _buildCountryButton(CountryType.unitedKingdom),
                _buildCountryButton(CountryType.australia),
                _buildCountryButton(CountryType.canada),
                _buildCountryButton(CountryType.china),
                _buildCountryButton(CountryType.japan),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'More Countries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Dropdown for other countries
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CountryType>(
                  value: _selectedCountry,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: _pageColors[1]),
                  items: CountryType.values
                      .map(_buildCountryDropdownItem)
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCountry = value;
                        // Update currency to match the country's default
                        _selectedCurrency = value.defaultCurrency;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'Your country will help us set appropriate currency defaults.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Continue button will be in the bottom navigator
          ],
        ),
      ),
    );
  }
  
  Widget _buildCountryButton(CountryType country) {
    final isSelected = _selectedCountry == country;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCountry = country;
          // Update currency to match the country's default
          _selectedCurrency = country.defaultCurrency;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _pageColors[1].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _pageColors[1] : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              country.flagEmoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                country.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? _pageColors[1] : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  DropdownMenuItem<CountryType> _buildCountryDropdownItem(CountryType country) {
    return DropdownMenuItem<CountryType>(
      value: country,
      child: Row(
        children: [
          Text(
            country.flagEmoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              country.displayName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileImagePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step title
            Text(
              _stepTitles[2],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _pageColors[2],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a profile picture (optional)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            
            // Profile image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey.shade400,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _pageColors[2],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: Text(
                _profileImage != null
                    ? 'Tap to change your profile picture'
                    : 'Tap to add a profile picture',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Continue button will be in the bottom navigator
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrencyPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step title
            Text(
              _stepTitles[3],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _pageColors[3],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your primary currency',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            
            // Currency selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CurrencyType>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: _pageColors[3]),
                  items: [
                    // Put Nepali Rupee first
                    _buildCurrencyItem(CurrencyType.npr),
                    // Then add all other currencies
                    ...CurrencyType.values
                        .where((c) => c != CurrencyType.npr)
                        .map(_buildCurrencyItem)
                        .toList(),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'You\'ll be able to add multiple currencies later.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Continue button will be in the bottom navigator
          ],
        ),
      ),
    );
  }
  
  DropdownMenuItem<CurrencyType> _buildCurrencyItem(CurrencyType currency) {
    return DropdownMenuItem<CurrencyType>(
      value: currency,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              currency.symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _pageColors[3],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currency.displayName,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step title
            Text(
              _stepTitles[4],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _pageColors[4],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the accounts you want to use',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Cash Account
            _buildAccountOption(
              icon: Icons.money,
              title: 'Cash',
              subtitle: 'For tracking physical money',
              isSelected: _setupCashAccount,
              color: Colors.green.shade700,
              onChanged: (value) {
                setState(() {
                  _setupCashAccount = value ?? false;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Bank Account
            _buildAccountOption(
              icon: Icons.account_balance,
              title: 'Bank Account',
              subtitle: 'For checking/savings accounts',
              isSelected: _setupBankAccount,
              color: Colors.blue.shade700,
              onChanged: (value) {
                setState(() {
                  _setupBankAccount = value ?? false;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Digital Wallet - Fixed the overflow by improving layout
            _buildAccountOption(
              icon: Icons.phone_android,
              title: 'Digital Wallet',
              subtitle: 'For eSewa, Khalti, IMEPay',
              isSelected: _setupDigitalWalletAccount,
              color: Colors.purple.shade700,
              onChanged: (value) {
                setState(() {
                  _setupDigitalWalletAccount = value ?? false;
                });
              },
            ),
            
            const SizedBox(height: 24),
            Text(
              'You can add more accounts later from the Accounts screen.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Continue button will be in the bottom navigator
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: color,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildBottomNavigator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentPage > 0)
            OutlinedButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pageColors[_currentPage],
                side: BorderSide(color: _pageColors[_currentPage]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            )
          else
            // On first page, add a close button that returns to onboarding
            OutlinedButton.icon(
              onPressed: () {
                // Navigate back to onboarding instead of dashboard
                Navigator.pushReplacementNamed(context, AppRouter.onboarding);
              },
              icon: const Icon(Icons.close),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pageColors[_currentPage],
                side: BorderSide(color: _pageColors[_currentPage]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          
          // Next/Finish button
          ElevatedButton.icon(
            onPressed: _canContinue() ? _nextPage : null,
            icon: Icon(
              _currentPage < 4 ? Icons.arrow_forward : Icons.check,
            ),
            label: Text(
              _currentPage < 4 ? 'Continue' : 'Finish',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pageColors[_currentPage],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0:
        return _isNameValid;
      case 1:
        return true; // Country is always selected
      case 2:
        return true; // Profile image is optional
      case 3:
        return true; // Currency is always selected
      case 4:
        // At least one account must be selected
        return _setupCashAccount || _setupBankAccount || _setupDigitalWalletAccount;
      default:
        return false;
    }
  }
} 