import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';

part 'currency_type.g.dart';

@HiveType(typeId: AppConstants.currencyTypeId)
enum CurrencyType {
  @HiveField(0)
  usd,
  
  @HiveField(1)
  eur,
  
  @HiveField(2)
  gbp,
  
  @HiveField(3)
  inr,
  
  @HiveField(4)
  jpy,
  
  @HiveField(5)
  cad,
  
  @HiveField(6)
  aud,
  
  @HiveField(7)
  cny,
  
  @HiveField(8)
  sgd,
  
  @HiveField(9)
  myr,
  
  @HiveField(10)
  npr,
  
  @HiveField(11)
  brl,
  
  @HiveField(12)
  rub,
  
  @HiveField(13)
  krw,
  
  @HiveField(14)
  thb,
  
  @HiveField(15)
  idr,
  
  @HiveField(16)
  php,
  
  @HiveField(17)
  vnd;
  
  String get symbol {
    switch (this) {
      case CurrencyType.usd:
        return '\$';
      case CurrencyType.eur:
        return '€';
      case CurrencyType.gbp:
        return '£';
      case CurrencyType.inr:
        return '₹';
      case CurrencyType.jpy:
        return '¥';
      case CurrencyType.cad:
        return 'C\$';
      case CurrencyType.aud:
        return 'A\$';
      case CurrencyType.cny:
        return '¥';
      case CurrencyType.sgd:
        return 'S\$';
      case CurrencyType.myr:
        return 'RM';
      case CurrencyType.npr:
        return 'रू';
      case CurrencyType.brl:
        return 'R\$';
      case CurrencyType.rub:
        return '₽';
      case CurrencyType.krw:
        return '₩';
      case CurrencyType.thb:
        return '฿';
      case CurrencyType.idr:
        return 'Rp';
      case CurrencyType.php:
        return '₱';
      case CurrencyType.vnd:
        return '₫';
    }
  }
  
  String get displayName {
    switch (this) {
      case CurrencyType.usd:
        return 'US Dollar';
      case CurrencyType.eur:
        return 'Euro';
      case CurrencyType.gbp:
        return 'British Pound';
      case CurrencyType.inr:
        return 'Indian Rupee';
      case CurrencyType.jpy:
        return 'Japanese Yen';
      case CurrencyType.cad:
        return 'Canadian Dollar';
      case CurrencyType.aud:
        return 'Australian Dollar';
      case CurrencyType.cny:
        return 'Chinese Yuan';
      case CurrencyType.sgd:
        return 'Singapore Dollar';
      case CurrencyType.myr:
        return 'Malaysian Ringgit';
      case CurrencyType.npr:
        return 'Nepali Rupee';
      case CurrencyType.brl:
        return 'Brazilian Real';
      case CurrencyType.rub:
        return 'Russian Ruble';
      case CurrencyType.krw:
        return 'South Korean Won';
      case CurrencyType.thb:
        return 'Thai Baht';
      case CurrencyType.idr:
        return 'Indonesian Rupiah';
      case CurrencyType.php:
        return 'Philippine Peso';
      case CurrencyType.vnd:
        return 'Vietnamese Dong';
    }
  }
  
  static CurrencyType fromCode(String code) {
    try {
      return CurrencyType.values.firstWhere(
        (c) => c.name.toUpperCase() == code.toUpperCase(),
        orElse: () => CurrencyType.usd,
      );
    } catch (_) {
      return CurrencyType.usd;
    }
  }
} 