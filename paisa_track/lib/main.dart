import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/core/constants/theme_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/budget_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/country_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/budget_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:paisa_track/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:paisa_track/providers/theme_provider.dart';
import 'package:paisa_track/providers/auth_provider.dart';
import 'package:paisa_track/providers/user_profile_provider.dart';
import 'package:paisa_track/providers/currency_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:paisa_track/data/models/app_icon.dart';
import 'package:paisa_track/data/models/bank_data.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:paisa_track/data/models/custom_account_model_adapter.dart';

Future<void> main() async {
  // This preserves the splash screen
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // If we're in icon generation mode, generate the icon and exit
  if (Platform.environment.containsKey('GENERATE_APP_ICON')) {
    await generateAppIcon();
    exit(0);
  }
  
  try {
    print('App starting up...');
    
    // Initialize Hive (skip migration on first run)
    bool firstRun = false;
    
    try {
      // Initialize Hive base functionality first
      print('Initializing Hive...');
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);
      
      // Register adapters before trying to open boxes
      print('Registering Hive adapters...');
      _registerHiveAdapters();
      print('All Hive adapters registered successfully');
      
      // Initialize database service
      print('Initializing database service...');
      final databaseService = DatabaseService();
      await databaseService.init();
      print('Database service initialized successfully');
      
    } catch (e) {
      print('Error initializing Hive: $e');
      
      // Check if this is specifically an AccountType issue
      if (e.toString().contains('AccountType') && e.toString().contains('String')) {
        print('Detected AccountType conversion issue. Attempting targeted fix...');
        
        try {
          // First make sure Hive is initialized
          await Hive.initFlutter();
          _registerHiveAdapters();
          
          // Just open the accounts box directly
          print('Opening accounts box directly to fix type issues...');
          try {
            final accountBox = await Hive.openBox<dynamic>(AppConstants.accountsBox);
            
            // Loop through each account and fix type issues
            print('Processing ${accountBox.length} accounts...');
            for (int i = 0; i < accountBox.length; i++) {
              try {
                final account = accountBox.getAt(i);
                if (account != null) {
                  // Extract whatever data we can from the corrupted account
                  Map<String, dynamic> accountData = {};
                  try {
                    accountData['id'] = account.id;
                  } catch (_) {
                    accountData['id'] = const Uuid().v4();
                  }
                  
                  try {
                    accountData['name'] = account.name;
                  } catch (_) {
                    accountData['name'] = 'Account ${i + 1}';
                  }
                  
                  try {
                    accountData['balance'] = account.balance;
                  } catch (_) {
                    accountData['balance'] = 0.0;
                  }
                  
                  try {
                    accountData['currency'] = account.currency;
                  } catch (_) {
                    accountData['currency'] = null;
                  }
                  
                  // Create a new account with safe string type
                  final fixedAccount = AccountModel(
                    id: accountData['id'],
                    name: accountData['name'],
                    balance: accountData['balance'] ?? 0.0,
                    type: 'AccountType.cash', // Safe default
                    currency: accountData['currency'],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  await accountBox.putAt(i, fixedAccount);
                  print('Fixed account: ${fixedAccount.name}');
                }
              } catch (accountError) {
                print('Error fixing individual account at index $i: $accountError');
                // Try to delete the problematic account if we can't fix it
                try {
                  await accountBox.deleteAt(i);
                  print('Deleted corrupted account at index $i');
                } catch (e) {
                  print('Failed to delete corrupted account: $e');
                }
              }
            }
            
            await accountBox.close();
            print('Account fixes applied. Retrying database initialization...');
            
            // Create a new DatabaseService instance to retry initialization
            final databaseService = DatabaseService();
            await databaseService.init();
            print('Database service initialized successfully after targeted fix');
            
          } catch (recoveryError) {
            print('Error during targeted fix: $recoveryError');
            // If targeted fix fails, fall back to full reset
            print('Falling back to full reset...');
            await _deleteHiveBoxes();
            firstRun = true;
          }
        } catch (e) {
          print('Error during targeted fix: $e');
          // If targeted fix fails, fall back to full reset
          print('Falling back to full reset...');
          await _deleteHiveBoxes();
          firstRun = true;
        }
      } else {
        // Not an AccountType issue, try standard recovery
        try {
          print('Attempting to recover by deleting Hive boxes...');
          await Hive.initFlutter(); // Make sure Hive is at least initialized
          _registerHiveAdapters(); // Register adapters again to be sure
          await _deleteHiveBoxes();
          firstRun = true;
          print('Recovery successful, will proceed as first run');
        } catch (recoveryError) {
          print('Fatal error during recovery: $recoveryError');
          throw Exception('Cannot initialize database: $recoveryError');
        }
      }
    }
    
    // The openHiveBoxes step is now handled by DatabaseService.init()
    // Open and initialize DatabaseService
    try {
      if (firstRun) {
        // If this is a first run after recovery, initialize the database service
        print('Initializing database service after recovery...');
        final databaseService = DatabaseService();
        await databaseService.init();
        print('Database service initialized successfully after recovery');
      }
      
      // Create default categories if needed
      await _createDefaultCategories();
      
      // Update existing accounts with correct bank logos
      await _updateExistingAccountLogos();
    } catch (e) {
      print('Error initializing database service: $e');
      throw Exception('Cannot initialize database service: $e');
    }
    
    // Migrate data if needed (skip on first run)
    if (!firstRun) {
      try {
        print('Starting data migration...');
        await _migrateData();
        print('Data migration completed successfully');
      } catch (e) {
        print('Error during data migration: $e');
        // Continue anyway since this is not critical
      }
    }
    
    // Determine initial route
    print('Determining initial route...');
    String initialRoute;
    
    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    final isFirstLaunch = prefs.getBool(AppConstants.isFirstLaunchKey) ?? true;
    
    // Check if user setup is completed
    final userRepository = UserRepository();
    final hasUserProfile = await userRepository.hasUserProfile();
    
    // Set first launch to false regardless of what happens, so we only see onboarding once
    if (isFirstLaunch) {
      await prefs.setBool(AppConstants.isFirstLaunchKey, false);
    }
    
    print('First launch: $isFirstLaunch');
    print('Onboarding completed: $hasCompletedOnboarding');
    print('User profile exists: $hasUserProfile');
    
    if (!hasCompletedOnboarding) {
      initialRoute = AppRouter.onboarding;
      print('Going to onboarding screen');
    } else if (!hasUserProfile) {
      initialRoute = AppRouter.userSetup;
      print('Going to user setup screen');
    } else {
      // Use the splash route for biometric authentication
      initialRoute = AppRouter.splash;
      print('Going to splash screen for authentication');
    }
    
    print('Starting app with route: $initialRoute');
    
    // Remove splash screen when initialization is done
    FlutterNativeSplash.remove();
    
    // Initialize singletons/repositories
    final accountRepository = AccountRepository();
    final transactionRepository = TransactionRepository();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()..initialize()),
          ChangeNotifierProvider(create: (context) {
            // Access the UserProfileProvider to ensure it's initialized first
            final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
            // Set context for the UserProfileProvider
            userProfileProvider.setContext(context);
            return CurrencyProvider();
          }),
          Provider<UserRepository>(create: (_) => userRepository),
          Provider<CategoryRepository>(create: (_) => CategoryRepository()),
          Provider<TransactionRepository>.value(value: transactionRepository),
          Provider<AccountRepository>.value(value: accountRepository),
          Provider<BudgetRepository>(create: (_) => BudgetRepository()),
        ],
        child: PaisaTrackApp(initialRoute: initialRoute),
      ),
    );
  } catch (e) {
    // Remove splash screen in case of error
    FlutterNativeSplash.remove();
    
    print('FATAL ERROR during app initialization: $e');
    // Show a simple error screen instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // First, try to close any open boxes
                      print('Attempting to reset app data...');
                      
                      // Delete all Hive data using our improved method
                      await _deleteHiveBoxes();
                      
                      // Clear any preferences
                      print('Clearing preferences...');
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App data reset successfully! Restarting app...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Wait a moment to show the success message
                      await Future.delayed(const Duration(seconds: 2));
                      
                      // Exit the app for a complete restart
                      // The system will restart the app, which will reinitialize everything
                      SystemNavigator.pop();
                    } catch (e) {
                      print('Error resetting app data: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to reset app: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Reset App Data'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

void _registerHiveAdapters() {
  try {
    print('Registering Hive adapters...');
    
    // Register type adapters for enums first
    _safeRegisterAdapter(() {
      print('Registering CountryTypeAdapter...');
      Hive.registerAdapter(CountryTypeAdapter());
    });
    
    _safeRegisterAdapter(() {
      print('Registering CurrencyTypeAdapter...');
      Hive.registerAdapter(CurrencyTypeAdapter());
    });
    
    _safeRegisterAdapter(() {
      print('Registering AccountTypeAdapter...');
      Hive.registerAdapter(AccountTypeAdapter());
    });
    
    _safeRegisterAdapter(() {
      print('Registering TransactionTypeAdapter...');
      Hive.registerAdapter(TransactionTypeAdapter());
    });
    
    // Register type adapters for models
    _safeRegisterAdapter(() {
      print('Registering UserProfileModelAdapter...');
      Hive.registerAdapter(UserProfileModelAdapter());
    });
    
    _safeRegisterAdapter(() {
      print('Registering CategoryModelAdapter...');
      Hive.registerAdapter(CategoryModelAdapter());
    });
    
    _safeRegisterAdapter(() {
      print('Registering AccountModelAdapter...');
      Hive.registerAdapter(AccountModelAdapter());
    });
    
    // Override the account model adapter with our custom implementation for proper type handling
    _unregisterAndRegisterAdapter('AccountModel', CustomAccountModelAdapter());
    
    _safeRegisterAdapter(() {
      print('Registering TransactionModelAdapter...');
      Hive.registerAdapter(TransactionModelAdapter());
    });
    
    _safeRegisterAdapter(() {
      print('Registering BudgetModelAdapter...');
      Hive.registerAdapter(BudgetModelAdapter());
    });
    
    print('All Hive adapters registered successfully');
  } catch (e) {
    print('Error registering Hive adapters: $e');
    throw e; // Re-throw to be caught by the calling context
  }
}

void _safeRegisterAdapter(Function register) {
  try {
    register();
  } catch (e) {
    if (e.toString().contains('already a TypeAdapter')) {
      print('Info: Adapter already registered. This is expected during recovery: ${e.toString()}');
    } else {
      print('Error registering adapter: ${e.toString()}');
      print('Full error details: $e');
      print('Stack trace: ${StackTrace.current}');
      // Don't throw here to prevent app from crashing if one adapter fails
    }
  }
}

Future<void> _openHiveBoxes() async {
  // Open all required boxes
  await Hive.openBox<AccountModel>(AppConstants.accountsBox);
  await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
  await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
  await Hive.openBox<UserProfileModel>(AppConstants.userProfileBox);
}

Future<void> _deleteHiveBoxes() async {
  try {
    print('Deleting Hive boxes...');
    
    // First try to close any open boxes
    await Hive.close();
    
    // Get the Hive directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/hive';
    
    // Delete all existing box files manually
    final dir = Directory(hivePath);
    if (await dir.exists()) {
      try {
        // List all files and directories
        final entities = dir.listSync();
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
              print('Deleted file: ${entity.path}');
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
              print('Deleted directory: ${entity.path}');
            }
          } catch (e) {
            print('Error deleting entity ${entity.path}: $e');
          }
        }
        
        // Then try to delete the whole directory
        await dir.delete(recursive: true);
        print('Deleted main Hive directory');
      } catch (e) {
        print('Error while deleting Hive directory contents: $e');
      }
    } else {
      print('Hive directory does not exist, nothing to delete');
    }
    
    // Recreate the directory
    try {
      await dir.create(recursive: true);
      print('Recreated Hive directory');
    } catch (e) {
      print('Error recreating Hive directory: $e');
    }
    
    print('Hive boxes deletion completed');
  } catch (e) {
    print('Error in _deleteHiveBoxes: $e');
    // Don't throw here to continue with app initialization
  }
}

