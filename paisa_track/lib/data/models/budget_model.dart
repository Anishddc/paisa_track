import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';

part 'budget_model.g.dart';

@HiveType(typeId: AppConstants.budgetTypeId)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  double amount;
  
  @HiveField(3)
  String currencyCode;
  
  @HiveField(4)
  List<String> categoryIds;
  
  @HiveField(5)
  DateTime startDate;
  
  @HiveField(6)
  DateTime endDate;
  
  @HiveField(7)
  int colorValue;
  
  @HiveField(8)
  String? iconName;
  
  @HiveField(9)
  String? notes;
  
  @HiveField(10)
  bool isArchived;
  
  @HiveField(11)
  DateTime createdAt;
  
  @HiveField(12)
  DateTime? lastUpdated;

  BudgetModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.categoryIds,
    required this.startDate,
    required this.endDate,
    required this.colorValue,
    this.iconName,
    this.notes,
    this.isArchived = false,
    required this.createdAt,
    this.lastUpdated,
  });
  
  Color get color => Color(colorValue);
  
  IconData get icon {
    // Default icon if none is specified
    return Icons.account_balance_wallet;
  }
  
  // Check if a date falls within the budget period
  bool isDateInBudgetPeriod(DateTime date) {
    return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
           (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
  }
  
  // Create a copy of the budget with some properties changed
  BudgetModel copyWith({
    String? name,
    double? amount,
    String? currencyCode,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    int? colorValue,
    String? iconName,
    String? notes,
    bool? isArchived,
  }) {
    return BudgetModel(
      id: this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryIds: categoryIds ?? this.categoryIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: this.createdAt,
      lastUpdated: DateTime.now(),
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryIds': categoryIds,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'colorValue': colorValue,
      'iconName': iconName,
      'notes': notes,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
  
  // Create from JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      currencyCode: json['currencyCode'],
      categoryIds: (json['categoryIds'] as List).cast<String>(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      colorValue: json['colorValue'],
      iconName: json['iconName'],
      notes: json['notes'],
      isArchived: json['isArchived'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
    );
  }
} 