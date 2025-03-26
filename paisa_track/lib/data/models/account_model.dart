import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:uuid/uuid.dart';

part 'account_model.g.dart';

@HiveType(typeId: AppConstants.accountModelId)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double balance;
  
  @HiveField(3)
  final String _typeString;
  
  @HiveField(4)
  final CurrencyType currency;
  
  @HiveField(5)
  final String? description;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime updatedAt;
  
  @HiveField(8)
  final bool isArchived;
  
  @HiveField(9)
  final String? bankName;
  
  @HiveField(10)
  final String? accountNumber;
  
  @HiveField(11)
  final int colorValue;
  
  @HiveField(12)
  final String? accountHolderName;
  
  @HiveField(13)
  final int? iconData;
  
  @HiveField(14)
  final String? bankLogoPath;
  
  @HiveField(15)
  final double initialBalance;
  
  @HiveField(16)
  final String? userName;
  
  // New field to explicitly store the account type as an index
  @HiveField(17, defaultValue: 1) // 1 is the index of cash
  final int _typeIndex;
  
  static const IconData defaultIcon = Icons.account_balance;
  
  // Helper method to get an explicit type index from AccountType
  static int _getTypeIndex(AccountType type) {
    return AccountType.values.indexOf(type);
  }
  
  // Helper method to get AccountType from index
  static AccountType _getTypeFromIndex(int index) {
    if (index >= 0 && index < AccountType.values.length) {
      return AccountType.values[index];
    }
    return AccountType.cash; // Fallback
  }
  
  // Convert AccountType to String for storage
  String _accountTypeToString(AccountType type) {
    return 'AccountType.${type.name}';
  }
  
  // Convert String to AccountType
  static AccountType _stringToAccountType(dynamic typeInput) {
    try {
      // If it's already an AccountType enum, return it directly
      if (typeInput is AccountType) {
        return typeInput;
      }
      
      // Handle int (for index-based lookup)
      if (typeInput is int) {
        return _getTypeFromIndex(typeInput);
      }
      
      // Convert to string to handle various input formats
      final typeString = typeInput.toString();
      
      // Handle full enum path names
      if (typeString.contains('AccountType.')) {
        final typeName = typeString.split('.').last;
        return AccountType.values.firstWhere(
          (e) => e.name == typeName,
          orElse: () => AccountType.cash,
        );
      }
      
      // Handle simple enum value names
      return AccountType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => AccountType.cash,
      );
    } catch (_) {
      return AccountType.cash;
    }
  }
  
  // Getter to access AccountType - now uses both _typeIndex and _typeString for reliability
  AccountType get type {
    try {
      // First try to use the type index as the most reliable method
      if (_typeIndex >= 0 && _typeIndex < AccountType.values.length) {
        return AccountType.values[_typeIndex];
      }
      
      // Fall back to string parsing if needed
      return _stringToAccountType(_typeString);
    } catch (_) {
      // Ultimate fallback
      return AccountType.cash;
    }
  }
  
  // Getter to access raw _typeString for debugging
  String get typeString => _typeString;
  
  // Getter to access _typeIndex for debugging
  int get typeIndex => _typeIndex;
  
  AccountModel({
    String? id,
    required this.name,
    this.balance = 0.0,
    Object? type, // Accept any type for flexibility
    CurrencyType? currency,
    String? currencyCode,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
    this.bankName,
    this.accountNumber,
    this.colorValue = 0xFF0099FF,
    this.accountHolderName,
    this.iconData,
    IconData? icon,
    this.bankLogoPath,
    double? initialBalance,
    this.userName,
    int? typeIndex,
  }) : id = id ?? const Uuid().v4(),
       // Determine the actual AccountType from input
       _typeIndex = typeIndex ?? (type is AccountType
           ? _getTypeIndex(type)
           : (type is int
               ? type
               : _getTypeIndex(_stringToAccountType(type)))),
       // Store the string representation as well for backward compatibility
       _typeString = type is AccountType 
           ? 'AccountType.${type.name}'
           : (type is String 
               ? (type.contains('AccountType.') ? type : 'AccountType.${_stringToAccountType(type).name}')
               : 'AccountType.${_stringToAccountType(type).name}'),
       currency = currency ?? (currencyCode != null ? CurrencyType.fromCode(currencyCode) : CurrencyType.usd),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       initialBalance = initialBalance ?? balance;
  
  // Backward compatibility getters
  String get currencyCode => currency.name;
  
  // Color based on the stored colorValue
  Color get color => Color(colorValue);
  
  IconData get icon {
    // If iconData is provided, use it
    if (iconData != null) {
      return IconData(iconData!, fontFamily: 'MaterialIcons');
    }
    
    // Otherwise use the default icon for the account type
    return type.icon;
  }
  
  // Update balance method
  AccountModel updateBalance(double newBalance) {
    return copyWith(
      balance: newBalance,
    );
  }
  
  // Add an amount to balance
  AccountModel addToBalance(double amount) {
    final newBalance = balance + amount;
    return copyWith(
      balance: newBalance,
    );
  }
  
  // Subtract an amount from balance
  AccountModel subtractFromBalance(double amount) {
    final newBalance = balance - amount;
    return copyWith(
      balance: newBalance,
    );
  }
  
  AccountModel copyWith({
    String? name,
    double? balance,
    Object? type,
    CurrencyType? currency,
    String? description,
    bool? isArchived,
    String? bankName,
    String? accountNumber,
    int? colorValue,
    DateTime? updatedAt,
    String? accountHolderName,
    int? iconData,
    String? bankLogoPath,
    double? initialBalance,
    String? userName,
  }) {
    // Determine the AccountType to use
    final AccountType newType = type is AccountType 
        ? type 
        : (type is String 
            ? _stringToAccountType(type) 
            : this.type);
            
    // Get the type index explicitly
    final int newTypeIndex = type != null
        ? _getTypeIndex(newType)
        : _typeIndex;
            
    return AccountModel(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: newType,
      typeIndex: newTypeIndex, // Pass the explicit type index
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isArchived: isArchived ?? this.isArchived,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      colorValue: colorValue ?? this.colorValue,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      iconData: iconData ?? this.iconData,
      bankLogoPath: bankLogoPath ?? this.bankLogoPath,
      initialBalance: initialBalance ?? this.initialBalance,
      userName: userName ?? this.userName,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': _typeString,
      'currency': currency.toString(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'colorValue': colorValue,
      'accountHolderName': accountHolderName,
      'iconData': iconData,
      'bankLogoPath': bankLogoPath,
      'initialBalance': initialBalance,
      'userName': userName,
    };
  }
  
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    // Type handling is done in the constructor
    return AccountModel(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
      type: json['type'],
      currency: CurrencyType.values.firstWhere(
        (e) => e.toString() == json['currency'],
        orElse: () => CurrencyType.usd,
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isArchived: json['isArchived'] ?? false,
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      colorValue: json['colorValue'] ?? 0xFF0099FF,
      accountHolderName: json['accountHolderName'],
      iconData: json['iconData'],
      bankLogoPath: json['bankLogoPath'],
      initialBalance: json['initialBalance']?.toDouble(),
      userName: json['userName'],
    );
  }
} 