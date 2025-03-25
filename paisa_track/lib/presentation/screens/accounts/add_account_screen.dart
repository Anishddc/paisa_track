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

class AddAccountScreen extends StatefulWidget {
  final String defaultCurrencyCode;
  final String? userName;
  
  const AddAccountScreen({
    super.key,
    this.defaultCurrencyCode = 'USD',
    this.userName,
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  AccountType _selectedType = AccountType.wallet;
  CurrencyType _selectedCurrency = CurrencyType.usd;
  Color _selectedColor = ColorConstants.primaryColor;
  IconData _selectedIcon = Icons.account_balance_wallet;
  double _initialBalance = 0.0;
  Bank? _selectedBank;
  bool _showBankSelection = false;
  bool _isLoading = false;
  
  List<Bank> _nepaliBanks = [];
  List<Bank> _nepaliWallets = [];
  
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];
  
  final List<IconData> _iconOptions = [
    Icons.account_balance_wallet,
    Icons.account_balance,
    Icons.credit_card,
    Icons.savings,
    Icons.attach_money,
    Icons.payment,
    Icons.currency_exchange,
    Icons.money,
    Icons.shopping_bag,
    Icons.card_giftcard,
  ];

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
  
  String _getAccountNameLabel() {
    switch (_selectedType) {
      case AccountType.wallet:
        return 'Wallet Name';
      case AccountType.bank:
        return 'Account Name';
      case AccountType.creditCard:
        return 'Card Name';
      case AccountType.investment:
        return 'Investment Account Name';
      case AccountType.loan:
        return 'Loan Name';
      case AccountType.digitalWallet:
        return 'Digital Wallet Name';
      case AccountType.cash:
        return 'Cash Account Name';
      case AccountType.card:
        return 'Card Name';
      case AccountType.other:
        return 'Account Name';
    }
  }
  
  Widget _getDummyBankLogo(Bank bank) {
    print('Attempting to load logo for bank: ${bank.name}');
    print('Logo path: ${bank.logoPath}');
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bank.backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: bank.logoPath.isNotEmpty
        ? ClipOval(
            child: Image.asset(
              bank.logoPath,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to default icon if image fails to load
                print('Failed to load asset: ${bank.logoPath}, error: $error');
                return Icon(
                  bank.icon ?? Icons.account_balance,
                  color: bank.backgroundColor,
                  size: 20,
                );
              },
            ),
          )
        : Icon(
            bank.icon ?? Icons.account_balance,
            color: bank.backgroundColor,
            size: 20,
          ),
    );
  }
  
  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final List<Bank> options = _selectedType == AccountType.bank
            ? _nepaliBanks
            : _nepaliWallets;
        
        return AlertDialog(
          title: Text(
            _selectedType == AccountType.bank
                ? 'Select Bank'
                : 'Select Digital Wallet'
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final bank = options[index];
                return ListTile(
                  leading: _getDummyBankLogo(bank),
                  title: Text(bank.name),
                  onTap: () {
                    setState(() {
                      _selectedBank = bank;
                      _bankNameController.text = bank.name;
                      if (_nameController.text.isEmpty) {
                        _nameController.text = '${bank.name} Account';
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String accountName = _nameController.text.isNotEmpty
          ? _nameController.text
          : (_selectedBank != null
              ? '${_selectedBank!.name} Account'
              : _bankNameController.text);

      // Create account model
      final account = AccountModel(
        id: const Uuid().v4(),
        name: accountName,
        type: _selectedType,
        balance: _initialBalance,
        currency: _selectedCurrency,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        bankName: _selectedType == AccountType.bank || _selectedType == AccountType.digitalWallet
            ? (_selectedBank != null ? _selectedBank!.name : _bankNameController.text)
            : null,
        accountNumber: _accountNumberController.text.isEmpty 
            ? null 
            : _accountNumberController.text,
        accountHolderName: _accountHolderController.text.isEmpty 
            ? null 
            : _accountHolderController.text,
        isArchived: false,
        colorValue: _selectedColor.value,
        iconData: _selectedIcon.codePoint,
        initialBalance: _initialBalance,
        userName: widget.userName,
        bankLogoPath: _selectedBank?.logoPath,
      );

      try {
        // Add account to database
        final accountRepository = AccountRepository();
        await accountRepository.addAccount(account);
        
        if (mounted) {
          // Return the account to the caller
          Navigator.pop(context, account);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding account: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add Account',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Type
            _buildSectionTitle('Account Type'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: AccountType.values.length,
                    itemBuilder: (context, index) {
                      final type = AccountType.values[index];
                      final isSelected = _selectedType == type;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            _showBankSelection = (type == AccountType.bank || type == AccountType.digitalWallet);
                            _selectedBank = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type.icon,
                                color: isSelected ? ColorConstants.primaryColor : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade800,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bank/Wallet Selection for Nepal
            if (_showBankSelection) ...[
              _buildSectionTitle(_selectedType == AccountType.bank ? 'Select Bank' : 'Select Digital Wallet'),
              const SizedBox(height: 12),
              
              GestureDetector(
                onTap: () {
                  _showSelectionDialog();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_selectedBank != null) ...[
                        _getDummyBankLogo(_selectedBank!),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedBank!.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            _selectedType == AccountType.bank 
                                ? 'Tap to select a bank' 
                                : 'Tap to select a digital wallet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Account Name
            _buildTextField(
              controller: _nameController,
              label: _getAccountNameLabel(),
              icon: Icons.description_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for your account';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Initial Balance
            _buildSectionTitle('Initial Balance'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _selectedCurrency.symbol,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                      ),
                      style: const TextStyle(fontSize: 24),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          _initialBalance = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Currency Selection
            _buildSectionTitle('Currency'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CurrencyType>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  items: CurrencyType.values.map((currency) {
                    return DropdownMenuItem<CurrencyType>(
                      value: currency,
                      child: Row(
                        children: [
                          Text(
                            currency.symbol,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${currency.name.toUpperCase()} - ${currency.displayName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Color and Icon Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Color'),
                      const SizedBox(height: 12),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colorOptions.length,
                          itemBuilder: (context, index) {
                            final color = _colorOptions[index];
                            final isSelected = _selectedColor == color;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Icon'),
                      const SizedBox(height: 12),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _iconOptions.length,
                          itemBuilder: (context, index) {
                            final icon = _iconOptions[index];
                            final isSelected = _selectedIcon == icon;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _selectedColor : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _selectedColor.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Additional Info (optional fields)
            ExpansionTile(
              title: const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                const SizedBox(height: 16),
                // Account Number
                _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number (Optional)',
                  icon: Icons.confirmation_number_outlined,
                ),
                const SizedBox(height: 16),
                // Account Holder
                _buildTextField(
                  controller: _accountHolderController,
                  label: 'Account Holder (Optional)',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  icon: Icons.note_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: ColorConstants.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
} 