/// Handles any data migrations needed when updating the app
Future<void> _migrateData() async {
  print('Starting data migration...');
  try {
    // Migrate user profile for country field if missing
    final userRepository = UserRepository();
    final userProfileBox = await Hive.openBox<UserProfileModel>('user_profiles');
    
    if (userProfileBox.isNotEmpty) {
      final userProfile = userProfileBox.getAt(0);
      print('Found existing user profile: ${userProfile?.name}');
      
      if (userProfile != null) {
        // Check if the country field is null and needs migration
        if (userProfile.country == null) {
          print('Country field is null, migrating profile...');
          
          // Infer country from currency if possible
          CountryType inferredCountry = CountryType.unitedStates; // Default
          
          try {
            // Logic to infer country from currency
            final currencyCode = userProfile.defaultCurrencyCode;
            print('Inferring country from currency: $currencyCode');
            
            if (currencyCode == 'USD') {
              inferredCountry = CountryType.unitedStates;
            } else if (currencyCode == 'EUR') {
              inferredCountry = CountryType.germany; // or another EUR country
            } else if (currencyCode == 'GBP') {
              inferredCountry = CountryType.unitedKingdom;
            } else if (currencyCode == 'JPY') {
              inferredCountry = CountryType.japan;
            } else if (currencyCode == 'INR') {
              inferredCountry = CountryType.india;
            } else if (currencyCode == 'CAD') {
              inferredCountry = CountryType.canada;
            } else if (currencyCode == 'AUD') {
              inferredCountry = CountryType.australia;
            } else {
              // Default case
              inferredCountry = CountryType.unitedStates;
            }
            
            print('Inferred country: ${inferredCountry.toString()}');
            
            // Create a new profile with the country field
            final updatedProfile = UserProfileModel(
              id: userProfile.id,
              name: userProfile.name,
              profileImagePath: userProfile.profileImagePath,
              defaultCurrencyCode: userProfile.defaultCurrencyCode,
              createdAt: userProfile.createdAt,
              lastUpdated: DateTime.now(),
              locale: userProfile.locale ?? 'en_US',
              themeMode: userProfile.themeMode ?? 'system',
              isBiometricEnabled: userProfile.isBiometricEnabled ?? false,
              country: inferredCountry,
            );
            
            // Delete old profile and save the new one
            try {
              await userProfileBox.deleteAt(0);
              await userProfileBox.add(updatedProfile);
              print('User profile successfully migrated with country field');
            } catch (e) {
              print('Error updating user profile: $e');
              // Try an alternative approach if the first fails
              try {
                await userProfileBox.putAt(0, updatedProfile);
                print('User profile updated using putAt');
              } catch (e) {
                print('Failed to update user profile: $e');
              }
            }
          } catch (e) {
            print('Error during country inference: $e');
          }
        } else {
          print('User profile already has country field: ${userProfile.country}');
        }
      }
    } else {
      print('No user profile found to migrate');
    }
    
    // Migrate accounts for accountHolderName field if missing
    print('Migrating account data for accountHolderName field...');
    final accountBox = await Hive.openBox<AccountModel>('accounts');
    for (int i = 0; i < accountBox.length; i++) {
      try {
        final account = accountBox.getAt(i);
        if (account != null && account.type == AccountType.bank && account.accountHolderName == null) {
          print('Migrating bank account: ${account.name}');
          
          // Get user profile first
          final userProfile = await userRepository.getUserProfile();
          
          final updatedAccount = AccountModel(
            id: account.id,
            name: account.name,
            type: account.type,
            balance: account.balance,
            currency: account.currency,
            createdAt: account.createdAt,
            isArchived: account.isArchived,
            bankName: account.bankName,
            accountNumber: account.accountNumber,
            accountHolderName: userProfile?.name ?? '',
          );
          
          await accountBox.putAt(i, updatedAccount);
          print('Updated account with holder name: ${updatedAccount.accountHolderName}');
        }
      } catch (e) {
        print('Error migrating account at index $i: $e');
      }
    }
    
    print('Data migration completed successfully');
  } catch (e) {
    print('Error during data migration: $e');
  }
}

