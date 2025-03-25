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
  
  static const IconData defaultIcon = Icons.account_balance;  // Make this constant
  
  // Convert AccountType to String for storage
  String _accountTypeToString(AccountType type) {
    return type.toString();
  }
  
  // Convert String to AccountType
  static AccountType _stringToAccountType(dynamic typeInput) {
    try {
      // If it's already an AccountType enum, return it directly
      if (typeInput is AccountType) {
        return typeInput;
      }
      
      // Convert to string to handle various input formats
      final typeString = typeInput.toString();
      
      // Handle full enum path names
      if (typeString == 'AccountType.bank') return AccountType.bank;
      if (typeString == 'AccountType.cash') return AccountType.cash;
      if (typeString == 'AccountType.digitalWallet') return AccountType.digitalWallet;
      if (typeString == 'AccountType.card') return AccountType.card;
      if (typeString == 'AccountType.wallet') return AccountType.wallet;
      if (typeString == 'AccountType.creditCard') return AccountType.creditCard;
      if (typeString == 'AccountType.investment') return AccountType.investment;
      if (typeString == 'AccountType.loan') return AccountType.loan;
      if (typeString == 'AccountType.other') return AccountType.other;
      
      // Handle simple enum value names
      if (typeString == 'bank') return AccountType.bank;
      if (typeString == 'cash') return AccountType.cash;
      if (typeString == 'digitalWallet') return AccountType.digitalWallet;
      if (typeString == 'card') return AccountType.card;
      if (typeString == 'wallet') return AccountType.wallet;
      if (typeString == 'creditCard') return AccountType.creditCard;
      if (typeString == 'investment') return AccountType.investment;
      if (typeString == 'loan') return AccountType.loan;
      if (typeString == 'other') return AccountType.other;
      
      // Try to match by enum value name or full toString() representation
      return AccountType.values.firstWhere(
        (e) => e.toString() == typeString || e.name == typeString,
        orElse: () => AccountType.cash,
      );
    } catch (_) {
      return AccountType.cash;
    }
  }
  
  // Getter to access AccountType
  AccountType get type {
    try {
      // Handle the case where _typeString might actually be an AccountType enum
      if (_typeString is AccountType) {
        return _typeString as AccountType;
      }
      
      // Otherwise, convert from string
      return _stringToAccountType(_typeString);
    } catch (_) {
      // Fallback to safe default
      return AccountType.cash;
    }
  }
  
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
  }) : id = id ?? const Uuid().v4(),
       // Handle different type parameters - now with more robust handling
       _typeString = type is AccountType 
           ? type.toString() 
           : (type is String 
               ? type 
               : AccountType.cash.toString()),
       currency = currency ?? (currencyCode != null ? CurrencyType.fromCode(currencyCode) : CurrencyType.usd),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       initialBalance = initialBalance ?? balance;
  
  // Backward compatibility getters
  String get currencyCode => currency.name;
  
  // Color based on the stored colorValue
  Color get color => Color(colorValue);
  
  IconData get icon {
    // If iconData is provided, use it, otherwise use the icon from AccountType extension
    if (iconData != null) {
      return IconData(iconData!, fontFamily: 'MaterialIcons');
    }
    
    // Use the icon from AccountType extension
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
    return AccountModel(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
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