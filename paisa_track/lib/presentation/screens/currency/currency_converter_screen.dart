import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _result = 0;
  bool _hasConverted = false;
  
  // Sample exchange rates
  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 150.27,
    'CAD': 1.37,
    'AUD': 1.52,
    'CHF': 0.91,
    'CNY': 7.23,
    'INR': 83.31,
    'MXN': 16.76,
  };
  
  final List<String> _currencyCodes = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'MXN'
  ];
  
  final Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'MXN': 'Mexican Peso',
  };
  
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'Fr',
    'CNY': '¥',
    'INR': '₹',
    'MXN': 'Mex\$',
  };
  
  @override
  void initState() {
    super.initState();
    _amountController.text = '1';
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  void _convertCurrency() {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null) return;
    
    double result = 0;
    
    // Get the exchange rate from USD to source currency
    final double fromRate = _exchangeRates[_fromCurrency] ?? 1.0;
    
    // Get the exchange rate from USD to target currency
    final double toRate = _exchangeRates[_toCurrency] ?? 1.0;
    
    // Convert from source to USD, then to target
    result = (amount / fromRate) * toRate;
    
    setState(() {
      _result = result;
      _hasConverted = true;
    });
  }
  
  void _swapCurrencies() {
    setState(() {
      final String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      
      if (_hasConverted) {
        _convertCurrency();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildCurrencySelectors(),
                    const SizedBox(height: 24),
                    _buildConvertButton(),
                    if (_hasConverted) ...[
                      const SizedBox(height: 24),
                      _buildResult(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildExchangeRatesCard(),
            const SizedBox(height: 24),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter amount',
        prefixText: _currencySymbols[_fromCurrency],
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (_hasConverted) {
          _convertCurrency();
        }
      },
    );
  }
  
  Widget _buildCurrencySelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildCurrencyDropdown(
            value: _fromCurrency,
            label: 'From',
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _fromCurrency = value;
                  if (_hasConverted) {
                    _convertCurrency();
                  }
                });
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _swapCurrencies,
            tooltip: 'Swap currencies',
          ),
        ),
        Expanded(
          child: _buildCurrencyDropdown(
            value: _toCurrency,
            label: 'To',
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _toCurrency = value;
                  if (_hasConverted) {
                    _convertCurrency();
                  }
                });
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCurrencyDropdown({
    required String value,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: _currencyCodes.map((String currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(
                '$currency - ${_currencyNames[currency]}',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
  
  Widget _buildConvertButton() {
    return ElevatedButton(
      onPressed: _convertCurrency,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('Convert'),
    );
  }
  
  Widget _buildResult() {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: _currencySymbols[_toCurrency],
      decimalDigits: 2,
    );
    
    final amountValue = double.tryParse(_amountController.text) ?? 0;
    final formattedAmount = NumberFormat.currency(
      symbol: _currencySymbols[_fromCurrency],
      decimalDigits: 2,
    ).format(amountValue);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            formatter.format(_result),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$formattedAmount = ${formatter.format(_result)}',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Exchange rate: 1 $_fromCurrency = ${(_exchangeRates[_toCurrency] ?? 1.0) / (_exchangeRates[_fromCurrency] ?? 1.0)} $_toCurrency',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExchangeRatesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exchange Rates (vs USD)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currencyCodes.map((currency) {
                if (currency == 'USD') return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$currency: ${_exchangeRates[currency]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: These are sample rates for demonstration',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'In the full version of Paisa Track, you\'ll be able to:',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('View conversion history'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.refresh),
              title: Text('Get real-time exchange rates'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Set rate alerts'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text('View historical rate charts'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
} 