Future<void> _initializeHive() async {
  // Set preferred device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize database service (this is separate from opening boxes)
  await DatabaseService().init();
}

/// Create default categories if they don't exist
Future<void> _createDefaultCategories() async {
  try {
    print('Checking for default categories...');
    final categoryBox = Hive.box<CategoryModel>(AppConstants.categoriesBox);
    
    if (categoryBox.isEmpty) {
      print('Creating default categories...');
      // Add default categories
      final defaultExpenses = CategoryModel.defaultExpenseCategories();
      final defaultIncomes = CategoryModel.defaultIncomeCategories();
      
      for (final category in [...defaultExpenses, ...defaultIncomes]) {
        await categoryBox.put(category.id, category);
      }
      print('Default categories created successfully');
    } else {
      print('Default categories already exist');
    }
  } catch (e) {
    print('Error creating default categories: $e');
    // Continue anyway, not critical
  }
}

/// Update existing accounts with correct bank logos
Future<void> _updateExistingAccountLogos() async {
  try {
    print('Checking for accounts that need logo path updates...');
    final databaseService = DatabaseService();
    final accountsBox = databaseService.accountsBox;
    final accountsList = accountsBox.values.toList();
    
    // Get all available Nepali banks for reference
    final allNepaliBanks = NepalBankData.getNepaliBanks();
    final allWallets = NepalBankData.getNepaliDigitalWallets();
    final Map<String, Bank> bankNameMap = {};
    
    // Create a map of bank names (lowercase) to Bank objects for easy lookup
    for (final bank in [...allNepaliBanks, ...allWallets]) {
      bankNameMap[bank.name.toLowerCase()] = bank;
    }
    
    // Count how many accounts need updates
    int updatedCount = 0;
    
    // Loop through all accounts and ensure bankLogoPath is properly set
    for (final account in accountsList) {
      bool needsUpdate = false;
      String? newLogoPath;
      
      // If account has no logo path or an empty one
      if (account.bankLogoPath == null || account.bankLogoPath!.isEmpty) {
        if (account.type == AccountType.bank || account.type == AccountType.digitalWallet) {
          // Try to find a matching bank in our data
          final bankName = account.bankName?.toLowerCase() ?? account.name.toLowerCase();
          
          // Look for a direct match first
          if (bankNameMap.containsKey(bankName)) {
            newLogoPath = bankNameMap[bankName]!.logoPath;
            print('Found matching bank for: $bankName');
          } else {
            // Look for partial matches (e.g., "NIC Asia" might match with "NIC Asia Bank Ltd")
            for (final entry in bankNameMap.entries) {
              if (entry.key.contains(bankName) || bankName.contains(entry.key)) {
                newLogoPath = entry.value.logoPath;
                print('Found partial match for: $bankName -> ${entry.key}');
                break;
              }
            }
          }
          
          // If no match found, use default app icon
          if (newLogoPath == null || newLogoPath.isEmpty) {
            newLogoPath = 'assets/images/app_icon.png';
            print('Using default app icon for: $bankName');
          }
          
          // Update the account with the new logo path
          final updatedAccount = account.copyWith(bankLogoPath: newLogoPath);
          await accountsBox.put(account.id, updatedAccount);
          needsUpdate = true;
          updatedCount++;
        }
      }
      
      if (needsUpdate) {
        print('Updated account: ${account.name} with logo: $newLogoPath');
      }
    }
    
    if (updatedCount > 0) {
      print('Updated $updatedCount accounts with missing logo paths');
    } else {
      print('No accounts needed logo path updates');
    }
  } catch (e) {
    print('Error updating account logos: $e');
  }
}

