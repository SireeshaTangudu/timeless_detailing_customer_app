import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';

class AuthController extends ChangeNotifier {
  final BaseOdooService _odooService;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  String? _errorMessage;

  AuthController(this._odooService);

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  String get userName => _userProfile?['name'] ?? 'Guest Customer';
  String get userEmail => _userProfile?['email'] ?? '';
  int get loyaltyPoints => _userProfile?['loyalty_points'] ?? 0;
  String get memberSince => _userProfile?['member_since'] ?? 'N/A';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.login(email, password);
      if (success) {
        // Fetch full profile info upon success
        _userProfile = await _odooService.getCustomerProfile('res_partner_12');
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to Odoo server. Please check your credentials or network.';
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signup(String name, String email, String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.signup(name, email, phone, password);
      if (success) {
        // Automatically attempt login after registering
        await login(email, password);
      } else {
        _errorMessage = 'Registration failed. Odoo server returned an error.';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to reset password. Please check network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _odooService.logout();
    _isAuthenticated = false;
    _userProfile = null;
    _isLoading = false;
    notifyListeners();
  }

  // Refresh loyalty points or info from backend
  Future<void> refreshProfile() async {
    if (_userProfile != null) {
      final profile = await _odooService.getCustomerProfile(_userProfile!['id'].toString());
      if (profile != null) {
        _userProfile = profile;
        notifyListeners();
      }
    }
  }
}
