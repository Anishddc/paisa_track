import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';

part 'account_type.g.dart';

@HiveType(typeId: AppConstants.accountTypeId)
enum AccountType {
  @HiveField(0)
  bank,
  
  @HiveField(1)
  cash,
  
  @HiveField(2)
  digitalWallet,
  
  @HiveField(3)
  card,
  
  @HiveField(4)
  wallet,
  
  @HiveField(5)
  creditCard,
  
  @HiveField(6)
  investment,
  
  @HiveField(7)
  loan,
  
  @HiveField(8)
  other,
}

extension AccountTypeExtension on AccountType {
  String get name {
    switch (this) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.cash:
        return 'Cash';
      case AccountType.digitalWallet:
        return 'Digital Wallet';
      case AccountType.card:
        return 'Card';
      case AccountType.wallet:
        return 'Wallet';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.investment:
        return 'Investment';
      case AccountType.loan:
        return 'Loan';
      case AccountType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.digitalWallet:
        return Icons.account_balance_wallet;
      case AccountType.card:
        return Icons.credit_card;
      case AccountType.wallet:
        return Icons.wallet;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.loan:
        return Icons.monetization_on;
      case AccountType.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case AccountType.bank:
        return Colors.blue;
      case AccountType.cash:
        return Colors.green;
      case AccountType.digitalWallet:
        return Colors.purple;
      case AccountType.card:
        return Colors.orange.shade800;
      case AccountType.wallet:
        return Colors.orange;
      case AccountType.creditCard:
        return Colors.red;
      case AccountType.investment:
        return Colors.teal;
      case AccountType.loan:
        return Colors.amber;
      case AccountType.other:
        return Colors.grey;
    }
  }
  
  int get colorValue {
    return color.value;
  }
} 