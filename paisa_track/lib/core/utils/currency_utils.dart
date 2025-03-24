import 'package:intl/intl.dart';

class CurrencyUtils {
  static String formatCurrency(
    double amount, {
    String currencyCode = 'USD',
    int decimalDigits = 2,
    String locale = 'en_US',
  }) {
    final format = NumberFormat.currency(
      locale: locale,
      symbol: getCurrencySymbol(currencyCode),
      decimalDigits: decimalDigits,
    );
    return format.format(amount);
  }
  
  static String formatCompactCurrency(
    double amount, {
    String currencyCode = 'USD',
    String locale = 'en_US',
  }) {
    final format = NumberFormat.compactCurrency(
      locale: locale,
      symbol: getCurrencySymbol(currencyCode),
    );
    return format.format(amount);
  }
  
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'NPR':
        return 'रू';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'BRL':
        return 'R\$';
      case 'RUB':
        return '₽';
      case 'KRW':
        return '₩';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      case 'THB':
        return '฿';
      case 'IDR':
        return 'Rp';
      case 'PHP':
        return '₱';
      case 'VND':
        return '₫';
      default:
        return currencyCode;
    }
  }
  
  static final Map<String, String> currencyNames = {
    'NPR': 'Nepali Rupee',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'INR': 'Indian Rupee',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'KRW': 'South Korean Won',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'PHP': 'Philippine Peso',
    'VND': 'Vietnamese Dong',
  };
  
  static String getCurrencyName(String currencyCode) {
    return currencyNames[currencyCode] ?? currencyCode;
  }
  
  static List<Map<String, String>> getCurrencyList() {
    // Create a list with NPR first, followed by others
    final npr = {
      'code': 'NPR',
      'name': 'Nepali Rupee',
      'symbol': getCurrencySymbol('NPR'),
    };
    
    final otherCurrencies = currencyNames.entries
        .where((e) => e.key != 'NPR')
        .map((e) => {
              'code': e.key,
              'name': e.value,
              'symbol': getCurrencySymbol(e.key),
            })
        .toList();
    
    return [npr, ...otherCurrencies];
  }
  
  static double parseFormattedCurrency(String value) {
    // Remove currency symbols and other non-numeric characters except decimal point
    final numericString = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  static List<Currency> getCommonCurrencies() {
    return [
      Currency(code: 'NPR', name: 'Nepali Rupee', symbol: 'रू'),
      Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
      Currency(code: 'EUR', name: 'Euro', symbol: '€'),
      Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
      Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
      Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
      Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
      Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
      Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
      Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
      Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
      Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
      Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
      Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
      Currency(code: 'THB', name: 'Thai Baht', symbol: '฿'),
      Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
      Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
      Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
    ];
  }
}

class Currency {
  final String code;
  final String name;
  final String symbol;
  
  Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });
} 