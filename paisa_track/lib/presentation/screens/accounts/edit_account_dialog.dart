import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';

class EditAccountDialog extends StatefulWidget {
  final AccountModel account;
  
  const EditAccountDialog({
    super.key,
    required this.account,
  });

  @override
  State<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _accountHolderController;
  
  late AccountType _selectedType;
  late CurrencyType _selectedCurrency;
  late Color _selectedColor;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing account data
    _nameController = TextEditingController(text: widget.account.name);
    _bankNameController = TextEditingController(text: widget.account.bankName ?? '');
    _accountNumberController = TextEditingController(text: widget.account.accountNumber ?? '');
    _descriptionController = TextEditingController(text: widget.account.description ?? '');
    _accountHolderController = TextEditingController(text: widget.account.accountHolderName ?? '');
    
    // Initialize other fields
    _selectedType = widget.account.type;
    _selectedCurrency = widget.account.currency;
    _selectedColor = widget.account.color;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _descriptionController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Account Type Selection
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Account Name - only show for non-bank accounts
              if (_selectedType != AccountType.bank)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _selectedType == AccountType.wallet ? 'Wallet Name' : 'Account Name',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              
              // Show spacing only if account name is displayed
              if (_selectedType != AccountType.bank)
                const SizedBox(height: 16),
              
              // Bank Details (only for bank accounts)
              if (_selectedType == AccountType.bank) ...[
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bank name';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Update the name controller with the bank name for bank accounts
                    _nameController.text = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account holder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Color Selection
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ColorConstants.accountColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor.value == color.value
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      // For bank accounts, ensure the account name is the same as the bank name
      if (_selectedType == AccountType.bank) {
        _nameController.text = _bankNameController.text;
      }
      
      final updatedAccount = widget.account.copyWith(
        name: _nameController.text,
        type: _selectedType,
        currency: _selectedCurrency,
        colorValue: _selectedColor.value,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        bankName: _selectedType == AccountType.bank ? _bankNameController.text : null,
        accountNumber: _selectedType == AccountType.bank && _accountNumberController.text.isNotEmpty 
            ? _accountNumberController.text 
            : null,
        accountHolderName: _selectedType == AccountType.bank ? _accountHolderController.text : null,
      );
      
      Navigator.pop(context, updatedAccount);
    }
  }
} 