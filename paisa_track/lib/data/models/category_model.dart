import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:uuid/uuid.dart';

part 'category_model.g.dart';

@HiveType(typeId: AppConstants.categoryModelId)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String iconName;
  
  @HiveField(3)
  final int colorValue;
  
  @HiveField(4)
  final bool isIncome;
  
  @HiveField(5)
  final String? description;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime updatedAt;
  
  @HiveField(8)
  final bool isArchived;
  
  @HiveField(9)
  final bool isTransfer;
  
  @HiveField(10)
  final double monthlyBudget;
  
  CategoryModel({
    String? id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.isIncome,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
    this.isTransfer = false,
    this.monthlyBudget = 0.0,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  // Backward compatibility getters
  TransactionType get type => isTransfer ? TransactionType.transfer :
                            isIncome ? TransactionType.income : TransactionType.expense;
  
  Color get color => Color(colorValue);
  
  IconData get icon {
    // Map icon names to IconData
    switch (iconName) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_cart;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'housing':
        return Icons.home;
      case 'utilities':
        return Icons.electrical_services;
      case 'insurance':
        return Icons.security;
      case 'gifts':
        return Icons.card_giftcard;
      case 'other':
        return Icons.more_horiz;
      case 'work':
        return Icons.work;
      case 'trending_up':
        return Icons.trending_up;
      case 'swap_horiz':
        return Icons.swap_horiz;
      default:
        return Icons.category;
    }
  }
  
  CategoryModel copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    bool? isIncome,
    String? description,
    bool? isArchived,
    bool? isTransfer,
    double? monthlyBudget,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isIncome: isIncome ?? this.isIncome,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isArchived: isArchived ?? this.isArchived,
      isTransfer: isTransfer ?? this.isTransfer,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'isIncome': isIncome,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'isTransfer': isTransfer,
      'monthlyBudget': monthlyBudget,
    };
  }
  
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      iconName: json['iconName'],
      colorValue: json['colorValue'],
      isIncome: json['isIncome'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isArchived: json['isArchived'] ?? false,
      isTransfer: json['isTransfer'] ?? false,
      monthlyBudget: json['monthlyBudget']?.toDouble() ?? 0.0,
    );
  }
  
  static List<CategoryModel> defaultExpenseCategories() {
    return [
      CategoryModel(
        name: 'Food & Dining',
        iconName: 'food',
        colorValue: ColorConstants.categoryColors[0].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Transportation',
        iconName: 'transport',
        colorValue: ColorConstants.categoryColors[1].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Shopping',
        iconName: 'shopping',
        colorValue: ColorConstants.categoryColors[2].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Bills & Utilities',
        iconName: 'bills',
        colorValue: ColorConstants.categoryColors[3].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Entertainment',
        iconName: 'entertainment',
        colorValue: ColorConstants.categoryColors[4].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Healthcare',
        iconName: 'health',
        colorValue: ColorConstants.categoryColors[5].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Education',
        iconName: 'education',
        colorValue: ColorConstants.categoryColors[6].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Housing',
        iconName: 'housing',
        colorValue: ColorConstants.categoryColors[7].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Insurance',
        iconName: 'insurance',
        colorValue: ColorConstants.categoryColors[8].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Gifts & Donations',
        iconName: 'gifts',
        colorValue: ColorConstants.categoryColors[9].value,
        isIncome: false,
      ),
      CategoryModel(
        name: 'Other Expenses',
        iconName: 'other',
        colorValue: ColorConstants.categoryColors[10].value,
        isIncome: false,
      ),
    ];
  }
  
  static List<CategoryModel> defaultIncomeCategories() {
    return [
      CategoryModel(
        name: 'Salary',
        iconName: 'work',
        colorValue: ColorConstants.categoryColors[11].value,
        isIncome: true,
      ),
      CategoryModel(
        name: 'Freelance',
        iconName: 'work',
        colorValue: ColorConstants.categoryColors[12].value,
        isIncome: true,
      ),
      CategoryModel(
        name: 'Investments',
        iconName: 'trending_up',
        colorValue: ColorConstants.categoryColors[13].value,
        isIncome: true,
      ),
      CategoryModel(
        name: 'Gifts',
        iconName: 'gifts',
        colorValue: ColorConstants.categoryColors[14].value,
        isIncome: true,
      ),
      CategoryModel(
        name: 'Other Income',
        iconName: 'other',
        colorValue: ColorConstants.categoryColors[15].value,
        isIncome: true,
      ),
    ];
  }

  static List<CategoryModel> defaultTransferCategories() {
    return [
      CategoryModel(
        name: 'Transfer',
        iconName: 'swap_horiz',
        colorValue: ColorConstants.categoryColors[5].value,
        isIncome: false,
        isTransfer: true,
        description: 'Transfer between accounts',
      ),
    ];
  }
} 