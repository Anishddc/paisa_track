import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final AccountModel account;
  final String currencySymbol;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.account,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountText = '$currencySymbol${transaction.amount.toStringAsFixed(2)}';
    final amountColor = isIncome ? ColorConstants.successColor : ColorConstants.errorColor;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: amountColor.withOpacity(0.1),
            child: Icon(
              icon,
              color: amountColor,
            ),
          ),
          title: Text(transaction.description),
          subtitle: Text(
            '${account.name} • ${_formatDate(transaction.date)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            amountText,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 