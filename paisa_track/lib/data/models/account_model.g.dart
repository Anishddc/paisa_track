// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 10;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Safely handle the type field (field 3) which might be AccountType or String
    Object typeValue = fields[3];
    String typeString;
    
    if (typeValue is String) {
      // If it's already a string, use it directly
      typeString = typeValue;
    } else if (typeValue is AccountType) {
      // If it's AccountType enum, convert to string
      typeString = typeValue.toString();
    } else {
      // Default to cash if we can't determine the type
      typeString = 'AccountType.cash';
    }
    
    return AccountModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      balance: fields[2] as double,
      type: typeString,
      currency: fields[4] as CurrencyType?,
      description: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      isArchived: fields[8] as bool,
      bankName: fields[9] as String?,
      accountNumber: fields[10] as String?,
      colorValue: fields[11] as int,
      accountHolderName: fields[12] as String?,
      iconData: fields[13] as int?,
      bankLogoPath: fields[14] as String?,
      initialBalance: fields[15] as double,
      userName: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj._typeString) // Make sure we write the string representation
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.bankName)
      ..writeByte(10)
      ..write(obj.accountNumber)
      ..writeByte(11)
      ..write(obj.colorValue)
      ..writeByte(12)
      ..write(obj.accountHolderName)
      ..writeByte(13)
      ..write(obj.iconData)
      ..writeByte(14)
      ..write(obj.bankLogoPath)
      ..writeByte(15)
      ..write(obj.initialBalance)
      ..writeByte(16)
      ..write(obj.userName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
