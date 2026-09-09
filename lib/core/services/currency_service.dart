import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service to hold and format currency based on Odoo login response & API currency_ids.
class CurrencyService {
  CurrencyService._internal();
  static final CurrencyService instance = CurrencyService._internal();

  String _defaultSymbol = 'R';
  String _defaultName = 'ZAR';
  final Map<int, String> _currenciesMap = {};

  String get defaultSymbol => _defaultSymbol;
  String get defaultName => _defaultName;

  /// Initialize and load stored currency preferences from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSymbol = prefs.getString('app_currency_symbol');
      if (savedSymbol != null && savedSymbol.isNotEmpty) {
        _defaultSymbol = savedSymbol;
      }
      final savedName = prefs.getString('app_currency_name');
      if (savedName != null && savedName.isNotEmpty) {
        _defaultName = savedName;
      }

      final savedMapRaw = prefs.getString('app_currencies_map');
      if (savedMapRaw != null && savedMapRaw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(savedMapRaw);
        decoded.forEach((key, val) {
          final intKey = int.tryParse(key);
          if (intKey != null && val is String) {
            _currenciesMap[intKey] = val;
          }
        });
      }
    } catch (e) {
      debugPrint('CurrencyService init error: $e');
    }
  }

  /// Update currency data from Odoo login response 'currencies' field.
  /// Example input:
  /// {
  ///   "38": {
  ///     "name": "ZAR",
  ///     "symbol": "R",
  ///     "position": "before",
  ///     "digits": [69, 2]
  ///   }
  /// }
  Future<void> updateFromLoginResponse(Map<String, dynamic> currenciesJson) async {
    if (currenciesJson.isEmpty) return;

    try {
      String? firstSymbol;
      String? firstName;

      currenciesJson.forEach((key, value) {
        final intKey = int.tryParse(key.toString());
        if (value is Map<String, dynamic> || value is Map) {
          final symbol = value['symbol'] as String?;
          final name = value['name'] as String?;

          if (intKey != null && symbol != null && symbol.isNotEmpty) {
            _currenciesMap[intKey] = symbol;
          }

          if (firstSymbol == null && symbol != null && symbol.isNotEmpty) {
            firstSymbol = symbol;
            firstName = name;
          }
        }
      });

      if (firstSymbol != null) {
        _defaultSymbol = firstSymbol!;
        if (firstName != null) _defaultName = firstName!;
      }

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_currency_symbol', _defaultSymbol);
      await prefs.setString('app_currency_name', _defaultName);

      final Map<String, String> stringKeyMap = {};
      _currenciesMap.forEach((k, v) => stringKeyMap[k.toString()] = v);
      await prefs.setString('app_currencies_map', jsonEncode(stringKeyMap));

      debugPrint('🔵 [CurrencyService] Updated currency: symbol=$_defaultSymbol, name=$_defaultName, map=$_currenciesMap');
    } catch (e) {
      debugPrint('Error updating currency service from login response: $e');
    }
  }

  /// Get currency symbol by currency_id (can be int, String, List [id, name], or Map).
  /// Falls back to default symbol (from login response or 'R').
  String getSymbol({dynamic currencyId}) {
    if (currencyId != null) {
      int? targetId;
      if (currencyId is int) {
        targetId = currencyId;
      } else if (currencyId is String) {
        targetId = int.tryParse(currencyId);
      } else if (currencyId is List && currencyId.isNotEmpty) {
        targetId = int.tryParse(currencyId[0].toString());
      } else if (currencyId is Map && currencyId['id'] != null) {
        targetId = int.tryParse(currencyId['id'].toString());
      }

      if (targetId != null && _currenciesMap.containsKey(targetId)) {
        return _currenciesMap[targetId]!;
      }
    }
    return _defaultSymbol;
  }

  /// Format an amount with currency symbol.
  /// Example: format(1500) -> "R 1500.00" or "R 1500" if decimalDigits is 0.
  String format(num amount, {dynamic currencyId, int decimalDigits = 2, bool space = true}) {
    final sym = getSymbol(currencyId: currencyId);
    final formattedNum = decimalDigits == 0
        ? amount.round().toString()
        : amount.toStringAsFixed(decimalDigits);
    final sep = space ? ' ' : '';
    return '$sym$sep$formattedNum';
  }
}
