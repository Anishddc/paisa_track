import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/presentation/screens/accounts/add_account_dialog.dart';
import 'package:paisa_track/presentation/screens/accounts/edit_account_dialog.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  final _repository = AccountRepository();
  List<AccountModel> _accounts = [];
  
  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }
  
  Future<void> _loadAccounts() async {
    final accounts = await _repository.getAllAccounts();
    setState(() {
      _accounts = accounts;
    });
  }
  
  Future<void> _addAccount() async {
    final account = await showDialog<AccountModel>(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );
    
    if (account != null) {
      await _repository.addAccount(account);
      _loadAccounts();
    }
  }
  
  Future<void> _editAccount(AccountModel account) async {
    final updatedAccount = await showDialog<AccountModel>(
      context: context,
      builder: (context) => EditAccountDialog(account: account),
    );
    
    if (updatedAccount != null) {
      await _repository.updateAccount(updatedAccount);
      _loadAccounts();
    }
  }
  
  Future<void> _deleteAccount(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete ${account.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _repository.deleteAccount(account.id);
      _loadAccounts();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAccount,
          ),
        ],
      ),
      body: _accounts.isEmpty
          ? const Center(
              child: Text('No accounts yet. Add one to get started!'),
            )
          : ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(account.colorValue),
                      child: Text(
                        account.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(account.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.type.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (account.description != null)
                          Text(
                            account.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCurrency(
                            account.balance,
                            account.currency,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editAccount(account),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteAccount(account),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 