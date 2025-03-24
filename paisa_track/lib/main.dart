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
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:paisa_track/data/models/app_icon.dart';
import 'package:paisa_track/data/models/bank_data.dart';

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
      
      // Try to recover by deleting all boxes and starting fresh
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
    
    // Check if user setup is completed
    final userRepository = UserRepository();
    final hasUserProfile = await userRepository.hasUserProfile();
    
    if (!hasCompletedOnboarding) {
      initialRoute = AppRouter.onboarding;
      print('Going to onboarding screen');
    } else if (!hasUserProfile) {
      initialRoute = AppRouter.userSetup;
      print('Going to user setup screen');
    } else {
      initialRoute = AppRouter.dashboard;
      print('Going to dashboard screen');
    }
    
    print('Starting app with route: $initialRoute');
    
    // Remove splash screen when initialization is done
    FlutterNativeSplash.remove();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()..initialize()),
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
                    // Try to delete all data and restart the app
                    try {
                      // Clear any registered adapters first
                      try {
                        // There's no public API to reset TypeAdapters in Hive,
                        // but we can force close Hive entirely which has a similar effect
                        await Hive.close();
                      } catch (e) {
                        print('Error closing Hive: $e');
                        // Continue anyway
                      }
                      
                      // Initialize Hive again
                      await Hive.initFlutter();
                      
                      // Delete Hive directory
                      final appDocDir = await getApplicationDocumentsDirectory();
                      final hivePath = '${appDocDir.path}/hive';
                      try {
                        await Directory(hivePath).delete(recursive: true);
                        print('Successfully deleted Hive directory');
                      } catch (e) {
                        print('Error deleting Hive directory: $e');
                        // If we can't delete it, we'll skip trying to clear boxes 
                        // since Hive.boxes API is not available
                      }
                      
                      // Also clear shared preferences
                      await SharedPreferences.getInstance().then((prefs) => prefs.clear());
                      print('Successfully cleared SharedPreferences');
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data cleared successfully. Restarting app...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Give UI time to show the message
                      await Future.delayed(const Duration(seconds: 1));
                      
                      // Restart the app (this actually just reruns main())
                      main();
                    } catch (e) {
                      print('Failed to reset app: $e');
                      
                      // Show error message
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
  // Get the Hive directory
  final appDocDir = await getApplicationDocumentsDirectory();
  final hivePath = '${appDocDir.path}/hive';
  
  // Delete all existing boxes
  final dir = Directory(hivePath);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  
  // Recreate the directory
  await dir.create(recursive: true);
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

class PaisaTrackApp extends StatelessWidget {
  final String initialRoute;
  
  const PaisaTrackApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserRepository>(
          create: (_) => UserRepository(),
        ),
        Provider<CategoryRepository>(
          create: (_) => CategoryRepository(),
        ),
        Provider<TransactionRepository>(
          create: (_) => TransactionRepository(),
        ),
        Provider<BudgetRepository>(
          create: (_) => BudgetRepository(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeConstants.lightTheme,
        darkTheme: ThemeConstants.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
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
