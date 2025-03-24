import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/color_constants.dart';

part 'transaction_type.g.dart';

@HiveType(typeId: 6)
enum TransactionType {
  @HiveField(0)
  expense,
  
  @HiveField(1)
  income,
  
  @HiveField(2)
  transfer,
}

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.sync_alt;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.expense:
        return ColorConstants.errorColor;
      case TransactionType.income:
        return ColorConstants.successColor;
      case TransactionType.transfer:
        return ColorConstants.infoColor;
    }
  }
  
  bool get isIncome => this == TransactionType.income;
  
  bool get isExpense => this == TransactionType.expense;
  
  bool get isTransfer => this == TransactionType.transfer;
} 