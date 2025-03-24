import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/core/utils/validation_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/bank_data.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:uuid/uuid.dart';

class AddAccountDialog extends StatefulWidget {
  final String defaultCurrencyCode;
  final String? userName;
  
  const AddAccountDialog({
    super.key,
    this.defaultCurrencyCode = 'USD',
    this.userName,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  AccountType _selectedType = AccountType.wallet;
  CurrencyType _selectedCurrency = CurrencyType.usd;
  Color _selectedColor = ColorConstants.primaryColor;
  Bank? _selectedBank;
  bool _showBankSelection = false;
  
  List<Bank> _nepaliBanks = [];
  List<Bank> _nepaliWallets = [];
  
  @override
  void initState() {
    super.initState();
    _selectedCurrency = CurrencyType.fromCode(widget.defaultCurrencyCode);
    
    // Set the default account holder name if provided
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      _accountHolderController.text = widget.userName!;
    }
    
    // Load bank and wallet data
    _nepaliBanks = NepalBankData.getNepaliBanks();
    _nepaliWallets = NepalBankData.getNepaliDigitalWallets();
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
                'Add New Account',
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
                    _showBankSelection = (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet);
                    _selectedBank = null;
                    
                    // Pre-fill bank name if a bank was selected
                    if (_selectedBank != null) {
                      _bankNameController.text = _selectedBank!.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Bank/Wallet Selection for Nepal
              if (_showBankSelection) ...[
                GestureDetector(
                  onTap: () {
                    _showSelectionDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        if (_selectedBank != null) ...[
                          _getDummyBankLogo(_selectedBank!),
                          const SizedBox(width: 12),
                          Text(
                            _selectedBank!.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ] else ...[
                          Text(
                            _selectedType == AccountType.bank 
                                ? 'Select a bank' 
                                : 'Select a digital wallet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Account Name - only show for non-bank accounts and for bank accounts where bank is selected
              if (_selectedType != AccountType.bank)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _getAccountNameLabel(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              
              // Show spacing between fields only if account name is displayed
              if (_selectedType != AccountType.bank)
                const SizedBox(height: 16),
              
              // Bank Details (only for bank accounts)
              if (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet) ...[
                // Only show bank/wallet name field if no bank/wallet selected
                if (_selectedBank == null) 
                  TextFormField(
                    controller: _bankNameController,
                    decoration: InputDecoration(
                      labelText: _selectedType == AccountType.bank ? 'Bank Name' : 'Wallet Name',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _selectedType == AccountType.bank 
                            ? 'Please enter bank name' 
                            : 'Please enter wallet name';
                      }
                      return null;
                    },
                  ),
                if (_selectedBank == null)
                  const SizedBox(height: 16),
                TextFormField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    labelText: _selectedType == AccountType.bank 
                        ? 'Account Holder Name'
                        : 'Wallet Owner Name',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _selectedType == AccountType.bank
                          ? 'Please enter account holder name'
                          : 'Please enter wallet owner name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: _selectedType == AccountType.bank
                        ? 'Account Number (Optional)'
                        : 'Mobile Number (Optional)',
                    border: const OutlineInputBorder(),
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
              _buildColorSelection(),
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
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorSelection() {
    // If bank is selected, use its color as initial color but allow changing
    if (_selectedBank != null && _selectedColor == _selectedBank!.backgroundColor) {
      _selectedColor = _selectedBank!.backgroundColor;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Color:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
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
                    color: _selectedColor == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  void _showSelectionDialog() {
    String searchQuery = '';
    List<Bank> filteredItems = _getItemsToDisplay();
    List<Bank> popularItems = filteredItems.where((bank) => bank.isPopular).toList();
    List<Bank> otherItems = filteredItems.where((bank) => !bank.isPopular).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void filterItems(String query) {
              setState(() {
                searchQuery = query.toLowerCase();
                if (searchQuery.isEmpty) {
                  // If no search, show original lists
                  filteredItems = _getItemsToDisplay();
                  popularItems = filteredItems.where((bank) => bank.isPopular).toList();
                  otherItems = filteredItems.where((bank) => !bank.isPopular).toList();
                } else {
                  // Filter based on search
                  filteredItems = _getItemsToDisplay()
                      .where((bank) => bank.name.toLowerCase().contains(searchQuery))
                      .toList();
                  popularItems = filteredItems.where((bank) => bank.isPopular).toList();
                  otherItems = filteredItems.where((bank) => !bank.isPopular).toList();
                }
              });
            }
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _selectedType == AccountType.bank ? 'Select a Bank' : 'Select a Digital Wallet',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: filterItems,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (popularItems.isNotEmpty && searchQuery.isEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                              child: Text(
                                'Popular',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            ...popularItems.map((bank) => _buildBankListTile(bank, context)),
                            const Divider(),
                            if (otherItems.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                                child: Text(
                                  'Others',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ...otherItems.map((bank) => _buildBankListTile(bank, context)),
                          ] else ...[
                            // When searching or no popular items, show all filtered items
                            ...filteredItems.map((bank) => _buildBankListTile(bank, context)),
                            if (filteredItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No results found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildBankListTile(Bank bank, BuildContext context) {
    return ListTile(
      leading: _getDummyBankLogo(bank),
      title: Text(
        bank.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        setState(() {
          // Store current color to check if user has customized it
          final Color previousColor = _selectedColor;
          final bool wasCustomColor = _selectedBank != null && _selectedColor != _selectedBank!.backgroundColor;
          
          _selectedBank = bank;
          
          // Only update color if user hasn't customized it already
          if (!wasCustomColor) {
            _selectedColor = bank.backgroundColor;
          }
          
          // Pre-fill bank name
          if (_selectedType == AccountType.bank) {
            _bankNameController.text = bank.name;
          } else {
            _nameController.text = bank.name;
          }
        });
        Navigator.pop(context);
      },
      trailing: bank.isPopular 
          ? const Icon(
              Icons.star,
              color: Colors.amber,
              size: 18,
            )
          : null,
    );
  }
  
  // Return the appropriate list based on account type
  List<Bank> _getItemsToDisplay() {
    if (_selectedType == AccountType.bank) {
      return _nepaliBanks;
    } else if (_selectedType == AccountType.digitalWallet) {
      return _nepaliWallets;
    }
    return [];
  }
  
  // Get the appropriate label for the account name field
  String _getAccountNameLabel() {
    if (_selectedType == AccountType.bank) {
      return 'Account Name (e.g., Salary Account)';
    } else if (_selectedType == AccountType.digitalWallet) {
      return 'Wallet Name';
    } else if (_selectedType == AccountType.cash) {
      return 'Cash Account Name';
    } else {
      return 'Account Name';
    }
  }
  
  // Creates a bank logo, either from internet URL or a fallback
  Widget _getDummyBankLogo(Bank bank) {
    print('Attempting to load logo for bank: ${bank.name}');
    print('Logo path: ${bank.logoPath}');
    
    // Try to use local asset first
    if (bank.logoPath.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        radius: 16,
        child: ClipOval(
          child: Image.asset(
            bank.logoPath,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Failed to load asset: ${bank.logoPath}, error: $error');
              // If asset fails, use icon or fallback
              if (bank.icon != null) {
                return Icon(
                  bank.icon,
                  color: bank.backgroundColor,
                  size: 16,
                );
              }
              return _getBankFallbackLogo(bank);
            },
          ),
        ),
      );
    }
    
    // Use Material icon if available
    if (bank.icon != null) {
      return CircleAvatar(
        backgroundColor: bank.backgroundColor,
        radius: 16,
        child: Icon(
          bank.icon,
          color: Colors.white,
          size: 16,
        ),
      );
    }
    
    // Use fallback as last resort
    return _getBankFallbackLogo(bank);
  }
  
  // Fallback logo with first letter of bank name
  Widget _getBankFallbackLogo(Bank bank) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 16,
      child: ClipOval(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: 28,
          height: 28,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  
  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final IconData icon = _selectedType == AccountType.bank 
          ? Icons.account_balance 
          : _selectedType == AccountType.cash 
              ? Icons.money 
              : _selectedType == AccountType.digitalWallet 
                  ? Icons.account_balance_wallet 
                  : Icons.credit_card;
      
      // For bank accounts, store the bank logo path if a bank is selected
      final String? bankLogoPath = (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet)
          ? (_selectedBank != null 
              ? _selectedBank!.logoPath 
              : 'assets/images/app_icon.png') // Use app icon for custom banks/wallets
          : null;
      
      final account = AccountModel(
        id: const Uuid().v4(),
        name: (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet)
            ? (_selectedBank?.name ?? _bankNameController.text) // For banks/wallets, use selected name directly
            : _nameController.text,
        type: _selectedType,
        currencyCode: _selectedCurrency.name,
        balance: 0,
        colorValue: _selectedColor.value,
        icon: icon,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        bankName: (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet) 
            ? (_selectedBank?.name ?? _bankNameController.text) 
            : null,
        accountNumber: (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet) && _accountNumberController.text.isNotEmpty 
            ? _accountNumberController.text 
            : null,
        accountHolderName: (_selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet) 
            ? _accountHolderController.text 
            : null,
        // Add custom field for bank logo path
        bankLogoPath: bankLogoPath,
      );
      
      Navigator.pop(context, account);
    }
  }
} 