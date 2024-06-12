import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyConverter {
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/';

  Future<double?> getExchangeRate(String baseCurrency, String targetCurrency) async {
    final response = await http.get(Uri.parse('$_apiUrl$baseCurrency'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['rates'][targetCurrency];
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }
}
