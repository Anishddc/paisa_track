import 'package:hive/hive.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';

part 'country_type.g.dart';

@HiveType(typeId: 7)
enum CountryType {
  @HiveField(0)
  unitedStates,
  
  @HiveField(1)
  unitedKingdom,
  
  @HiveField(2)
  canada,
  
  @HiveField(3)
  australia,
  
  @HiveField(4)
  germany,
  
  @HiveField(5)
  france,
  
  @HiveField(6)
  japan,
  
  @HiveField(7)
  india,
  
  @HiveField(8)
  china,
  
  @HiveField(9)
  russia,
  
  @HiveField(10)
  brazil,
  
  @HiveField(11)
  southAfrica,
  
  @HiveField(12)
  mexico,
  
  @HiveField(13)
  italy,
  
  @HiveField(14)
  spain,
  
  @HiveField(15)
  southKorea,
  
  @HiveField(16)
  netherlands,
  
  @HiveField(17)
  switzerland,
  
  @HiveField(18)
  sweden,
  
  @HiveField(19)
  norway,
  
  @HiveField(20)
  newZealand,
  
  @HiveField(21)
  uae,
  
  @HiveField(22)
  singapore,
  
  @HiveField(23)
  ireland,
  
  @HiveField(24)
  poland,
  
  @HiveField(25)
  austria,
  
  @HiveField(26)
  belgium,
  
  @HiveField(27)
  denmark,
  
  @HiveField(28)
  finland,
  
  @HiveField(29)
  greece,
  
  @HiveField(30)
  portugal,
  
  @HiveField(31)
  nepal,
}

extension CountryTypeExtension on CountryType {
  String get displayName {
    switch (this) {
      case CountryType.unitedStates:
        return 'United States';
      case CountryType.unitedKingdom:
        return 'United Kingdom';
      case CountryType.canada:
        return 'Canada';
      case CountryType.australia:
        return 'Australia';
      case CountryType.germany:
        return 'Germany';
      case CountryType.france:
        return 'France';
      case CountryType.japan:
        return 'Japan';
      case CountryType.india:
        return 'India';
      case CountryType.china:
        return 'China';
      case CountryType.russia:
        return 'Russia';
      case CountryType.brazil:
        return 'Brazil';
      case CountryType.southAfrica:
        return 'South Africa';
      case CountryType.mexico:
        return 'Mexico';
      case CountryType.italy:
        return 'Italy';
      case CountryType.spain:
        return 'Spain';
      case CountryType.southKorea:
        return 'South Korea';
      case CountryType.netherlands:
        return 'Netherlands';
      case CountryType.switzerland:
        return 'Switzerland';
      case CountryType.sweden:
        return 'Sweden';
      case CountryType.norway:
        return 'Norway';
      case CountryType.newZealand:
        return 'New Zealand';
      case CountryType.uae:
        return 'United Arab Emirates';
      case CountryType.singapore:
        return 'Singapore';
      case CountryType.ireland:
        return 'Ireland';
      case CountryType.poland:
        return 'Poland';
      case CountryType.austria:
        return 'Austria';
      case CountryType.belgium:
        return 'Belgium';
      case CountryType.denmark:
        return 'Denmark';
      case CountryType.finland:
        return 'Finland';
      case CountryType.greece:
        return 'Greece';
      case CountryType.portugal:
        return 'Portugal';
      case CountryType.nepal:
        return 'Nepal';
    }
  }

  String get currencyCode {
    switch (this) {
      case CountryType.unitedStates:
        return 'USD';
      case CountryType.unitedKingdom:
        return 'GBP';
      case CountryType.canada:
        return 'CAD';
      case CountryType.australia:
        return 'AUD';
      case CountryType.germany:
      case CountryType.france:
      case CountryType.italy:
      case CountryType.spain:
      case CountryType.netherlands:
      case CountryType.austria:
      case CountryType.belgium:
      case CountryType.finland:
      case CountryType.greece:
      case CountryType.ireland:
      case CountryType.portugal:
        return 'EUR';
      case CountryType.japan:
        return 'JPY';
      case CountryType.india:
        return 'INR';
      case CountryType.china:
        return 'CNY';
      case CountryType.russia:
        return 'RUB';
      case CountryType.brazil:
        return 'BRL';
      case CountryType.southAfrica:
        return 'ZAR';
      case CountryType.mexico:
        return 'MXN';
      case CountryType.southKorea:
        return 'KRW';
      case CountryType.switzerland:
        return 'CHF';
      case CountryType.sweden:
        return 'SEK';
      case CountryType.norway:
        return 'NOK';
      case CountryType.newZealand:
        return 'NZD';
      case CountryType.uae:
        return 'AED';
      case CountryType.singapore:
        return 'SGD';
      case CountryType.poland:
        return 'PLN';
      case CountryType.denmark:
        return 'DKK';
      case CountryType.nepal:
        return 'NPR';
    }
  }

