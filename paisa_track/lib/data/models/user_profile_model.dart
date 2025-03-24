import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/data/models/enums/country_type.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: AppConstants.userProfileTypeId)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String? id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String defaultCurrencyCode;
  
  @HiveField(3)
  String? profileImagePath;
  
  @HiveField(4)
  String themeMode;
  
  @HiveField(5)
  bool notificationsEnabled;
  
  @HiveField(6)
  int weeklyGoalPercentage;
  
  @HiveField(7)
  bool? isBiometricEnabled;
  
  @HiveField(8)
  DateTime createdAt;
  
  @HiveField(9)
  String? locale;
  
  @HiveField(10)
  DateTime? lastUpdated;
  
  @HiveField(11)
  CountryType? country;
  
  @HiveField(12)
  bool useLargeFab;
  
  @HiveField(13)
  String dashboardLayout;
  
  @HiveField(14)
  int? appColor;

  UserProfileModel({
    this.id,
    required this.name,
    this.defaultCurrencyCode = 'INR',
    this.themeMode = 'system',
    this.profileImagePath,
    this.notificationsEnabled = true,
    this.weeklyGoalPercentage = 0,
    this.isBiometricEnabled,
    required this.createdAt,
    this.locale,
    this.lastUpdated,
    this.country,
    this.useLargeFab = true,
    this.dashboardLayout = 'default',
    this.appColor,
  });
  
  // Create a copy of this UserProfileModel with possible new values
  UserProfileModel copyWith({
    String? id,
    String? name,
    String? profileImagePath,
    String? defaultCurrencyCode,
    DateTime? createdAt,
    String? locale,
    String? themeMode,
    bool? isBiometricEnabled,
    DateTime? lastUpdated,
    CountryType? country,
    bool? notificationsEnabled,
    int? weeklyGoalPercentage,
    bool? useLargeFab,
    String? dashboardLayout,
    int? appColor,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
      createdAt: createdAt ?? this.createdAt,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated ?? DateTime.now(),
      country: country ?? this.country,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      weeklyGoalPercentage: weeklyGoalPercentage ?? this.weeklyGoalPercentage,
      useLargeFab: useLargeFab ?? this.useLargeFab,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      appColor: appColor ?? this.appColor,
    );
  }
  
  // Create a default UserProfileModel
  static UserProfileModel createDefault() {
    return UserProfileModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'User',
      profileImagePath: null,
      defaultCurrencyCode: 'USD',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      locale: 'en_US',
      themeMode: 'system',
      isBiometricEnabled: false,
      country: CountryType.unitedStates,
      notificationsEnabled: true,
      weeklyGoalPercentage: 0,
      useLargeFab: true,
      dashboardLayout: 'default',
      appColor: null,
    );
  }
  
  // Create UserProfileModel from JSON map
  static UserProfileModel fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      name: json['name'],
      defaultCurrencyCode: json['defaultCurrencyCode'],
      profileImagePath: json['profileImagePath'],
      themeMode: json['themeMode'],
      notificationsEnabled: json['notificationsEnabled'],
      weeklyGoalPercentage: json['weeklyGoalPercentage'],
      isBiometricEnabled: json['isBiometricEnabled'],
      createdAt: DateTime.parse(json['createdAt']),
      locale: json['locale'],
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
      country: json['country'] != null ? CountryType.values[json['country']] : null,
      useLargeFab: json['useLargeFab'] ?? true,
      dashboardLayout: json['dashboardLayout'] ?? 'default',
      appColor: json['appColor'],
    );
  }
  
  // Convert UserProfileModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'defaultCurrencyCode': defaultCurrencyCode,
      'profileImagePath': profileImagePath,
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'weeklyGoalPercentage': weeklyGoalPercentage,
      'isBiometricEnabled': isBiometricEnabled,
      'createdAt': createdAt.toIso8601String(),
      'locale': locale,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'country': country?.index,
      'useLargeFab': useLargeFab,
      'dashboardLayout': dashboardLayout,
      'appColor': appColor,
    };
  }
} 