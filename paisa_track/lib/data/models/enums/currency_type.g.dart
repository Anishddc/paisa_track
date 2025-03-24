// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CurrencyTypeAdapter extends TypeAdapter<CurrencyType> {
  @override
  final int typeId = 5;

  @override
  CurrencyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CurrencyType.usd;
      case 1:
        return CurrencyType.eur;
      case 2:
        return CurrencyType.gbp;
      case 3:
        return CurrencyType.inr;
      case 4:
        return CurrencyType.jpy;
      case 5:
        return CurrencyType.cad;
      case 6:
        return CurrencyType.aud;
      case 7:
        return CurrencyType.cny;
      case 8:
        return CurrencyType.sgd;
      case 9:
        return CurrencyType.myr;
      case 10:
        return CurrencyType.npr;
      case 11:
        return CurrencyType.brl;
      case 12:
        return CurrencyType.rub;
      case 13:
        return CurrencyType.krw;
      case 14:
        return CurrencyType.thb;
      case 15:
        return CurrencyType.idr;
      case 16:
        return CurrencyType.php;
      case 17:
        return CurrencyType.vnd;
      default:
        return CurrencyType.usd;
    }
  }

  @override
  void write(BinaryWriter writer, CurrencyType obj) {
    switch (obj) {
      case CurrencyType.usd:
        writer.writeByte(0);
        break;
      case CurrencyType.eur:
        writer.writeByte(1);
        break;
      case CurrencyType.gbp:
        writer.writeByte(2);
        break;
      case CurrencyType.inr:
        writer.writeByte(3);
        break;
      case CurrencyType.jpy:
        writer.writeByte(4);
        break;
      case CurrencyType.cad:
        writer.writeByte(5);
        break;
      case CurrencyType.aud:
        writer.writeByte(6);
        break;
      case CurrencyType.cny:
        writer.writeByte(7);
        break;
      case CurrencyType.sgd:
        writer.writeByte(8);
        break;
      case CurrencyType.myr:
        writer.writeByte(9);
        break;
      case CurrencyType.npr:
        writer.writeByte(10);
        break;
      case CurrencyType.brl:
        writer.writeByte(11);
        break;
      case CurrencyType.rub:
        writer.writeByte(12);
        break;
      case CurrencyType.krw:
        writer.writeByte(13);
        break;
      case CurrencyType.thb:
        writer.writeByte(14);
        break;
      case CurrencyType.idr:
        writer.writeByte(15);
        break;
      case CurrencyType.php:
        writer.writeByte(16);
        break;
      case CurrencyType.vnd:
        writer.writeByte(17);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
