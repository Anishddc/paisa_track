// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 0;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      defaultCurrencyCode: fields[2] as String,
      themeMode: fields[4] as String,
      profileImagePath: fields[3] as String?,
      notificationsEnabled: fields[5] as bool,
      weeklyGoalPercentage: fields[6] as int,
      isBiometricEnabled: fields[7] as bool?,
      createdAt: fields[8] as DateTime,
      locale: fields[9] as String?,
      lastUpdated: fields[10] as DateTime?,
      country: fields[11] as CountryType?,
      useLargeFab: fields[12] as bool,
      dashboardLayout: fields[13] as String,
      appColor: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.defaultCurrencyCode)
      ..writeByte(3)
      ..write(obj.profileImagePath)
      ..writeByte(4)
      ..write(obj.themeMode)
      ..writeByte(5)
      ..write(obj.notificationsEnabled)
      ..writeByte(6)
      ..write(obj.weeklyGoalPercentage)
      ..writeByte(7)
      ..write(obj.isBiometricEnabled)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.locale)
      ..writeByte(10)
      ..write(obj.lastUpdated)
      ..writeByte(11)
      ..write(obj.country)
      ..writeByte(12)
      ..write(obj.useLargeFab)
      ..writeByte(13)
      ..write(obj.dashboardLayout)
      ..writeByte(14)
      ..write(obj.appColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
