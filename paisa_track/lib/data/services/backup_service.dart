import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/budget_model.dart';

class BackupService {
  final DatabaseService _databaseService;
  
  BackupService({DatabaseService? databaseService}) 
      : _databaseService = databaseService ?? DatabaseService();
  
  /// Creates a backup of all app data and returns the path to the backup file
  Future<String> createBackup() async {
    try {
      // Create a map with all the data
      final backupData = {
        'metadata': {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'app': 'Paisa Track',
        },
        'user_profile': _databaseService.userProfileBox.values.map((profile) => profile.toJson()).toList(),
        'accounts': _databaseService.accountsBox.values.map((account) => account.toJson()).toList(),
        'categories': _databaseService.categoriesBox.values.map((category) => category.toJson()).toList(),
        'transactions': _databaseService.transactionsBox.values.map((transaction) => transaction.toJson()).toList(),
        'budgets': _databaseService.budgetsBox.values.map((budget) => budget.toJson()).toList(),
      };
      
      // Convert to JSON
      final jsonData = jsonEncode(backupData);
      
      // Get the backup directory
      final directory = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/paisa_track_backup_$timestamp.json';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      return filePath;
    } catch (e) {
      print('Error in createBackup: $e');
      // Try a simpler approach as a fallback
      return await _createSimpleBackup();
    }
  }
  
  /// Simpler backup method as a fallback
  Future<String> _createSimpleBackup() async {
    try {
      // Get application documents directory (should work on all platforms)
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'paisa_track_backup_$timestamp.json';
      final filePath = '${appDir.path}/$fileName';
      
      // Create a simplified backup with just essential data
      final userProfiles = _databaseService.userProfileBox.values.map((profile) => profile.toJson()).toList();
      final accounts = _databaseService.accountsBox.values.map((account) => account.toJson()).toList();
      final categories = _databaseService.categoriesBox.values.map((category) => category.toJson()).toList();
      
      final backupData = {
        'metadata': {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'app': 'Paisa Track',
          'simplified': true,
        },
        'user_profile': userProfiles,
        'accounts': accounts,
        'categories': categories,
        // Exclude transactions and budgets to keep the file smaller
      };
      
      // Convert to JSON
      final jsonData = jsonEncode(backupData);
      
      // Write the file
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      return filePath;
    } catch (e) {
      print('Error in simple backup: $e');
      throw Exception('Failed to create backup: $e');
    }
  }
  
  /// Restores data from a backup file
  Future<void> restoreFromBackup(String filePath) async {
    try {
      // Read the backup file
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }
      
      final jsonData = await file.readAsString();
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Verify version compatibility
      final metadata = backupData['metadata'] as Map<String, dynamic>;
      final version = metadata['version'] as String;
      if (!_isVersionCompatible(version)) {
        throw Exception('Incompatible backup version: $version');
      }
      
      // Clear existing data
      await _databaseService.clearAllData();
      
      // Restore user profiles
      final userProfiles = backupData['user_profile'] as List;
      for (final profileJson in userProfiles) {
        await _databaseService.userProfileBox.add(UserProfileModel.fromJson(profileJson as Map<String, dynamic>));
      }
      
      // Restore accounts
      final accounts = backupData['accounts'] as List;
      for (final accountJson in accounts) {
        await _databaseService.accountsBox.add(AccountModel.fromJson(accountJson as Map<String, dynamic>));
      }
      
      // Restore categories
      final categories = backupData['categories'] as List;
      for (final categoryJson in categories) {
        await _databaseService.categoriesBox.add(CategoryModel.fromJson(categoryJson as Map<String, dynamic>));
      }
      
      // Check if we have transactions and budgets in the backup
      if (backupData.containsKey('transactions')) {
        final transactions = backupData['transactions'] as List;
        for (final transactionJson in transactions) {
          await _databaseService.transactionsBox.add(TransactionModel.fromJson(transactionJson as Map<String, dynamic>));
        }
      }
      
      if (backupData.containsKey('budgets')) {
        final budgets = backupData['budgets'] as List;
        for (final budgetJson in budgets) {
          await _databaseService.budgetsBox.add(BudgetModel.fromJson(budgetJson as Map<String, dynamic>));
        }
      }
      
    } catch (e) {
      throw Exception('Failed to restore from backup: $e');
    }
  }
  
  /// Checks if the user has granted storage permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      print('Checking storage permissions');
      if (Platform.isAndroid) {
        // Check for storage permission
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          print('Requesting storage permission');
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return true;
      }
      
      // iOS doesn't need explicit permissions for this directory
      return true;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }
  
  /// No longer needed as we're using app's internal storage
  Future<bool> _isAndroid11OrHigher() async {
    return false;
  }
  
  /// Lists all available backup files in the app's backup directory
  Future<List<FileSystemEntity>> listBackupFiles() async {
    try {
      final directory = await _getBackupDirectory();
      final entities = await directory.list().toList();
      
      // Filter for JSON files that start with paisa_track_backup
      return entities.where((entity) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          return fileName.startsWith('paisa_track_backup') && fileName.endsWith('.json');
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error listing backup files: $e');
      return [];
    }
  }
  
  /// Get the directory to store backups
  Future<Directory> _getBackupDirectory() async {
    try {
      // Use external storage directory that's visible to users
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        print('External storage directory is null, using app documents directory instead');
        final appDocsDir = await getApplicationDocumentsDirectory();
        return appDocsDir;
      }
      
      // Create a specific directory for our backups that will be visible to users
      final backupDir = Directory('${externalDir.path}/PaisaTrackBackups');
      
      print('Using backup directory: ${backupDir.path}');
      
      // Create the directory if it doesn't exist
      if (!(await backupDir.exists())) {
        await backupDir.create(recursive: true);
        print('Created backup directory: ${backupDir.path}');
      }
      
      return backupDir;
    } catch (e) {
      print('Error getting backup directory: $e');
      // If all else fails, use application documents directory
      final directory = await getApplicationDocumentsDirectory();
      print('Fallback to app documents directory: ${directory.path}');
      return directory;
    }
  }
  
  /// Checks if the backup version is compatible with the current app version
  bool _isVersionCompatible(String version) {
    // For now, accept any version that starts with 1.x.x
    return version.startsWith('1.');
  }
} 