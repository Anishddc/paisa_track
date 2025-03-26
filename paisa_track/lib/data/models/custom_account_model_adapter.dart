import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';

/// A custom Hive adapter for AccountModel that properly handles the type field
class CustomAccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = AppConstants.accountModelId;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Debug the type fields
    print('Reading account from Hive - typeString: ${fields[3]}, typeIndex: ${fields[17]}');
    
    // Important: Pass both typeString and typeIndex to the constructor
    return AccountModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      balance: fields[2] as double,
      // Pass the type string from field 3 if it exists
      type: fields.containsKey(3) ? fields[3] as String? : null,
      currency: fields.containsKey(4) ? fields[4] as CurrencyType? : null,
      description: fields.containsKey(5) ? fields[5] as String? : null,
      createdAt: fields.containsKey(6) ? fields[6] as DateTime? : null,
      updatedAt: fields.containsKey(7) ? fields[7] as DateTime? : null,
      isArchived: fields.containsKey(8) ? fields[8] as bool : false,
      bankName: fields.containsKey(9) ? fields[9] as String? : null,
      accountNumber: fields.containsKey(10) ? fields[10] as String? : null,
      colorValue: fields.containsKey(11) ? fields[11] as int : 0xFF0099FF,
      accountHolderName: fields.containsKey(12) ? fields[12] as String? : null,
      iconData: fields.containsKey(13) ? fields[13] as int? : null,
      bankLogoPath: fields.containsKey(14) ? fields[14] as String? : null,
      initialBalance: fields.containsKey(15) ? fields[15] as double? : null,
      userName: fields.containsKey(16) ? fields[16] as String? : null,
      // Directly pass the type index from field 17 if it exists
      typeIndex: fields.containsKey(17) ? fields[17] as int : null,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    // Debug the type being saved
    print('Writing account to Hive - typeString: ${obj.typeString}, typeIndex: ${obj.typeIndex}');
    
    writer
      ..writeByte(18) // Total number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.typeString) // Use the getter instead of direct field access
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
      ..write(obj.userName)
      ..writeByte(17)
      ..write(obj.typeIndex); // Use the getter instead of direct field access
  }
} 