  String get flagEmoji {
    switch (this) {
      case CountryType.unitedStates:
        return '🇺🇸';
      case CountryType.unitedKingdom:
        return '🇬🇧';
      case CountryType.canada:
        return '🇨🇦';
      case CountryType.australia:
        return '🇦🇺';
      case CountryType.germany:
        return '🇩🇪';
      case CountryType.france:
        return '🇫🇷';
      case CountryType.japan:
        return '🇯🇵';
      case CountryType.india:
        return '🇮🇳';
      case CountryType.china:
        return '🇨🇳';
      case CountryType.russia:
        return '🇷🇺';
      case CountryType.brazil:
        return '🇧🇷';
      case CountryType.southAfrica:
        return '🇿🇦';
      case CountryType.mexico:
        return '🇲🇽';
      case CountryType.italy:
        return '🇮🇹';
      case CountryType.spain:
        return '🇪🇸';
      case CountryType.southKorea:
        return '🇰🇷';
      case CountryType.netherlands:
        return '🇳🇱';
      case CountryType.switzerland:
        return '🇨🇭';
      case CountryType.sweden:
        return '🇸🇪';
      case CountryType.norway:
        return '🇳🇴';
      case CountryType.newZealand:
        return '🇳🇿';
      case CountryType.uae:
        return '🇦🇪';
      case CountryType.singapore:
        return '🇸🇬';
      case CountryType.ireland:
        return '🇮🇪';
      case CountryType.poland:
        return '🇵🇱';
      case CountryType.austria:
        return '🇦🇹';
      case CountryType.belgium:
        return '🇧🇪';
      case CountryType.denmark:
        return '🇩🇰';
      case CountryType.finland:
        return '🇫🇮';
      case CountryType.greece:
        return '🇬🇷';
      case CountryType.portugal:
        return '🇵🇹';
      case CountryType.nepal:
        return '🇳🇵';
    }
  }
  
  // Default currency for each country
  CurrencyType get defaultCurrency {
    switch (this) {
      case CountryType.unitedStates:
        return CurrencyType.usd;
      case CountryType.unitedKingdom:
        return CurrencyType.gbp;
      case CountryType.canada:
        return CurrencyType.cad;
      case CountryType.australia:
        return CurrencyType.aud;
      case CountryType.germany:
      case CountryType.france:
      case CountryType.italy:
      case CountryType.spain:
      case CountryType.netherlands:
      case CountryType.austria:
      case CountryType.belgium:
      case CountryType.finland:
      case CountryType.greece:
      case CountryType.ireland:
      case CountryType.portugal:
        return CurrencyType.eur;
      case CountryType.japan:
        return CurrencyType.jpy;
      case CountryType.india:
        return CurrencyType.inr;
      case CountryType.china:
        return CurrencyType.cny;
      case CountryType.russia:
        return CurrencyType.rub;
      case CountryType.brazil:
        return CurrencyType.brl;
      case CountryType.southAfrica:
        return CurrencyType.usd;
      case CountryType.mexico:
        return CurrencyType.usd;
      case CountryType.southKorea:
        return CurrencyType.krw;
      case CountryType.switzerland:
        return CurrencyType.usd;
      case CountryType.sweden:
        return CurrencyType.usd;
      case CountryType.norway:
        return CurrencyType.usd;
      case CountryType.newZealand:
        return CurrencyType.usd;
      case CountryType.uae:
        return CurrencyType.usd;
      case CountryType.singapore:
        return CurrencyType.sgd;
      case CountryType.poland:
        return CurrencyType.usd;
      case CountryType.denmark:
        return CurrencyType.usd;
      case CountryType.nepal:
        return CurrencyType.npr;
    }
  }
  
  // Helper method to get a CountryType from a string name
  static CountryType fromName(String countryName) {
    try {
      return CountryType.values.firstWhere(
        (country) => country.displayName.toLowerCase() == countryName.toLowerCase(),
        orElse: () => CountryType.unitedStates,
      );
    } catch (_) {
      return CountryType.unitedStates;
    }
  }
} 