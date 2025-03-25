import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;
  final bool isDragging;
  final bool isLastItem;
  final bool showActions;
  
  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
    this.isDragging = false,
    this.isLastItem = false,
    this.showActions = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final currencySymbol = account.currency.symbol;
    
    return Card(
      elevation: isDragging ? 8 : 2,
      margin: EdgeInsets.only(
        bottom: isLastItem ? 0 : 12,
        left: isSelected ? 8 : 0,
        right: isSelected ? 8 : 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: ColorConstants.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Header
              Row(
                children: [
                  // Account Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(account.colorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                      ? ClipOval(
                          child: Image.asset(
                            account.bankLogoPath!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading bank logo: ${account.bankLogoPath}, error: $error');
                              // Fallback to default icon if image fails to load
                              return Icon(
                                account.icon,
                                color: Color(account.colorValue),
                                size: 20,
                              );
                            },
                          ),
                        )
                      : Icon(
                          account.icon,
                          color: Color(account.colorValue),
                          size: 20,
                        ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Account Name and Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          account.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Balance
                  Text(
                    '$currencySymbol${account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              if (showActions) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: ColorConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: ColorConstants.errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 