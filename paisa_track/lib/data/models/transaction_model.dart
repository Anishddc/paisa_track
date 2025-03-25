import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: AppConstants.transactionModelId)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String description;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final TransactionType type;
  
  @HiveField(4)
  final String categoryId;
  
  @HiveField(5)
  final String accountId;
  
  @HiveField(6)
  final DateTime date;
  
  @HiveField(7)
  final String? notes;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime updatedAt;
  
  @HiveField(10)
  final bool isArchived;
  
  @HiveField(11)
  final String? destinationAccountId;
  
  @HiveField(15)
  final String? recurranceId;
  
  @HiveField(16)
  bool isProcessed;
  
  TransactionModel({
    String? id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
    this.destinationAccountId,
    String? toAccountId, // For backward compatibility
    this.recurranceId,
    this.isProcessed = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  // Backward compatibility getter
  String? get toAccountId => destinationAccountId;
  
  // Check if transaction is a transfer
  bool get isTransfer => type == TransactionType.transfer && destinationAccountId != null;
  
  // Check if transaction is income
  bool get isIncome => type == TransactionType.income;
  
  // Check if transaction is expense
  bool get isExpense => type == TransactionType.expense;
  
  TransactionModel copyWith({
    String? description,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? notes,
    bool? isArchived,
    String? destinationAccountId,
    String? toAccountId, // For backward compatibility
    String? recurranceId,
    bool? isProcessed,
  }) {
    return TransactionModel(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isArchived: isArchived ?? this.isArchived,
      destinationAccountId: toAccountId ?? destinationAccountId ?? this.destinationAccountId,
      recurranceId: recurranceId ?? this.recurranceId,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.toString(),
      'categoryId': categoryId,
      'accountId': accountId,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'destinationAccountId': destinationAccountId,
      'recurranceId': recurranceId,
      'isProcessed': isProcessed,
    };
  }
  
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isArchived: json['isArchived'] ?? false,
      destinationAccountId: json['destinationAccountId'] ?? json['toAccountId'],
      recurranceId: json['recurranceId'],
      isProcessed: json['isProcessed'] ?? false,
    );
  }

  Future<void> save() async {
    try {
      // Get the box and save this transaction
      final box = await Hive.openBox<TransactionModel>('transactions');
      await box.put(id, this);
      
      print('Transaction saved: $id (${description ?? "no description"})');
      
      // Note: This doesn't automatically notify listeners
      // The repository's stream controller needs to be triggered separately
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }
} 