class PaisaTrackApp extends StatefulWidget {
  final String initialRoute;
  
  const PaisaTrackApp({
    Key? key,
    required this.initialRoute,
  }) : super(key: key);

  @override
  State<PaisaTrackApp> createState() => _PaisaTrackAppState();
}

class _PaisaTrackAppState extends State<PaisaTrackApp> {
  @override
  Widget build(BuildContext context) {
    // Using Consumer for ThemeProvider to listen to theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: widget.initialRoute,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      // Close Hive boxes when app is closed
      Hive.close();
      
      // Get repositories from provider
      if (context != null) {
        try {
          final transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
          transactionRepository.dispose();
          
          final accountRepository = Provider.of<AccountRepository>(context, listen: false);
          accountRepository.dispose();
          
          print('Repositories successfully disposed');
        } catch (e) {
          print('Error disposing repositories: $e');
        }
      }
    } catch (e) {
      print('Error in app disposal: $e');
    }
    
    super.dispose();
  }
}

/// Generates app icons at various sizes for Android and iOS
Future<void> generateAppIcon() async {
  print('Note: App now using the provided asset image instead of generated icon.');
  print('The app_icon.png file in assets/images/ is the source icon.');
  print('To update the app icon, replace that file with a new image.');
  
  // No need to generate icons since we're now using the asset
  // The flutter_launcher_icons package will handle creating appropriate sized 
  // versions for different platforms during the build process.
}

// Add a helper to override existing adapters
void _unregisterAndRegisterAdapter<T>(String name, TypeAdapter<T> adapter) {
  print('Overriding adapter for $name...');
  try {
    if (Hive.isAdapterRegistered(adapter.typeId)) {
      // Note: Hive doesn't have a clean way to unregister adapters, but we can replace them
      print('Adapter with typeId ${adapter.typeId} was already registered, replacing it');
    }
    Hive.registerAdapter(adapter, override: true);
    print('Successfully registered adapter for $name');
  } catch (e) {
    print('Error while registering adapter for $name: $e');
  }
}
