// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 1;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.bank;
      case 1:
        return AccountType.cash;
      case 2:
        return AccountType.digitalWallet;
      case 3:
        return AccountType.card;
      case 4:
        return AccountType.wallet;
      case 5:
        return AccountType.creditCard;
      case 6:
        return AccountType.investment;
      case 7:
        return AccountType.loan;
      case 8:
        return AccountType.other;
      default:
        return AccountType.bank;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.bank:
        writer.writeByte(0);
        break;
      case AccountType.cash:
        writer.writeByte(1);
        break;
      case AccountType.digitalWallet:
        writer.writeByte(2);
        break;
      case AccountType.card:
        writer.writeByte(3);
        break;
      case AccountType.wallet:
        writer.writeByte(4);
        break;
      case AccountType.creditCard:
        writer.writeByte(5);
        break;
      case AccountType.investment:
        writer.writeByte(6);
        break;
      case AccountType.loan:
        writer.writeByte(7);
        break;
      case AccountType.other:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
