import 'package:flutter/material.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_dialog.dart';
import 'package:paisa_track/presentation/widgets/common/confirmation_dialog.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:paisa_track/presentation/widgets/common/error_view.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/core/utils/date_utils.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailsScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AccountRepository _accountRepository = AccountRepository();
  
  TransactionModel? _transaction;
  CategoryModel? _category;
  AccountModel? _account;
  AccountModel? _destinationAccount;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get transaction
      final transaction = _transactionRepository.getTransactionById(widget.transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      // Get category
      final category = _categoryRepository.getCategoryById(transaction.categoryId);
      if (category == null) {
        throw Exception('Category not found');
      }

      // Get account
      final account = _accountRepository.getAccountById(transaction.accountId);
      if (account == null) {
        throw Exception('Account not found');
      }

      // Get destination account for transfers
      AccountModel? destinationAccount;
      if (transaction.type == TransactionType.transfer && transaction.destinationAccountId != null) {
        destinationAccount = _accountRepository.getAccountById(transaction.destinationAccountId!);
      }

      setState(() {
        _transaction = transaction;
        _category = category;
        _account = account;
        _destinationAccount = destinationAccount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load transaction details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditTransactionDialog() async {
    if (_transaction == null || _account == null) return;

    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        account: _account!,
      ),
    ).then((result) {
      if (result != null && mounted) {
        _loadTransactionDetails();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
      }
    });
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Delete Transaction',
        message: 'Are you sure you want to delete this transaction? This action cannot be undone.',
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _transactionRepository.deleteTransaction(_transaction!.id);
        
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted successfully'),
              backgroundColor: ColorConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: ColorConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditTransactionDialog,
            tooltip: 'Edit Transaction',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: ColorConstants.errorColor),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Transaction',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: _loadTransactionDetails,
                )
              : _buildTransactionDetails(),
    );
  }

  Widget _buildTransactionDetails() {
    if (_transaction == null || _category == null || _account == null) {
      return const Center(child: Text('Transaction not found'));
    }

    final isIncome = _transaction!.type == TransactionType.income;
    final isTransfer = _transaction!.type == TransactionType.transfer;
    final amountColor = isIncome
        ? ColorConstants.successColor
        : isTransfer
            ? ColorConstants.infoColor
            : ColorConstants.errorColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount
          Center(
            child: Text(
              '${_account!.currency.symbol}${_transaction!.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Transaction Type
          _buildDetailRow(
            'Type',
            _transaction!.type.name.toUpperCase(),
            icon: isIncome
                ? Icons.arrow_upward
                : isTransfer
                    ? Icons.swap_horiz
                    : Icons.arrow_downward,
            iconColor: amountColor,
          ),
          
          const SizedBox(height: 16),
          
          // Category
          _buildDetailRow(
            'Category',
            _category!.name,
            icon: _category!.icon,
            iconColor: _category!.color,
          ),
          
          const SizedBox(height: 16),
          
          // Account
          _buildDetailRow(
            'Account',
            _account!.name,
            icon: Icons.account_balance_wallet,
            iconColor: _account!.color,
          ),
          
          if (isTransfer && _destinationAccount != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              'To Account',
              _destinationAccount!.name,
              icon: Icons.account_balance_wallet,
              iconColor: _destinationAccount!.color,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Date and Time
          _buildDetailRow(
            'Date',
            AppDateUtils.formatDate(_transaction!.date),
            icon: Icons.calendar_today,
          ),
          
          const SizedBox(height: 8),
          
          _buildDetailRow(
            'Time',
            DateFormat('h:mm a').format(_transaction!.date),
            icon: Icons.access_time,
          ),
          
          if (_transaction!.description != null && _transaction!.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_transaction!.description!),
          ],
          
          if (_transaction!.notes != null && _transaction!.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_transaction!.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 