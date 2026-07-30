import 'dart:typed_data';
import 'dart:convert';
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

  String get userName {
    final val = _userProfile?['name'];
    if (val is String && val.isNotEmpty && val != 'false') return val;
    return 'Guest Customer';
  }

  String get userEmail {
    final val = _userProfile?['email'];
    if (val is String && val.isNotEmpty && val != 'false') return val;
    return '';
  }

  String get userPhone {
    final val = _userProfile?['phone'];
    if (val is String && val.isNotEmpty && val != 'false') return val;
    return '';
  }

  String? get profileImageBase64 {
    final img = _userProfile?['image_1920'] ?? _userProfile?['image_128'];
    if (img == null ||
        img == false ||
        img is! String ||
        img.isEmpty ||
        img == 'false') {
      return null;
    }
    return img;
  }

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
      _errorMessage =
          'Failed to connect to Odoo server. Please check your credentials or network.';
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signup(
    String name,
    String email,
    String phone,
    String password,
  ) async {
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

  Future<bool> resetPassword({required String email, String? database}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.forgotPassword(
        email: email,
        database: database,
      );
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

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final isLoggedIn = await _odooService.checkAuthStatus().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      _isAuthenticated = isLoggedIn;
      if (isLoggedIn) {
        _userProfile = await _odooService
            .getCustomerProfile('current')
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
      }
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh loyalty points or info from backend
  Future<void> refreshProfile() async {
    if (_userProfile != null) {
      final profile = await _odooService.getCustomerProfile(
        _userProfile!['id'].toString(),
      );
      if (profile != null) {
        _userProfile = profile;
        notifyListeners();
      }
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerId = _userProfile?['id']?.toString() ?? '1';
      final success = await _odooService.updateCustomerProfile(
        customerId: customerId,
        name: name,
        phone: phone,
        email: email,
      );

      _userProfile ??= {};
      if (name != null && name.isNotEmpty) _userProfile!['name'] = name;
      if (phone != null && phone.isNotEmpty) _userProfile!['phone'] = phone;
      if (email != null && email.isNotEmpty) _userProfile!['email'] = email;

      _isLoading = false;
      notifyListeners();
      if (!success) {
        _errorMessage =
            'Failed to update profile. Please check permissions or try again.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          _extractPermissionError(e) ?? 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage(Uint8List imageBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerId = _userProfile?['id']?.toString() ?? '1';
      final base64Image = base64Encode(imageBytes);

      final success = await _odooService.uploadProfileImage(
        customerId,
        imageBytes,
      );

      _userProfile ??= {};
      _userProfile!['image_1920'] = base64Image;

      _isLoading = false;
      notifyListeners();
      if (!success) {
        _errorMessage =
            'Photo saved locally but failed to sync to server. Check permissions.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _isLoading = false;
      final base64Image = base64Encode(imageBytes);
      _userProfile ??= {};
      _userProfile!['image_1920'] = base64Image;
      _errorMessage =
          _extractPermissionError(e) ??
          'Photo saved locally. Server sync failed: $e';
      notifyListeners();
      return false;
    }
  }

  String? _extractPermissionError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('not allowed') ||
        msg.contains('permission') ||
        msg.contains('access')) {
      return 'Permission denied. Your account lacks access to modify profile records on the server. Please contact support.';
    }
    return null;
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.deleteAccount();
      if (success) {
        _isAuthenticated = false;
        _userProfile = null;
      } else {
        _errorMessage = 'Failed to delete account. Please contact support.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _extractPermissionError(e) ?? 'Failed to delete account: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearProfilePicture() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerId = _userProfile?['id']?.toString() ?? '1';
      final success = await _odooService.clearProfilePicture(customerId);

      _userProfile ??= {};
      _userProfile!.remove('image_1920');

      _isLoading = false;
      notifyListeners();
      if (!success) {
        _errorMessage = 'Photo removed locally but server sync failed. Check permissions.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _isLoading = false;
      _userProfile ??= {};
      _userProfile!.remove('image_1920');
      _errorMessage = _extractPermissionError(e) ?? 'Photo removed locally. Server sync failed: $e';
      notifyListeners();
      return false;
    }
  }
}
