import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/services/firebase_notification_service.dart';

class AuthController extends ChangeNotifier {
  final BaseOdooService _odooService;

  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  String? _errorMessage;

  AuthController(this._odooService);

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  String get userName {
    if (_isGuest) return 'Guest Customer';
    final val = _userProfile?['name'];
    if (val is String && val.isNotEmpty && val != 'false') return val;
    return 'Guest Customer';
  }

  String get userEmail {
    if (_isGuest) return '';
    final val = _userProfile?['email'];
    if (val is String && val.isNotEmpty && val != 'false') return val;
    return '';
  }

  String get userPhone {
    if (_isGuest) return '';
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
        _isGuest = false;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_guest_mode', false);
        } catch (_) {}

        // Fetch full profile info upon success
        final partnerIdStr = _odooService.currentPartnerId?.toString() ?? 'current';
        _userProfile = await _odooService.getCustomerProfile(partnerIdStr);
        _isAuthenticated = true;

        // Automatically sync FCM token to Odoo device token after login
        try {
          await FirebaseNotificationService.syncFcmTokenToOdoo(_odooService);
        } catch (e) {
          debugPrint('Error syncing FCM token post-login: $e');
        }

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
        final loggedIn = await login(email, password);
        if (loggedIn && phone.isNotEmpty) {
          try {
            final partnerIdStr =
                _odooService.currentPartnerId?.toString() ?? 'current';
            await _odooService.updateCustomerProfile(
              customerId: partnerIdStr,
              phone: phone,
            );
          } catch (e) {
            debugPrint('Post-signup phone update warning: $e');
          }
        }
      } else {
        _errorMessage = 'Registration failed. Odoo server returned an error.';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '').trim();
      _errorMessage = cleanMsg.isNotEmpty
          ? cleanMsg
          : 'Registration failed. Please try again.';
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

  /// Authenticates in the background using the configured guest service account.
  /// This creates a valid Odoo session cookie so categories, services,
  /// variants, and pricing can be freely browsed without SessionExpired errors.
  Future<bool> loginAsGuest() async {
    _isLoading = true;
    _errorMessage = null;
    _isGuest = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', true);
    } catch (_) {}
    notifyListeners();

    try {
      final config = AppConfig.instance;
      debugPrint(
        '🔵 [AuthController] Attempting background guest authentication: ${config.guestEmail}',
      );

      bool odooLoginSuccess = false;
      try {
        odooLoginSuccess = await _odooService.login(
          config.guestEmail,
          config.guestPassword,
        );
      } catch (e) {
        debugPrint(
          '⚠️ [AuthController] Background guest login network/credential warning: $e',
        );
        odooLoginSuccess = false;
      }

      _isGuest = true;
      _isAuthenticated = true;
      _userProfile = {
        'name': 'Guest Customer',
        'email': '',
        'phone': '',
        'is_guest': true,
      };

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest_mode', true);
      } catch (_) {}

      debugPrint(
        '🟢 [AuthController] Guest mode activated (sessionEstablished=$odooLoginSuccess)',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🔴 [AuthController] loginAsGuest fallback: $e');
      _isGuest = true;
      _isAuthenticated = true;
      _userProfile = {
        'name': 'Guest Customer',
        'email': '',
        'phone': '',
        'is_guest': true,
      };
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _odooService.logout();
    } catch (e) {
      debugPrint('Logout service exception: $e');
    }
    FirebaseNotificationService.resetTokenState();
    _isGuest = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', false);
    } catch (_) {}
    _isAuthenticated = false;
    _userProfile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuestSaved = prefs.getBool('is_guest_mode') ?? false;

      // Guest session cold-start guard:
      // If the user closed/killed the app while in Guest Mode, clear the temporary guest session.
      // A cold restart must always direct the user to Splash -> Onboarding / Login.
      if (isGuestSaved) {
        debugPrint(
          '🛡️ [AuthController] Cold start detected with previous Guest session. Clearing guest session to show onboarding/login.',
        );
        try {
          await _odooService.logout();
        } catch (_) {}
        await prefs.remove('is_guest_mode');
        await prefs.setBool('is_logged_in', false);
        _isAuthenticated = false;
        _isGuest = false;
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final isLoggedIn = await _odooService.checkAuthStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (isLoggedIn) {
        _isGuest = false;
        _isAuthenticated = true;
        _userProfile = _odooService.savedUserInfo;

        // Sync FCM token to Odoo post auto-login check for registered users only
        try {
          FirebaseNotificationService.syncFcmTokenToOdoo(_odooService)
              .catchError((e) {
            debugPrint('Error syncing FCM token on splash check: $e');
          });
        } catch (_) {}

        // Fetch fresh profile in background
        try {
          final profile = await _odooService
              .getCustomerProfile('current')
              .timeout(const Duration(seconds: 4), onTimeout: () => null);
          if (profile != null) {
            _userProfile = profile;
          }
        } catch (e) {
          debugPrint('🟡 Profile refresh warning on splash: $e');
        }
      } else {
        _isAuthenticated = false;
        _isGuest = false;
        _userProfile = null;
      }

      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('AuthController.checkAuthStatus error: $e');
      _isAuthenticated = false;
      _isGuest = false;
      _userProfile = null;
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
      await _odooService.updateCustomerProfile(
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
      return true;
    } catch (e) {
      _userProfile ??= {};
      if (name != null && name.isNotEmpty) _userProfile!['name'] = name;
      if (phone != null && phone.isNotEmpty) _userProfile!['phone'] = phone;
      if (email != null && email.isNotEmpty) _userProfile!['email'] = email;

      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> uploadProfileImage(Uint8List imageBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerId = _userProfile?['id']?.toString() ?? '1';
      final base64Image = base64Encode(imageBytes);

      await _odooService.uploadProfileImage(
        customerId,
        imageBytes,
      );

      _userProfile ??= {};
      _userProfile!['image_1920'] = base64Image;
      _userProfile!['image_128'] = base64Image;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      final base64Image = base64Encode(imageBytes);
      _userProfile ??= {};
      _userProfile!['image_1920'] = base64Image;
      _userProfile!['image_128'] = base64Image;
      notifyListeners();
      return true;
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
      final result = await _odooService.deleteAccount();
      final success = result['success'] == true;
      if (success) {
        _isAuthenticated = false;
        _userProfile = null;
      } else {
        _errorMessage = result['message']?.toString() ??
            'Failed to delete account. Please try again or contact support.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          _extractPermissionError(e) ?? 'Failed to delete account: $e';
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
      _userProfile!.remove('image_128');

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
      _userProfile!.remove('image_128');
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (!success) {
        _errorMessage =
            'Failed to change password. Please verify your current password.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = cleanMsg.isNotEmpty
          ? cleanMsg
          : 'Failed to change password. Please verify your current password.';
      notifyListeners();
      return false;
    }
  }
}
