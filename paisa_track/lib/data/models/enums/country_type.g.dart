// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CountryTypeAdapter extends TypeAdapter<CountryType> {
  @override
  final int typeId = 7;

  @override
  CountryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CountryType.unitedStates;
      case 1:
        return CountryType.unitedKingdom;
      case 2:
        return CountryType.canada;
      case 3:
        return CountryType.australia;
      case 4:
        return CountryType.germany;
      case 5:
        return CountryType.france;
      case 6:
        return CountryType.japan;
      case 7:
        return CountryType.india;
      case 8:
        return CountryType.china;
      case 9:
        return CountryType.russia;
      case 10:
        return CountryType.brazil;
      case 11:
        return CountryType.southAfrica;
      case 12:
        return CountryType.mexico;
      case 13:
        return CountryType.italy;
      case 14:
        return CountryType.spain;
      case 15:
        return CountryType.southKorea;
      case 16:
        return CountryType.netherlands;
      case 17:
        return CountryType.switzerland;
      case 18:
        return CountryType.sweden;
      case 19:
        return CountryType.norway;
      case 20:
        return CountryType.newZealand;
      case 21:
        return CountryType.uae;
      case 22:
        return CountryType.singapore;
      case 23:
        return CountryType.ireland;
      case 24:
        return CountryType.poland;
      case 25:
        return CountryType.austria;
      case 26:
        return CountryType.belgium;
      case 27:
        return CountryType.denmark;
      case 28:
        return CountryType.finland;
      case 29:
        return CountryType.greece;
      case 30:
        return CountryType.portugal;
      case 31:
        return CountryType.nepal;
      default:
        return CountryType.unitedStates;
    }
  }

  @override
  void write(BinaryWriter writer, CountryType obj) {
    switch (obj) {
      case CountryType.unitedStates:
        writer.writeByte(0);
        break;
      case CountryType.unitedKingdom:
        writer.writeByte(1);
        break;
      case CountryType.canada:
        writer.writeByte(2);
        break;
      case CountryType.australia:
        writer.writeByte(3);
        break;
      case CountryType.germany:
        writer.writeByte(4);
        break;
      case CountryType.france:
        writer.writeByte(5);
        break;
      case CountryType.japan:
        writer.writeByte(6);
        break;
      case CountryType.india:
        writer.writeByte(7);
        break;
      case CountryType.china:
        writer.writeByte(8);
        break;
      case CountryType.russia:
        writer.writeByte(9);
        break;
      case CountryType.brazil:
        writer.writeByte(10);
        break;
      case CountryType.southAfrica:
        writer.writeByte(11);
        break;
      case CountryType.mexico:
        writer.writeByte(12);
        break;
      case CountryType.italy:
        writer.writeByte(13);
        break;
      case CountryType.spain:
        writer.writeByte(14);
        break;
      case CountryType.southKorea:
        writer.writeByte(15);
        break;
      case CountryType.netherlands:
        writer.writeByte(16);
        break;
      case CountryType.switzerland:
        writer.writeByte(17);
        break;
      case CountryType.sweden:
        writer.writeByte(18);
        break;
      case CountryType.norway:
        writer.writeByte(19);
        break;
      case CountryType.newZealand:
        writer.writeByte(20);
        break;
      case CountryType.uae:
        writer.writeByte(21);
        break;
      case CountryType.singapore:
        writer.writeByte(22);
        break;
      case CountryType.ireland:
        writer.writeByte(23);
        break;
      case CountryType.poland:
        writer.writeByte(24);
        break;
      case CountryType.austria:
        writer.writeByte(25);
        break;
      case CountryType.belgium:
        writer.writeByte(26);
        break;
      case CountryType.denmark:
        writer.writeByte(27);
        break;
      case CountryType.finland:
        writer.writeByte(28);
        break;
      case CountryType.greece:
        writer.writeByte(29);
        break;
      case CountryType.portugal:
        writer.writeByte(30);
        break;
      case CountryType.nepal:
        writer.writeByte(31);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
