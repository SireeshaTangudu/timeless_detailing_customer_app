import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/product_category_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/bookable_slot_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';
import 'package:timeless_detailing_customer_app/core/services/firebase_notification_service.dart';

abstract class BaseOdooService {
  String get baseUrl;
  String get db;
  Future<bool> login(String email, String password);
  Future<void> logout();
  Future<List<DetailService>> getServices();
  Future<List<Booking>> getBookings(String customerId);
  Future<Booking> createBooking(Booking booking);
  Future<Booking?> getLiveTrackingBooking(String bookingId);
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId);
  Future<bool> signup(String name, String email, String phone, String password);
  Future<bool> forgotPassword({required String email, String? database});
  Future<bool> checkAuthStatus();
  Future<bool> updateCustomerProfile({
    required String customerId,
    String? name,
    String? phone,
    String? email,
  });
  Future<bool> uploadProfileImage(String customerId, Uint8List imageBytes);
  Future<bool> clearProfilePicture(String customerId);
  Future<bool> deleteAccount();
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  });
  Map<String, dynamic>? get savedUserInfo;
  int? get currentPartnerId;
  int? get currentUid;

  // Mobile API Integration Endpoints
  Future<List<ProductCategory>> getProductCategories();
  Future<List<DetailService>> getServicesFromProductTemplate({int? categoryId});
  Future<List<ProductVariant>> getServiceDetailsWithVariants(int templateId);
  Future<ProductVariant?> getVariantById(int productId);
  Future<BookableSlotsResult?> getBookableSlots({
    required int appointmentTypeId,
    required String timezone,
    required int resourceId,
    required int askedCapacity,
    required String date,
  });
  Future<Map<String, dynamic>?> bookAppointment({
    required String name,
    required int appointmentTypeId,
    int? productId,
    required int appointmentBookerId,
    required List<int> partnerIds,
    required String start,
    required String stop,
    double duration = 1.0,
    int? resourceId,
    String? phone,
    String? collectorName,
    String? collectorLicense,
    String? vehicleMake,
    String? vehicleModel,
    List<String>? vehicleImagesBase64,
  });
  Future<Map<String, dynamic>> getUserBookings(int partnerId);
  Future<Map<String, dynamic>?> getBookingDetails(int bookingId);
  Future<Map<String, dynamic>?> cancelBooking({
    required int bookingId,
    required List<int> partnerIds,
  });
  Future<List<ProjectModel>> getProjects();
  Future<List<ProjectTaskModel>> getProjectTasks(int projectId);
  Future<List<ProjectTaskTypeModel>> getProjectTaskTypes(int projectId);
  Future<List<Map<String, dynamic>>> getSentQuotations({int? partnerId});
  Future<List<Map<String, dynamic>>> getSaleOrders({int? partnerId});
  Future<Map<String, dynamic>?> getQuotationDetails(int orderId);
  Future<bool> acceptQuotation({
    required int orderId,
    required String name,
    String? signatureBase64,
    String? accessToken,
  });
  Future<Map<String, dynamic>?> getCompanyLocationDetails();
  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
    String? previousToken,
  });
  Future<bool> deactivateDeviceToken({String? token, int? deviceId});
  Future<List<Map<String, dynamic>>> getDeviceTokens();
  Future<List<Map<String, dynamic>>> getUserNotifications({int? partnerId});
  Future<Map<String, dynamic>?> getNotificationDetail(int notificationId);
  Future<Map<String, dynamic>?> getInvoiceDetails(int invoiceId);
  Future<List<Map<String, dynamic>>> getUserInvoices({int? partnerId});
  Future<List<Cookie>> getCookies();
}

class OdooApiService implements BaseOdooService {
  Dio? _dio;
  PersistCookieJar? _cookieJar;

  final String baseUrl;
  final String db;
  int? _uid;
  int? _partnerId;
  String? _sessionId;
  Map<String, dynamic>? _savedUserInfo;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    preferencesKeyPrefix: 'timeless_detailing',
  );
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  OdooApiService({required this.baseUrl, required this.db});

  @override
  Map<String, dynamic>? get savedUserInfo => _savedUserInfo;

  @override
  int? get currentPartnerId => _partnerId;

  @override
  int? get currentUid => _uid;

  /// Initialize the API client with instance URL, persistent cookies and headers
  Future<void> initialize() async {
    if (_dio != null) return;

    String cleanUrl = baseUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (cleanUrl.toLowerCase().endsWith('/odoo')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 5);
    }
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: cleanUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Bypass SSL certificate verification on staging/dev Odoo servers
    if (_dio!.httpClientAdapter is IOHttpClientAdapter) {
      (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/odoo_cookies'),
    );

    _dio!.interceptors.add(CookieManager(_cookieJar!));
  }

  Future<void> _ensureInitialized() async {
    await initialize();
  }

  @override
  Future<List<Cookie>> getCookies() async {
    await _ensureInitialized();
    final list = <Cookie>[];
    if (_cookieJar != null) {
      try {
        final uri = Uri.parse(baseUrl);
        final cList = await _cookieJar!.loadForRequest(uri);
        list.addAll(cList);
      } catch (e) {
        debugPrint('getCookies error: $e');
      }
    }

    String? sess = _sessionId;
    if (sess == null || sess.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        sess = prefs.getString('session_id');
        if (sess != null && sess.isNotEmpty) {
          _sessionId = sess;
        }
      } catch (_) {}
    }

    if (sess != null &&
        sess.isNotEmpty &&
        !list.any((c) => c.name == 'session_id')) {
      list.add(Cookie('session_id', sess));
    }
    return list;
  }

  bool _isReauthenticating = false;

  /// Helper to automatically re-authenticate when session expires
  Future<bool> _tryReauthenticate() async {
    if (_isReauthenticating) return false;
    _isReauthenticating = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser =
          prefs.getString('username') ??
          prefs.getString('user_email') ??
          await _storage.read(key: 'username').catchError((_) => null);
      final savedPass =
          prefs.getString('password') ??
          await _storage.read(key: 'password').catchError((_) => null);

      if (savedUser != null &&
          savedUser.isNotEmpty &&
          savedPass != null &&
          savedPass.isNotEmpty) {
        debugPrint(
          '🔑 [OdooApiService] Auto re-authenticating user ($savedUser)...',
        );
        final success = await login(savedUser, savedPass);
        _isReauthenticating = false;
        return success;
      }
    } catch (e) {
      debugPrint('🔴 [OdooApiService] Auto re-authentication error: $e');
    }
    _isReauthenticating = false;
    return false;
  }

  /// JSON-RPC caller helper mapping to Odoo's call_kw endpoint
  Future<dynamic> _callKw({
    required String model,
    required String method,
    required List<dynamic> args,
    required Map<String, dynamic> kwargs,
  }) async {
    await _ensureInitialized();
    try {
      debugPrint('🔵 [OdooApiService] _callKw $model/$method...');
      Response response;
      try {
        response = await _dio!.post(
          '/web/dataset/call_kw/$model/$method',
          data: {
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'model': model,
              'method': method,
              'args': args,
              'kwargs': kwargs,
            },
          },
          options: Options(
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 90),
          ),
        );
      } catch (e) {
        debugPrint(
          '🔵 Path /web/dataset/call_kw/$model/$method failed ($e). Retrying /web/dataset/call_kw...',
        );
        response = await _dio!.post(
          '/web/dataset/call_kw',
          data: {
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'model': model,
              'method': method,
              'args': args,
              'kwargs': kwargs,
            },
          },
          options: Options(
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 90),
          ),
        );
      }

      final error = response.data['error'];
      if (error != null) {
        final errorMsg = (error['data']?['message'] ?? error['message'] ?? '')
            .toString();
        final errorName = (error['data']?['name'] ?? '').toString();
        final isSessionExpired =
            errorMsg.toLowerCase().contains('session expired') ||
            errorName.contains('SessionExpired') ||
            error['code'] == 100;

        if (isSessionExpired && !_isReauthenticating) {
          debugPrint(
            '⚠️ [OdooApiService] Session expired on $model/$method. Attempting auto re-authentication...',
          );
          final reauthSuccess = await _tryReauthenticate();
          if (reauthSuccess) {
            debugPrint(
              '🟢 [OdooApiService] Auto re-authentication successful. Retrying $model/$method...',
            );
            return _callKw(
              model: model,
              method: method,
              args: args,
              kwargs: kwargs,
            );
          }
        }

        throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Odoo JSON-RPC Error');
      }

      return response.data['result'];
    } catch (e) {
      final errStr = e.toString();
      if (errStr.toLowerCase().contains('session expired') &&
          !_isReauthenticating) {
        debugPrint(
          '⚠️ [OdooApiService] Exception contains "session expired". Attempting re-authentication...',
        );
        final reauthSuccess = await _tryReauthenticate();
        if (reauthSuccess) {
          return _callKw(
            model: model,
            method: method,
            args: args,
            kwargs: kwargs,
          );
        }
      }
      print('Odoo call_kw error on $model/$method: $e');
      rethrow;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    print('Odoo login attempt: URL=$baseUrl, DB=$db, Login=$email');
    try {
      await _ensureInitialized();

      final response = await _dio!.post(
        '/web/session/authenticate',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'db': db, 'login': email, 'password': password},
        },
      );

      print('Odoo login response code: ${response.statusCode}');
      print('Odoo login response data: ${response.data}');

      final result = response.data['result'];

      if (result != null && result['uid'] != null && result['uid'] != false) {
        print('Odoo authentication successful! UID=${result['uid']}');
        _uid = result['uid'];
        _sessionId = result['session_id'];

        if (result['partner_id'] != null) {
          if (result['partner_id'] is int) {
            _partnerId = result['partner_id'];
          } else if (result['partner_id'] is List &&
              (result['partner_id'] as List).isNotEmpty) {
            _partnerId = result['partner_id'][0] as int;
          }
        }

        final userName =
            result['name'] ??
            result['partner_display_name'] ??
            result['username'] ??
            '';
        final userPhone = result['phone'] is String
            ? result['phone'] as String
            : '';
        _savedUserInfo = {
          'id': _partnerId ?? _uid,
          'name': userName,
          'email': result['username'] ?? email,
          'phone': userPhone,
        };

        // Save session state to SharedPreferences and SecureStorage for 100% reliable persistence
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('username', email);
          await prefs.setString('password', password);
          if (_uid != null) await prefs.setInt('uid', _uid!);
          if (_partnerId != null) await prefs.setInt('partner_id', _partnerId!);
          await prefs.setString('session_id', _sessionId ?? '');
          await prefs.setString('user_name', userName);
          await prefs.setString('user_email', email);
          await prefs.setString('user_phone', userPhone);
        } catch (e) {
          debugPrint('SharedPreferences save error: $e');
        }

        try {
          await _storage.write(key: 'instance_url', value: baseUrl);
          await _storage.write(key: 'database', value: db);
          await _storage.write(key: 'username', value: email);
          await _storage.write(key: 'password', value: password);
          await _storage.write(key: 'is_logged_in', value: 'true');
          await _storage.write(key: 'uid', value: _uid.toString());
          if (_partnerId != null) {
            await _storage.write(
              key: 'partner_id',
              value: _partnerId.toString(),
            );
          }
          await _storage.write(key: 'session_id', value: _sessionId ?? '');
          await _storage.write(key: 'user_name', value: userName);
          await _storage.write(key: 'user_email', value: email);
          await _storage.write(key: 'user_phone', value: userPhone);
        } catch (_) {}

        return true;
      }
      print(
        'Odoo authentication failed: Invalid username or password (result is null/false).',
      );
      return false;
    } catch (e) {
      print('Odoo authenticate caught exception: $e');
      rethrow;
    }
  }

  @override
  Future<bool> signup(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      await _ensureInitialized();

      // 1. Fetch CSRF token via GET request first
      print('Odoo signup: fetching CSRF token from page...');
      final getResponse = await _dio!.get(
        '/web/signup',
        queryParameters: {'db': db},
      );

      String? csrfToken;
      final html = getResponse.data.toString();
      final tokenRegex = RegExp(
        r'name="csrf_token"\s+value="([^"]+)"|csrf_token:\s*"([^"]+)"',
      );
      final match = tokenRegex.firstMatch(html);
      if (match != null) {
        csrfToken = match.group(1) ?? match.group(2);
      }

      print('Odoo signup CSRF: $csrfToken');

      // 2. Perform POST registration with CSRF token included
      final response = await _dio!.post(
        '/web/signup',
        data: {
          'csrf_token': csrfToken ?? '',
          'db': db,
          'name': name,
          'login': email,
          'password': password,
          'confirm_password': password,
          'phone': phone,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // Let Dio handle redirects normally, but allow 302 and 200 responses
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      print('Odoo signup response path: ${response.realUri.path}');
      // Odoo stays on '/web/signup' if registration fails (displays validation errors).
      // On success, Odoo redirects the session to '/web' or '/my/home'.
      final success =
          response.statusCode == 200 && response.realUri.path != '/web/signup';
      print('Odoo signup result: success=$success');
      return success;
    } catch (e) {
      print('Odoo signup error: $e');
      return false;
    }
  }

  @override
  Future<bool> forgotPassword({required String email, String? database}) async {
    await _ensureInitialized();

    if (_dio == null) {
      debugPrint("Forgot Password Error: Dio service not initialized.");
      return false;
    }

    final targetDb = (database != null && database.isNotEmpty) ? database : db;

    debugPrint("🚀 --- Starting Forgot Password Flow ---");

    try {
      debugPrint("Step 1: Fetching '/web/reset_password' to get CSRF token...");
      final getResponse = await _dio!.get(
        '/web/reset_password',
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint(
        "✅ GET request completed with status code: ${getResponse.statusCode}",
      );
      final html = getResponse.data.toString();

      // Print a snippet of the HTML to avoid flooding the console
      final htmlSnippet = html.length > 800 ? html.substring(0, 800) : html;
      debugPrint("📄 HTML Snippet Received:\n---\n$htmlSnippet\n---");

      // --- STEP 2: PARSE the HTML to find the CSRF token ---
      debugPrint("🔎 Step 2: Searching for CSRF token in HTML...");

      // Let's try two common patterns for the CSRF token
      RegExp csrfRegex = RegExp(
        r'name="csrf_token"\s*value="([^"]+)"',
      ); // Pattern 1: <input> tag
      Match? match = csrfRegex.firstMatch(html);

      if (match == null) {
        debugPrint(
          "CSRF token not found with <input> pattern. Trying JSON pattern...",
        );
        csrfRegex = RegExp(
          r'"csrf_token"\s*:\s*"([^"]+)"',
        ); // Pattern 2: JSON script
        match = csrfRegex.firstMatch(html);
      }

      if (match == null) {
        debugPrint(
          "CRITICAL: CSRF token could not be found in the HTML response. Cannot proceed.",
        );
        debugPrint(
          "ACTION: Manually inspect the full HTML in the console to find the token's format.",
        );
        // To see the full HTML, uncomment the line below
        // debugPrint("Full HTML: $html");
        return false;
      }

      final csrfToken = match.group(1)!;

      // --- STEP 3: POST the form data ---
      debugPrint("🔎 Step 3: Posting data to '/web/reset_password'...");
      final postResponse = await _dio!.post(
        '/web/reset_password',
        data: {'login': email, 'db': targetDb, 'csrf_token': csrfToken},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint(
        "POST request completed with status code: ${postResponse.statusCode}",
      );
      final responseText = postResponse.data.toString();
      debugPrint("POST Response Body:\n---\n$responseText\n---");

      // --- STEP 4: CHECK for success ---
      debugPrint("Step 4: Analyzing POST response for success message...");
      // A successful reset usually shows a confirmation message.
      // Let's check for common success phrases.
      bool success = responseText.contains(
        'Password reset instructions sent to your email address.',
      );

      if (success) {
        debugPrint("SUCCESS: Found a likely success message in the response.");
      } else {
        debugPrint("FAILURE: Could not find a known success message.");
        debugPrint(
          "ACTION: Check the 'POST Response Body' above to see what Odoo is actually saying.",
        );
      }

      debugPrint("--- Finished Forgot Password Flow ---");
      return success;
    } on DioException catch (e) {
      debugPrint(
        "CRITICAL DioException: An unrecoverable network error occurred.",
      );
      debugPrint("   Error Type: ${e.type}");
      debugPrint("   Error Message: ${e.message}");
      if (e.response != null) {
        debugPrint("   Response Data: ${e.response?.data}");
      }
      debugPrint(" --- Finished Forgot Password Flow with Error ---");
      return false;
    } catch (e) {
      debugPrint(" CRITICAL Unhandled Exception: $e");
      debugPrint(" --- Finished Forgot Password Flow with Error ---");
      return false;
    }
  }

  @override
  Future<bool> deactivateDeviceToken({String? token, int? deviceId}) async {
    bool success = false;

    // Preferred method: deactivate_token(fcmToken)
    if (token != null && token.isNotEmpty) {
      try {
        debugPrint(
          '🔵 [OdooApiService] Deactivating device token via timeless.device.token/deactivate_token...',
        );
        final resp = await _callKw(
          model: 'timeless.device.token',
          method: 'deactivate_token',
          args: [token],
          kwargs: {},
        );
        debugPrint('🟢 [OdooApiService] deactivate_token response: $resp');
        if (resp != null && resp is Map) {
          if (resp['success'] == true) {
            success = true;
          } else if (resp['status'] == 'no_device' &&
              deviceId != null &&
              deviceId > 0) {
            debugPrint(
              '🟡 deactivate_token returned no_device status, falling back to deactivate([[device_id]]) for id=$deviceId...',
            );
          }
        }
      } catch (e) {
        debugPrint('🟡 deactivate_token RPC error: $e');
      }
    }

    // Fallback or explicit method by device_id: deactivate([[deviceId]])
    if (!success && deviceId != null && deviceId > 0) {
      try {
        debugPrint(
          '🔵 [OdooApiService] Deactivating device token id=$deviceId via timeless.device.token/deactivate...',
        );
        final resp = await _callKw(
          model: 'timeless.device.token',
          method: 'deactivate',
          args: [
            [deviceId],
          ],
          kwargs: {},
        );
        debugPrint(
          '🟢 [OdooApiService] Deactivated device token id=$deviceId success, response: $resp',
        );
        if (resp != null &&
            (resp == true || (resp is Map && resp['success'] == true))) {
          success = true;
        }
      } catch (e) {
        debugPrint('🟡 Deactivate device token warning: $e');
      }
    }

    return success;
  }

  @override
  Future<void> logout() async {
    try {
      // Step 1: Read cached FCM token and device_id BEFORE clearing session
      String? token = FirebaseNotificationService.fcmToken;
      if (token == null || token.isEmpty) {
        try {
          token = await _storage.read(key: 'cached_fcm_token');
        } catch (_) {}
      }
      if (token == null || token.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('cached_fcm_token');
        } catch (_) {}
      }

      int? tokenId = _registeredTokenId;
      if (tokenId == null) {
        try {
          final val = await _storage.read(key: 'registered_token_id');
          if (val != null && val.isNotEmpty) {
            tokenId = int.tryParse(val);
          }
        } catch (_) {}
      }
      if (tokenId == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          tokenId = prefs.getInt('registered_token_id');
        } catch (_) {}
      }

      // Step 2: Deactivate device token WHILE session is still valid
      await deactivateDeviceToken(token: token, deviceId: tokenId);

      // Step 3: Clear local token storage & state
      try {
        await _storage.delete(key: 'registered_token_id');
        await _storage.delete(key: 'cached_fcm_token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('registered_token_id');
        await prefs.remove('cached_fcm_token');
      } catch (_) {}

      FirebaseNotificationService.resetTokenState();
      _registeredTokenId = null;

      // Step 4: Finally clear session
      await _clearSession();
      _dio = null;
    } catch (e) {
      debugPrint('🔴 Odoo logout error: $e');
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    try {
      await _ensureInitialized();

      // Read from SharedPreferences first (rock-solid persistence across app restarts and device cold boots)
      final prefs = await SharedPreferences.getInstance();
      final bool prefLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final String? prefEmail =
          prefs.getString('username') ?? prefs.getString('user_email');
      final String? prefPassword = prefs.getString('password');
      final int? prefUid = prefs.getInt('uid');
      final int? prefPartnerId = prefs.getInt('partner_id');
      final String? prefName = prefs.getString('user_name');
      final String? prefPhone = prefs.getString('user_phone');
      final String? prefSessionId = prefs.getString('session_id');

      // Also read from secure storage as fallback
      final savedUidStr = await _storage
          .read(key: 'uid')
          .catchError((_) => null);
      final isLoggedInFlag = await _storage
          .read(key: 'is_logged_in')
          .catchError((_) => null);
      final savedEmail =
          await _storage.read(key: 'username').catchError((_) => null) ??
          await _storage.read(key: 'user_email').catchError((_) => null);
      final savedPassword = await _storage
          .read(key: 'password')
          .catchError((_) => null);

      final String? effectiveEmail = prefEmail ?? savedEmail;
      final String? effectivePassword = prefPassword ?? savedPassword;
      final int? effectiveUid = (prefUid != null && prefUid > 0)
          ? prefUid
          : int.tryParse(savedUidStr ?? '');
      final int? effectivePartnerId =
          prefPartnerId ??
          int.tryParse(
            await _storage.read(key: 'partner_id').catchError((_) => null) ??
                '',
          );
      final bool isLoggedIn =
          prefLoggedIn ||
          (isLoggedInFlag == 'true') ||
          (effectiveEmail != null && effectiveEmail.isNotEmpty);

      if (!isLoggedIn) {
        return false;
      }

      _uid = effectiveUid;
      _partnerId = effectivePartnerId;
      _sessionId =
          prefSessionId ??
          await _storage.read(key: 'session_id').catchError((_) => null);

      final savedName =
          prefName ??
          await _storage.read(key: 'user_name').catchError((_) => null);
      final savedPhone =
          prefPhone ??
          await _storage.read(key: 'user_phone').catchError((_) => null);

      _savedUserInfo = {
        'id': _partnerId ?? _uid ?? 1,
        'name': savedName ?? 'Customer',
        'email': effectiveEmail ?? '',
        'phone': savedPhone ?? '',
      };

      // Background silent re-auth to refresh session cookies (non-blocking for fast splash load)
      if (effectiveEmail != null &&
          effectivePassword != null &&
          effectiveEmail.isNotEmpty &&
          effectivePassword.isNotEmpty) {
        login(effectiveEmail, effectivePassword).catchError((e) {
          debugPrint('Silent re-auth background error: $e');
          return false;
        });
      }

      return true;
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
      return true;
    }
  }

  Future<void> _clearSession() async {
    try {
      await _cookieJar?.deleteAll();
      await _storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    _uid = null;
    _partnerId = null;
    _sessionId = null;
    _savedUserInfo = null;
  }

  List<DetailService> _getFallbackServices() {
    return const [];
  }

  @override
  Future<List<DetailService>> getServices() async {
    try {
      await _ensureInitialized();

      // 1. Try querying product.template first (accessible to portal/customer users)
      try {
        final response = await _callKw(
          model: 'product.template',
          method: 'search_read',
          args: [[]],
          kwargs: {
            'fields': [
              'id',
              'name',
              'description_sale',
              'list_price',
              'categ_id',
              'image_1920',
            ],
            'limit': 50,
          },
        );

        if (response != null && response is List && response.isNotEmpty) {
          return response.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            if (map.containsKey('list_price')) {
              map['lst_price'] = map['list_price'];
            }
            return DetailService.fromOdooJson(map);
          }).toList();
        }
      } catch (e) {
        print('product.template search_read error: $e');
      }

      // 2. Fallback to product.product if product.template didn't return items
      try {
        final response = await _callKw(
          model: 'product.product',
          method: 'search_read',
          args: [[]],
          kwargs: {
            'fields': [
              'id',
              'name',
              'description_sale',
              'lst_price',
              'categ_id',
              'image_1920',
            ],
            'limit': 50,
          },
        );

        if (response != null && response is List && response.isNotEmpty) {
          return response
              .map(
                (item) =>
                    DetailService.fromOdooJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (e) {
        print('product.product search_read error: $e');
      }

      return _getFallbackServices();
    } catch (e) {
      print('Odoo getServices error: $e');
      return _getFallbackServices();
    }
  }

  // =========================================================================
  // MOBILE API INTEGRATION ENDPOINTS
  // =========================================================================

  /// Get Product Categories (`timeless.product.category/web_search_read`)
  @override
  Future<List<ProductCategory>> getProductCategories() async {
    debugPrint(
      '🔵 [OdooApiService] Calling timeless.product.category/web_search_read...',
    );
    try {
      final response = await _callKw(
        model: 'timeless.product.category',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [],
          'specification': {
            'id': {},
            'name': {},
            'sequence': {},
            'image': {},
            'write_date': {},
          },
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      if (records.isNotEmpty) {
        debugPrint(
          '🟢 [OdooApiService] getProductCategories returned ${records.length} categories',
        );
        return records.map((item) {
          return ProductCategory.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getProductCategories error: $e');
      return [];
    }
  }

  /// ENDPOINT 1: Get Main Services (`product.template/web_search_read`)
  @override
  Future<List<DetailService>> getServicesFromProductTemplate({
    int? categoryId,
  }) async {
    debugPrint(
      '🔵 [OdooApiService] Calling product.template/web_search_read (categoryId=$categoryId)...',
    );
    try {
      dynamic response;
      final List<dynamic> domain = [
        ['sale_ok', '=', true],
        ['timeless_published', '=', true],
        if (categoryId != null) ['mobile_categ_id', '=', categoryId],
      ];

      final Map<String, dynamic> specification = {
        'id': {},
        'name': {},
        'list_price': {},
        'currency_id': {},
        'product_variant_count': {},
        'write_date': {},
        'mobile_image': {},
        'mobile_categ_id': {
          'fields': {'id': {}, 'name': {}},
        },
        'timeless_coverage_line_ids': {
          'fields': {
            'id': {},
            'sequence': {},
            'view': {},
            'view_image_url': {},
            'panel_key': {},
            'title': {},
            'icon': {},
            'x_percent': {},
            'y_percent': {},
            'description': {},
            'product_id': {
              'fields': {'id': {}, 'display_name': {}},
            },
          },
        },
        'product_variant_ids': {
          'fields': {
            'id': {},
            'name': {},
            'display_name': {},
            'lst_price': {},
            'appointment_type_id': {
              'fields': {
                'id': {},
                'name': {},
                'appointment_duration': {},
                'message_intro': {},
                'min_schedule_hours': {},
                'max_schedule_days': {},
                'min_cancellation_hours': {},
              },
            },
            'appointment_resource_id': {
              'fields': {'id': {}, 'name': {}, 'capacity': {}},
            },
            'timeless_page_tagline': {},
            'timeless_page_intro': {},
            'timeless_page_conclusion': {},
            'timeless_hide_price': {},
            'timeless_cta_label': {},
            'timeless_feature_line_ids': {
              'fields': {'sequence': {}, 'text': {}},
            },
            'timeless_faq_line_ids': {
              'fields': {'sequence': {}, 'question': {}, 'answer': {}},
            },
          },
        },
      };

      try {
        response = await _callKw(
          model: 'product.template',
          method: 'web_search_read',
          args: [],
          kwargs: {'domain': domain, 'specification': specification},
        );
      } catch (e) {
        debugPrint(
          'Endpoint 1 custom domain/specification error ($e). Retrying with simple domain...',
        );
        response = await _callKw(
          model: 'product.template',
          method: 'web_search_read',
          args: [],
          kwargs: {
            'domain': categoryId != null
                ? [
                    ['mobile_categ_id', '=', categoryId],
                  ]
                : [],
            'specification': {
              'id': {},
              'name': {},
              'list_price': {},
              'currency_id': {},
              'product_variant_count': {},
            },
          },
        );
      }

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      if (records.isNotEmpty) {
        debugPrint(
          '🟢 [OdooApiService] web_search_read returned ${records.length} records',
        );
        return records.map((item) {
          return DetailService.fromOdooJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      debugPrint(
        '🟡 [OdooApiService] web_search_read returned 0 records. Trying getServices()...',
      );
      final fallbackServices = await getServices();
      if (fallbackServices.isNotEmpty) {
        return fallbackServices;
      }
      return _getFallbackServices();
    } catch (e) {
      debugPrint(
        '🔴 [OdooApiService] Endpoint 1 error: $e. Using fallback services',
      );
      return getServices();
    }
  }

  /// ENDPOINT 2: Get Service Details with Variants (`product.product/web_search_read`)
  @override
  Future<List<ProductVariant>> getServiceDetailsWithVariants(
    int templateId,
  ) async {
    debugPrint(
      '🔵 [OdooApiService] Calling Endpoint 2 (product.product/web_search_read) for templateId=$templateId...',
    );
    try {
      dynamic response;
      try {
        response = await _callKw(
          model: 'product.product',
          method: 'web_search_read',
          args: [],
          kwargs: {
            'domain': [
              ['product_tmpl_id', '=', templateId],
              ['appointment_type_id', '!=', false],
              ['appointment_type_id.is_published', '=', true],
              ['appointment_type_id.active', '=', true],
              ['timeless_published', '=', true],
            ],
            'specification': {
              'id': {},
              'name': {},
              'display_name': {},
              'lst_price': {},
              'product_template_variant_value_ids': {
                'fields': {'id': {}, 'name': {}},
              },
              'appointment_type_id': {
                'fields': {
                  'id': {},
                  'name': {},
                  'appointment_duration': {},
                  'message_intro': {},
                  'min_schedule_hours': {},
                  'max_schedule_days': {},
                  'min_cancellation_hours': {},
                },
              },
              'appointment_resource_id': {
                'fields': {'id': {}, 'name': {}, 'capacity': {}},
              },
            },
          },
        );
      } catch (e) {
        debugPrint(
          'Endpoint 2 custom domain/fields error ($e). Retrying with simple domain...',
        );
        response = await _callKw(
          model: 'product.product',
          method: 'web_search_read',
          args: [],
          kwargs: {
            'domain': [
              ['product_tmpl_id', '=', templateId],
            ],
            'specification': {
              'id': {},
              'name': {},
              'display_name': {},
              'lst_price': {},
              'product_template_variant_value_ids': {
                'fields': {'id': {}, 'name': {}},
              },
              'appointment_type_id': {
                'fields': {
                  'id': {},
                  'name': {},
                  'appointment_duration': {},
                  'message_intro': {},
                },
              },
              'appointment_resource_id': {
                'fields': {'id': {}, 'name': {}},
              },
            },
          },
        );
      }

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      if (records.isNotEmpty) {
        debugPrint(
          '🟢 [OdooApiService] Endpoint 2 returned ${records.length} variants',
        );
        return records.map((item) {
          return ProductVariant.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      // Fallback: search_read on product.product
      final fallbackResponse = await _callKw(
        model: 'product.product',
        method: 'search_read',
        args: [
          [
            ['product_tmpl_id', '=', templateId],
          ],
        ],
        kwargs: {
          'fields': [
            'id',
            'name',
            'display_name',
            'lst_price',
            'appointment_type_id',
            'appointment_resource_id',
            'product_template_variant_value_ids',
          ],
          'limit': 50,
        },
      );

      if (fallbackResponse is List && fallbackResponse.isNotEmpty) {
        debugPrint(
          '🟢 [OdooApiService] Endpoint 2 fallback search_read returned ${fallbackResponse.length} variants',
        );
        return fallbackResponse.map((item) {
          return ProductVariant.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        '🔴 [OdooApiService] Endpoint 2 error for templateId=$templateId: $e',
      );
      return [];
    }
  }

  @override
  Future<ProductVariant?> getVariantById(int productId) async {
    debugPrint(
      '🔵 [OdooApiService] Fetching product.product details for productId=$productId...',
    );
    try {
      final response = await _callKw(
        model: 'product.product',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            ['id', '=', productId],
          ],
          'specification': {
            'id': {},
            'name': {},
            'display_name': {},
            'lst_price': {},
            'product_template_variant_value_ids': {
              'fields': {'id': {}, 'name': {}},
            },
            'appointment_type_id': {
              'fields': {
                'id': {},
                'name': {},
                'appointment_duration': {},
                'message_intro': {},
                'min_schedule_hours': {},
                'max_schedule_days': {},
                'min_cancellation_hours': {},
              },
            },
            'appointment_resource_id': {
              'fields': {'id': {}, 'name': {}, 'capacity': {}},
            },
          },
        },
      );
      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);
      if (records.isNotEmpty) {
        return ProductVariant.fromJson(
          Map<String, dynamic>.from(records.first as Map),
        );
      }
    } catch (e) {
      debugPrint(
        '🔴 [OdooApiService] Error fetching variant by id $productId: $e',
      );
    }
    return null;
  }

  /// ENDPOINT 3: Get Bookable Slots (`appointment.type/get_bookable_slots`)
  @override
  Future<BookableSlotsResult?> getBookableSlots({
    required int appointmentTypeId,
    required String timezone,
    required int resourceId,
    required int askedCapacity,
    required String date,
  }) async {
    try {
      final response = await _callKw(
        model: 'appointment.type',
        method: 'get_bookable_slots',
        args: [
          [appointmentTypeId],
          timezone,
        ],
        kwargs: {
          'resource_id': resourceId,
          'asked_capacity': askedCapacity,
          'date': date,
        },
      );

      if (response is Map<String, dynamic>) {
        return BookableSlotsResult.fromJson(response);
      }
      if (response is Map) {
        return BookableSlotsResult.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      return null;
    } catch (e) {
      print('Endpoint 3 (appointment.type/get_bookable_slots) error: $e');
      return null;
    }
  }

  String _formatToUtcFromJohannesburg(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return trimmed;

    String cleanStr = trimmed;
    if (cleanStr.contains('+02:00')) {
      cleanStr = cleanStr.replaceAll('+02:00', '').trim();
    } else if (RegExp(r'(\+|\-)\d{2}:?\d{2}$').hasMatch(cleanStr)) {
      cleanStr = cleanStr
          .replaceAll(RegExp(r'(\+|\-)\d{2}:?\d{2}$'), '')
          .trim();
    }

    final parsed = DateTime.tryParse(cleanStr.replaceAll(' ', 'T'));
    if (parsed != null) {
      // Subtract 2 hours to convert Johannesburg local time (UTC+2) to UTC for Odoo
      final utcTime = parsed.subtract(const Duration(hours: 2));
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(utcTime);
    }
    return cleanStr;
  }

  /// ENDPOINT 4: Book Appointment (`calendar.event/web_save`)
  @override
  Future<Map<String, dynamic>?> bookAppointment({
    required String name,
    required int appointmentTypeId,
    int? productId,
    required int appointmentBookerId,
    required List<int> partnerIds,
    required String start,
    required String stop,
    double duration = 1.0,
    int? resourceId,
    String? phone,
    String? collectorName,
    String? collectorLicense,
    String? vehicleMake,
    String? vehicleModel,
    List<String>? vehicleImagesBase64,
  }) async {
    try {
      final formattedPartnerIds = partnerIds
          .map(
            (id) => [
              6,
              0,
              [id],
            ],
          )
          .toList();
      int? effectiveProductId = productId;
      int effectiveAppointmentTypeId = appointmentTypeId;
      int? effectiveResourceId = resourceId;

      debugPrint(
        '🔵 [OdooApiService] bookAppointment start with productId=$productId, appointmentTypeId=$appointmentTypeId, resourceId=$resourceId',
      );

      if (effectiveProductId != null) {
        try {
          final prodResp = await _callKw(
            model: 'product.product',
            method: 'search_read',
            args: [
              [
                ['id', '=', effectiveProductId],
              ],
            ],
            kwargs: {
              'fields': [
                'id',
                'name',
                'appointment_type_id',
                'appointment_resource_id',
                'appointment_resource_ids',
              ],
              'limit': 1,
            },
          );
          debugPrint(
            '🔵 [OdooApiService] product.product search_read by ID result: $prodResp',
          );

          Map<String, dynamic>? prodMap;
          if (prodResp is List && prodResp.isNotEmpty) {
            prodMap = Map<String, dynamic>.from(prodResp.first as Map);
          } else {
            final tmplSearch = await _callKw(
              model: 'product.product',
              method: 'search_read',
              args: [
                [
                  ['product_tmpl_id', '=', effectiveProductId],
                ],
              ],
              kwargs: {
                'fields': [
                  'id',
                  'name',
                  'appointment_type_id',
                  'appointment_resource_id',
                  'appointment_resource_ids',
                ],
                'limit': 1,
              },
            );
            debugPrint(
              '🔵 [OdooApiService] product.product search_read by tmpl_id result: $tmplSearch',
            );
            if (tmplSearch is List && tmplSearch.isNotEmpty) {
              prodMap = Map<String, dynamic>.from(tmplSearch.first as Map);
              effectiveProductId = prodMap['id'] as int;
              debugPrint(
                '🟢 [OdooApiService] Mapped product template ID $productId -> variant ID $effectiveProductId',
              );
            }
          }

          if (prodMap != null) {
            final rawAppt = prodMap['appointment_type_id'];
            debugPrint(
              '🟢 [OdooApiService] Raw appointment_type_id from prodMap: $rawAppt (type: ${rawAppt.runtimeType})',
            );
            if (effectiveAppointmentTypeId <= 0) {
              if (rawAppt is Map && rawAppt['id'] is int) {
                effectiveAppointmentTypeId = rawAppt['id'] as int;
              } else if (rawAppt is List && rawAppt.isNotEmpty) {
                final id = rawAppt[0] is int
                    ? rawAppt[0] as int
                    : int.tryParse(rawAppt[0].toString());
                if (id != null) effectiveAppointmentTypeId = id;
              } else if (rawAppt is int) {
                effectiveAppointmentTypeId = rawAppt;
              }
            }

            final rawRes =
                prodMap['appointment_resource_id'] ??
                prodMap['appointment_resource_ids'];
            debugPrint(
              '🟢 [OdooApiService] Raw appointment_resource_id from prodMap: $rawRes (type: ${rawRes.runtimeType})',
            );
            if (effectiveResourceId == null || effectiveResourceId <= 0) {
              if (rawRes is Map && rawRes['id'] is int) {
                effectiveResourceId = rawRes['id'] as int;
              } else if (rawRes is List && rawRes.isNotEmpty) {
                final first = rawRes[0];
                if (first is int) {
                  effectiveResourceId = first;
                } else if (first is Map && first['id'] is int) {
                  effectiveResourceId = first['id'] as int;
                }
              } else if (rawRes is int) {
                effectiveResourceId = rawRes;
              }
            }
            debugPrint(
              '🟢 [OdooApiService] Effective ApptType ID=$effectiveAppointmentTypeId, Resource ID=$effectiveResourceId, Product ID=$effectiveProductId',
            );
          } else {
            debugPrint(
              '🟡 [OdooApiService] prodMap is NULL after variant search for productId=$productId',
            );
          }
        } catch (checkErr, stack) {
          debugPrint(
            '🔴 [OdooApiService] Variant/ApptType lookup check error: $checkErr\n$stack',
          );
        }
      }

      final bookingLines = effectiveResourceId != null
          ? [
              [
                0,
                0,
                {
                  'appointment_resource_id': effectiveResourceId,
                  'capacity_reserved': 1,
                },
              ],
            ]
          : [];

      final formattedImages =
          (vehicleImagesBase64 != null && vehicleImagesBase64.isNotEmpty)
          ? vehicleImagesBase64.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final rawB64 = entry.value;
              final b64 = rawB64.contains(',')
                  ? rawB64.split(',').last
                  : rawB64;
              return [
                0,
                0,
                {
                  'name': 'vehicle_photo_$idx.jpg',
                  'type': 'binary',
                  'datas': b64,
                  'mimetype': 'image/jpeg',
                },
              ];
            }).toList()
          : [];

      final formattedStart = _formatToUtcFromJohannesburg(start);
      String formattedStop = _formatToUtcFromJohannesburg(stop);

      final effectiveDuration = (duration <= 0 || duration == 3.0)
          ? 1.0
          : duration;

      final startUtcDt = DateTime.tryParse(formattedStart.replaceAll(' ', 'T'));
      if (startUtcDt != null) {
        final durationMinutes = (effectiveDuration * 60).round();
        final calcStopDt = startUtcDt.add(Duration(minutes: durationMinutes));
        formattedStop = DateFormat('yyyy-MM-dd HH:mm:ss').format(calcStopDt);
      }

      final payload = {
        'name': name,
        'appointment_type_id': effectiveAppointmentTypeId,
        if (effectiveProductId != null) 'product_id': effectiveProductId,
        'appointment_booker_id': appointmentBookerId,
        'partner_ids': formattedPartnerIds,
        'start': formattedStart,
        'stop': formattedStop,
        'duration': effectiveDuration,
        'booking_line_ids': bookingLines,
        if (phone != null) 'phone': phone,
        if (collectorName != null) 'collector_name': collectorName,
        if (collectorLicense != null) 'collector_license': collectorLicense,
        if (vehicleMake != null) 'vehicle_make': vehicleMake,
        if (vehicleModel != null) 'vehicle_model': vehicleModel,
        'vehicle_images': formattedImages,
      };

      debugPrint('payload: $payload');

      final response = await _callKw(
        model: 'calendar.event',
        method: 'web_save',
        args: [[], payload],
        kwargs: {
          'specification': {
            'id': {},
            'name': {},
            'start': {},
            'stop': {},
            'booking_phone': {},
            'booking_vehicle_make': {},
            'booking_vehicle_model': {},
            'booking_collector_name': {},
            'booking_collector_license': {},
            'opportunity_id': {
              'fields': {'id': {}, 'name': {}},
            },
          },
        },
      );

      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0] as Map);
      }
      return null;
    } catch (e) {
      final errStr = e.toString();
      debugPrint(
        '🔴 [OdooApiService] Endpoint 4 (calendar.event/web_save) error: $errStr',
      );
      rethrow;
    }
  }

  /// ENDPOINT 5: Get User Bookings (`calendar.event/web_search_read`)
  @override
  Future<Map<String, dynamic>> getUserBookings(int partnerId) async {
    try {
      final response = await _callKw(
        model: 'calendar.event',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            '|',
            [
              'partner_ids',
              'in',
              [partnerId],
            ],
            ['appointment_booker_id', '=', partnerId],
          ],
          'specification': {
            'id': {},
            'name': {},
            'start': {},
            'stop': {},
            'duration': {},
            'active': {},
            'appointment_type_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'appointment_resource_ids': {
              'fields': {'id': {}, 'name': {}},
            },
            'booking_phone': {},
            'booking_vehicle_make': {},
            'booking_vehicle_model': {},
            'booking_collector_required': {},
            'booking_collector_name': {},
            'booking_collector_license': {},
            'opportunity_id': {
              'fields': {'id': {}, 'name': {}},
            },
          },
          'order': 'start desc',
        },
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      if (response is List) {
        return {'length': response.length, 'records': response};
      }
      return {'length': 0, 'records': []};
    } catch (e) {
      print('Endpoint 5 (calendar.event/web_search_read) error: $e');
      return {'length': 0, 'records': []};
    }
  }

  /// ENDPOINT 6: Get Specific Booking Details (`calendar.event/web_read`)
  @override
  Future<Map<String, dynamic>?> getBookingDetails(int bookingId) async {
    try {
      final response = await _callKw(
        model: 'calendar.event',
        method: 'web_read',
        args: [
          [bookingId],
        ],
        kwargs: {
          'specification': {
            'id': {},
            'name': {},
            'start': {},
            'stop': {},
            'duration': {},
            'active': {},
            'appointment_type_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'appointment_resource_ids': {
              'fields': {'id': {}, 'name': {}},
            },
            'booking_phone': {},
            'booking_vehicle_make': {},
            'booking_vehicle_model': {},
            'booking_collector_required': {},
            'booking_collector_name': {},
            'booking_collector_license': {},
            'opportunity_id': {
              'fields': {'id': {}, 'name': {}},
            },
          },
        },
      );

      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0] as Map);
      }
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      debugPrint('Endpoint 6 (calendar.event/web_read) error: $e');
      return null;
    }
  }

  /// ENDPOINT 7: Cancel Booking (`calendar.event/action_cancel_meeting`)
  @override
  Future<Map<String, dynamic>?> cancelBooking({
    required int bookingId,
    required List<int> partnerIds,
  }) async {
    try {
      final response = await _callKw(
        model: 'calendar.event',
        method: 'action_cancel_meeting',
        args: [
          [bookingId],
        ],
        kwargs: {'partner_ids': partnerIds},
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'cancelled': true, 'response': response};
    } catch (e) {
      debugPrint('Endpoint 7 (calendar.event/action_cancel_meeting) error: $e');
      return null;
    }
  }

  /// ENDPOINT 8: Get All Projects (`project.project/web_search_read`)
  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await _callKw(
        model: 'project.project',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            ['is_template', '=', false],
          ],
          'specification': {
            'id': {},
            'name': {},
            'task_count': {},
            'label_tasks': {},
          },
          'order': 'name desc',
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      return records.map((item) {
        return ProjectModel.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (e) {
      debugPrint('Endpoint 8 (project.project/web_search_read) error: $e');
      return [];
    }
  }

  /// ENDPOINT 9: Get Project Tasks (`project.task/web_search_read`)
  @override
  Future<List<ProjectTaskModel>> getProjectTasks(int projectId) async {
    try {
      final response = await _callKw(
        model: 'project.task',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            ['project_id', '=', projectId],
            ['display_in_project', '=', true],
          ],
          'specification': {
            'id': {},
            'name': {},
            'priority': {},
            'portal_user_names': {},
            'state': {},
            'stage_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'project_id': {
              'fields': {'id': {}, 'name': {}},
            },
          },
          'order': 'id desc',
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      return records.map((item) {
        return ProjectTaskModel.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    } catch (e) {
      debugPrint('Endpoint 9 (project.task/web_search_read) error: $e');
      return [];
    }
  }

  /// Get Project Task Types/Stages (`project.task.type/web_search_read`)
  @override
  Future<List<ProjectTaskTypeModel>> getProjectTaskTypes(int projectId) async {
    try {
      final response = await _callKw(
        model: 'project.task.type',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            [
              'project_ids',
              'in',
              [projectId],
            ],
          ],
          'specification': {'id': {}, 'name': {}, 'sequence': {}},
          'order': 'sequence desc',
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      return records.map((item) {
        return ProjectTaskTypeModel.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    } catch (e) {
      debugPrint('getProjectTaskTypes error: $e');
      return [];
    }
  }

  /// STEP 13: Get Sent Quotations (`sale.order/web_search_read`)
  @override
  Future<List<Map<String, dynamic>>> getSentQuotations({int? partnerId}) async {
    try {
      final pid = partnerId ?? _partnerId ?? _uid;
      final response = await _callKw(
        model: 'sale.order',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            if (pid != null) ['partner_id', '=', pid],
            [
              'state',
              'in',
              ['sent', 'sale', 'cancel'],
            ],
          ],
          'specification': {
            'id': {},
            'name': {},
            'date_order': {},
            'validity_date': {},
            'amount_untaxed': {},
            'amount_tax': {},
            'amount_total': {},
            'currency_id': {},
            'state': {},
            'is_subscription': {},
            'subscription_state': {},
            'plan_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'next_invoice_date': {},
            'recurring_total': {},
            'partner_id': {
              'fields': {'id': {}, 'name': {}},
            },
          },
          'order': 'date_order desc',
        },
      );
      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);
      return records.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      debugPrint('getSentQuotations error: $e');
      return [];
    }
  }

  /// STEP 14: Get Sale Orders (`sale.order/web_search_read`)
  @override
  Future<List<Map<String, dynamic>>> getSaleOrders({int? partnerId}) async {
    try {
      final pid = partnerId ?? _partnerId ?? _uid;
      final response = await _callKw(
        model: 'sale.order',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': pid != null
              ? [
                  ['partner_id', '=', pid],
                ]
              : [],
          'specification': {
            'id': {},
            'name': {},
            'state': {},
            'amount_total': {},
            'date_order': {},
            'note': {},
            'order_line': {
              'fields': {
                'id': {},
                'name': {},
                'product_id': {
                  'fields': {'id': {}, 'display_name': {}},
                },
                'price_unit': {},
                'product_uom_qty': {},
              },
            },
          },
          'order': 'date_order desc',
        },
      );
      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);
      return records.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      debugPrint('getSaleOrders error: $e');
      return [];
    }
  }

  /// STEP 14b: Get Specific Quotation Details (`sale.order/web_read`)
  @override
  Future<Map<String, dynamic>?> getQuotationDetails(int orderId) async {
    try {
      final response = await _callKw(
        model: 'sale.order',
        method: 'web_read',
        args: [
          [orderId],
        ],
        kwargs: {
          'specification': {
            'id': {},
            'name': {},
            'date_order': {},
            'validity_date': {},
            'amount_untaxed': {},
            'amount_tax': {},
            'amount_total': {},
            'state': {},
            'vehicle_make': {},
            'vehicle_model': {},
            'vehicle_registration': {},
            'service_billing_status': {},
            'is_subscription': {},
            'subscription_state': {},
            'plan_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'start_date': {},
            'end_date': {},
            'next_invoice_date': {},
            'recurring_total': {},
            'order_line': {
              'fields': {
                'product_id': {
                  'fields': {'id': {}, 'display_name': {}},
                },
                'name': {},
                'product_uom_qty': {},
                'price_unit': {},
                'discount': {},
                'price_subtotal': {},
                'price_total': {},
                'recurring_invoice': {},
                'project_id': {
                  'fields': {'id': {}, 'name': {}},
                },
              },
            },
            'access_url': {},
            'access_token': {},
            'warranty_ids': {
              'fields': {
                'id': {},
                'name': {},
                'product_id': {
                  'fields': {'id': {}, 'display_name': {}},
                },
                'vehicle_make': {},
                'vehicle_model': {},
                'vehicle_registration': {},
                'warranty_start': {},
                'warranty_end': {},
                'status': {},
              },
            },
            'vehicle_id': {
              'fields': {
                'id': {},
                'vin': {},
                'make': {},
                'model': {},
                'registration': {},
              },
            },
            'vehicle_history_order_ids': {
              'fields': {
                'id': {},
                'name': {},
                'date_order': {},
                'state': {},
                'amount_total': {},
              },
            },
          },
        },
      );
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first as Map);
      }
      return null;
    } catch (e) {
      debugPrint('getQuotationDetails error: $e');
      return null;
    }
  }

  /// STEP 15: Accept Quotation (`/my/orders/<id>/accept`, verification & RPC fallback)
  @override
  Future<bool> acceptQuotation({
    required int orderId,
    required String name,
    String? signatureBase64,
    String? accessToken,
  }) async {
    debugPrint(
      '🔵 [OdooApiService] acceptQuotation called for orderId=$orderId, name=$name',
    );
    await _ensureInitialized();

    final String cleanSig =
        (signatureBase64 != null && signatureBase64.isNotEmpty)
        ? (signatureBase64.contains(',')
              ? signatureBase64.split(',').last
              : signatureBase64)
        : '';

    String token = accessToken ?? '';
    if (token.isEmpty && orderId > 0) {
      try {
        final details = await getQuotationDetails(orderId);
        if (details != null &&
            details['access_token'] is String &&
            (details['access_token'] as String).isNotEmpty) {
          token = details['access_token'];
        }
      } catch (_) {}
    }

    // Helper to check if quotation state was changed to sale/done in Odoo
    Future<bool> isOrderConfirmedInOdoo() async {
      try {
        final details = await getQuotationDetails(orderId);
        if (details != null) {
          final state = details['state']?.toString().toLowerCase() ?? '';
          debugPrint(
            '🔍 [OdooApiService] Checked order $orderId state in Odoo: "$state"',
          );
          if (state == 'sale' ||
              state == 'done' ||
              (state.isNotEmpty && state != 'draft' && state != 'sent')) {
            return true;
          }
        }
      } catch (e) {
        debugPrint(
          '⚠️ [OdooApiService] Failed to verify order state in Odoo: $e',
        );
      }
      return false;
    }

    // 1. Primary Strategy: Post JSON-RPC payload directly to dynamic /my/orders/$orderId/accept
    if (_dio != null && orderId > 0) {
      try {
        String portalUrl = '/my/orders/$orderId/accept';
        if (token.isNotEmpty) {
          portalUrl += '?access_token=$token';
        }
        debugPrint(
          '🔵 [OdooApiService] Posting JSON-RPC payload to: $portalUrl',
        );

        final payload = {
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "name": name,
            "signature": cleanSig,
            if (token.isNotEmpty) "access_token": token,
          },
        };

        final response = await _dio!.post(
          portalUrl,
          data: jsonEncode(payload),
          options: Options(
            headers: {'Content-Type': 'application/json'},
            followRedirects: true,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(
              seconds: 90,
            ), // Increased receive timeout to 90s
          ),
        );

        debugPrint(
          '🟢 [OdooApiService] Portal accept response status: ${response.statusCode}, body: ${response.data}',
        );

        if (response.data is Map && response.data['result'] != null) {
          final result = response.data['result'];
          if (result is Map) {
            final bool success =
                result['success'] == true ||
                result['status'] == 'accepted' ||
                result['redirect_url'] != null ||
                result['force_refresh'] == true;
            if (success) {
              debugPrint(
                '🟢 [OdooApiService] Quotation $orderId successfully accepted! Result: $result',
              );
              return true;
            }
          } else if (result == true) {
            debugPrint(
              '🟢 [OdooApiService] Quotation $orderId successfully accepted! Result: true',
            );
            return true;
          }
        }
        if (response.statusCode == 200) {
          // Verify if order status updated to confirmed in Odoo
          if (await isOrderConfirmedInOdoo()) {
            debugPrint(
              '🟢 [OdooApiService] Verified order state in Odoo is confirmed after portal accept 200',
            );
            return true;
          }
        }
      } catch (portalErr) {
        debugPrint(
          '⚠️ [OdooApiService] Direct portal accept URL failed/timed out ($portalErr). Checking if order was confirmed during request...',
        );
        if (await isOrderConfirmedInOdoo()) {
          debugPrint(
            '🟢 [OdooApiService] Order $orderId WAS confirmed in Odoo despite client timeout!',
          );
          return true;
        }
      }
    }

    // 2. Secondary Strategy: RPC action_confirm
    try {
      await _callKw(
        model: 'sale.order',
        method: 'action_confirm',
        args: [
          [orderId],
        ],
        kwargs: {
          if (name.isNotEmpty) 'name': name,
          if (cleanSig.isNotEmpty) 'signature': cleanSig,
        },
      );
      debugPrint(
        '🟢 [OdooApiService] acceptQuotation action_confirm successful for orderId=$orderId',
      );
      return true;
    } catch (e) {
      debugPrint(
        '⚠️ [OdooApiService] action_confirm not allowed or failed ($e). Posting acceptance message...',
      );
      try {
        await _callKw(
          model: 'sale.order',
          method: 'message_post',
          args: [
            [orderId],
          ],
          kwargs: {
            'body':
                '<p><b>Quotation Accepted & Digitally Signed</b><br/>Customer Name: $name</p>',
            'message_type': 'comment',
            'subtype_xmlid': 'mail.mt_comment',
          },
        );
        debugPrint(
          '🟢 [OdooApiService] Posted acceptance message to sale.order $orderId',
        );
      } catch (msgErr) {
        debugPrint('⚠️ [OdooApiService] Could not post message: $msgErr');
      }

      // Check if order was confirmed in Odoo despite action_confirm error
      if (await isOrderConfirmedInOdoo()) {
        debugPrint(
          '🟢 [OdooApiService] Verified order $orderId is confirmed in Odoo.',
        );
        return true;
      }

      debugPrint(
        '🔴 [OdooApiService] Quotation $orderId could not be confirmed in Odoo.',
      );
      return false;
    }
  }

  int? _registeredTokenId;

  /// STEP 15b: Register Device Token (`timeless.device.token`)
  @override
  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
    String? previousToken,
  }) async {
    try {
      final cleanPlatform = platform.toLowerCase() == 'ios' ? 'ios' : 'android';
      debugPrint(
        '🔵 [OdooApiService] Registering FCM Device Token (platform: $cleanPlatform, previousToken: $previousToken)...',
      );

      final Map<String, dynamic> kwargs = {};
      if (previousToken != null && previousToken.isNotEmpty) {
        kwargs['previous_token'] = previousToken;
      }

      // Call custom registration RPC method timeless.device.token/register_device directly
      final res = await _callKw(
        model: 'timeless.device.token',
        method: 'register_device',
        args: [token, cleanPlatform],
        kwargs: kwargs,
      );

      if (res != null && res != false) {
        debugPrint(
          '🟢 [OdooApiService] registerDeviceToken via register_device success response: $res',
        );

        int? deviceId;
        if (res is Map) {
          if (res['device_id'] is int) {
            deviceId = res['device_id'] as int;
          } else if (res['id'] is int) {
            deviceId = res['id'] as int;
          }
        } else if (res is int) {
          deviceId = res;
        }

        if (deviceId != null && deviceId > 0) {
          _registeredTokenId = deviceId;
          try {
            await _storage.write(
              key: 'registered_token_id',
              value: deviceId.toString(),
            );
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('registered_token_id', deviceId);
          } catch (_) {}
        }

        // Cache FCM token locally for token refresh checks
        try {
          await _storage.write(key: 'cached_fcm_token', value: token);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_fcm_token', token);
        } catch (_) {}

        if (res is Map && res['success'] == false) {
          debugPrint(
            '🟡 [OdooApiService] register_device returned success: false',
          );
          return false;
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('🔴 [OdooApiService] registerDeviceToken error: $e');
      return false;
    }
  }

  /// STEP 15c: Get Device Tokens (`timeless.device.token/search_read`)
  @override
  Future<List<Map<String, dynamic>>> getDeviceTokens() async {
    try {
      final response = await _callKw(
        model: 'timeless.device.token',
        method: 'search_read',
        args: [
          [
            '|',
            ['active', '=', true],
            ['active', '=', false],
          ],
        ],
        kwargs: {
          'fields': [
            'id',
            'partner_id',
            'user_id',
            'platform',
            'token',
            'active',
          ],
        },
      );
      final List records = response is List ? response : [];
      return records.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getDeviceTokens error: $e');
      return [];
    }
  }

  /// STEP 15d: Get User Notifications (`timeless.notification/web_search_read`)
  @override
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int? partnerId,
  }) async {
    try {
      final pid = partnerId ?? _partnerId ?? _uid;

      // 1. Primary: web_search_read on timeless.notification using exact Odoo payload
      try {
        final response = await _callKw(
          model: 'timeless.notification',
          method: 'web_search_read',
          args: [],
          kwargs: {
            'domain': pid != null
                ? [
                    '|',
                    ['partner_id', '=', pid],
                    ['partner_id', '=', false],
                  ]
                : [],
            'specification': {
              'notification_type': {},
              'title': {},
              'message': {},
              'res_model': {},
              'res_id': {},
              'sale_order_id': {
                'fields': {'id': {}, 'display_name': {}},
              },
              'is_read': {},
              'create_date': {},
            },
            'order': 'create_date desc',
          },
        );

        final List records =
            (response is Map && response.containsKey('records'))
            ? (response['records'] as List)
            : (response is List ? response : []);

        if (records.isNotEmpty) {
          debugPrint(
            '🟢 [OdooApiService] getUserNotifications web_search_read returned ${records.length} records',
          );
          return records
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
        }
      } catch (e) {
        debugPrint(
          '🟡 [OdooApiService] timeless.notification web_search_read with domain failed: $e',
        );
        // Fallback 1b: Try domain [] without partner_id restriction
        try {
          final response = await _callKw(
            model: 'timeless.notification',
            method: 'web_search_read',
            args: [],
            kwargs: {
              'domain': [],
              'specification': {
                'notification_type': {},
                'title': {},
                'message': {},
                'res_model': {},
                'res_id': {},
                'sale_order_id': {
                  'fields': {'id': {}, 'display_name': {}},
                },
                'is_read': {},
                'create_date': {},
              },
              'order': 'create_date desc',
            },
          );

          final List records =
              (response is Map && response.containsKey('records'))
              ? (response['records'] as List)
              : (response is List ? response : []);

          if (records.isNotEmpty) {
            debugPrint(
              '🟢 [OdooApiService] getUserNotifications web_search_read domain [] returned ${records.length} records',
            );
            return records
                .map((r) => Map<String, dynamic>.from(r as Map))
                .toList();
          }
        } catch (e2) {
          debugPrint(
            '🟡 [OdooApiService] timeless.notification web_search_read domain [] failed: $e2',
          );
        }
      }

      // 2. Fallback: search_read on timeless.notification
      try {
        final response = await _callKw(
          model: 'timeless.notification',
          method: 'search_read',
          args: [[]],
          kwargs: {
            'fields': [
              'id',
              'notification_type',
              'title',
              'message',
              'res_model',
              'res_id',
              'sale_order_id',
              'is_read',
              'create_date',
            ],
            'order': 'create_date desc',
          },
        );

        final List records =
            (response is Map && response.containsKey('records'))
            ? (response['records'] as List)
            : (response is List ? response : []);

        if (records.isNotEmpty) {
          debugPrint(
            '🟢 [OdooApiService] getUserNotifications search_read returned ${records.length} records',
          );
          return records
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
        }
      } catch (e) {
        debugPrint(
          '🟡 [OdooApiService] timeless.notification search_read fallback: $e',
        );
      }

      // 3. Fallback to mail.message model
      if (pid != null) {
        try {
          final response = await _callKw(
            model: 'mail.message',
            method: 'search_read',
            args: [
              [
                [
                  'partner_ids',
                  'in',
                  [pid],
                ],
              ],
            ],
            kwargs: {
              'fields': ['id', 'subject', 'body', 'date', 'model', 'res_id'],
              'order': 'id desc',
            },
          );

          final List records =
              (response is Map && response.containsKey('records'))
              ? (response['records'] as List)
              : (response is List ? response : []);

          if (records.isNotEmpty) {
            return records
                .map((r) => Map<String, dynamic>.from(r as Map))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getUserNotifications error: $e');
      return [];
    }
  }

  /// STEP 15e: Get Notification Detail (`timeless.notification` or `mail.message`)
  @override
  Future<Map<String, dynamic>?> getNotificationDetail(
    int notificationId,
  ) async {
    try {
      // 1. Try timeless.notification
      try {
        final response = await _callKw(
          model: 'timeless.notification',
          method: 'search_read',
          args: [
            [
              ['id', '=', notificationId],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'notification_type',
              'title',
              'message',
              'res_model',
              'res_id',
              'sale_order_id',
              'is_read',
              'create_date',
            ],
          },
        );

        final List records =
            (response is Map && response.containsKey('records'))
            ? (response['records'] as List)
            : (response is List ? response : []);

        if (records.isNotEmpty) {
          return Map<String, dynamic>.from(records.first as Map);
        }
      } catch (_) {}

      // 2. Fallback to mail.message
      try {
        final response = await _callKw(
          model: 'mail.message',
          method: 'search_read',
          args: [
            [
              ['id', '=', notificationId],
            ],
          ],
          kwargs: {
            'fields': ['id', 'subject', 'body', 'date', 'model', 'res_id'],
          },
        );
        if (response is List && response.isNotEmpty) {
          return Map<String, dynamic>.from(response.first as Map);
        }
      } catch (_) {}

      return null;
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getNotificationDetail error: $e');
      return null;
    }
  }

  /// STEP 16: Get Company Location Details (`res.company/web_read`)
  @override
  Future<Map<String, dynamic>?> getCompanyLocationDetails() async {
    try {
      final response = await _callKw(
        model: 'res.company',
        method: 'web_read',
        args: [
          [1],
        ],
        kwargs: {
          'specification': {
            'id': {},
            'name': {},
            'phone': {},
            'email': {},
            'website': {},
            'street': {},
            'street2': {},
            'city': {},
            'zip': {},
            'state_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'country_id': {
              'fields': {'id': {}, 'name': {}},
            },
            'latitude': {},
            'longitude': {},
          },
        },
      );
      final List records = response is List ? response : [];
      if (records.isNotEmpty) {
        final comp = Map<String, dynamic>.from(records.first as Map);
        debugPrint(
          '🟢 [OdooApiService] Company location details: name=${comp['name']}, lat=${comp['latitude']}, lng=${comp['longitude']}',
        );
        return comp;
      }
      return null;
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getCompanyLocationDetails error: $e');
      return null;
    }
  }

  @override
  Future<List<Booking>> getBookings(String customerId) async {
    try {
      dynamic response;
      final partnerId = int.tryParse(customerId) ?? _uid;
      try {
        response = await _callKw(
          model: 'sale.order',
          method: 'search_read',
          args: [
            partnerId != null
                ? [
                    ['partner_id', '=', partnerId],
                  ]
                : [],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'state',
              'amount_total',
              'date_order',
              'note',
              'vehicle_name',
              'vehicle_plate',
              'technician_name',
              'technician_avatar',
              'before_images',
              'after_images',
            ],
            'order': 'date_order desc',
          },
        );
      } catch (e) {
        debugPrint(
          'sale.order custom search_read failed ($e). Falling back to standard fields.',
        );
        response = await _callKw(
          model: 'sale.order',
          method: 'search_read',
          args: [
            partnerId != null
                ? [
                    ['partner_id', '=', partnerId],
                  ]
                : [],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'state',
              'amount_total',
              'date_order',
              'note',
            ],
            'order': 'date_order desc',
          },
        );
      }

      List<Booking> bookings = [];
      if (response is List) {
        for (var order in response) {
          final orderMap = Map<String, dynamic>.from(order as Map);
          final serviceJson = {
            'id': '1',
            'name': orderMap['name'] ?? 'Premium Detail',
            'lst_price': orderMap['amount_total'],
            'categ_id': [1, 'Full Packages'],
          };
          final service = DetailService.fromOdooJson(serviceJson);
          bookings.add(Booking.fromOdooJson(orderMap, service));
        }
      }
      return bookings;
    } catch (e) {
      debugPrint('Odoo getBookings error: $e');
      return [];
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      final orderId = await _callKw(
        model: 'sale.order',
        method: 'create',
        args: [
          {
            'partner_id': _uid ?? 1,
            'date_order': DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(booking.bookingDateTime),
            'note': booking.notes,
            'vehicle_name': booking.vehicleName,
            'vehicle_plate': booking.vehicleLicensePlate,
          },
        ],
        kwargs: {},
      );

      await _callKw(
        model: 'sale.order.line',
        method: 'create',
        args: [
          {
            'order_id': orderId,
            'product_id': booking.service.odooProductId ?? 1,
            'product_uom_qty': 1.0,
            'price_unit': booking.service.price,
          },
        ],
        kwargs: {},
      );

      return booking.copyWith(id: orderId.toString(), odooSaleOrderId: orderId);
    } catch (e) {
      print('Odoo createBooking error: $e');
      rethrow;
    }
  }

  @override
  Future<Booking?> getLiveTrackingBooking(String bookingId) async {
    try {
      final id = int.tryParse(bookingId);
      if (id == null) return null;

      dynamic response;
      try {
        response = await _callKw(
          model: 'sale.order',
          method: 'read',
          args: [
            [id],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'state',
              'amount_total',
              'date_order',
              'note',
              'vehicle_name',
              'vehicle_plate',
              'technician_name',
              'technician_avatar',
              'before_images',
              'after_images',
            ],
          },
        );
      } catch (e) {
        debugPrint(
          'sale.order custom read failed ($e). Falling back to standard fields.',
        );
        response = await _callKw(
          model: 'sale.order',
          method: 'read',
          args: [
            [id],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'state',
              'amount_total',
              'date_order',
              'note',
            ],
          },
        );
      }

      if (response == null || (response is List && response.isEmpty)) {
        // Fallback: search for latest sale.order for the current customer/partner
        try {
          final partnerId = _partnerId ?? _uid;
          final fallbackSearch = await _callKw(
            model: 'sale.order',
            method: 'search_read',
            args: [
              partnerId != null
                  ? [
                      ['partner_id', '=', partnerId],
                    ]
                  : [],
            ],
            kwargs: {
              'fields': [
                'id',
                'name',
                'state',
                'amount_total',
                'date_order',
                'note',
              ],
              'order': 'date_order desc',
              'limit': 1,
            },
          );
          if (fallbackSearch is List && fallbackSearch.isNotEmpty) {
            response = fallbackSearch;
          }
        } catch (_) {}
      }

      if (response == null || (response is List && response.isEmpty))
        return null;
      final orderMap = Map<String, dynamic>.from(
        (response is List ? response[0] : response) as Map,
      );

      final service = DetailService(
        id: '1',
        name: orderMap['name']?.toString() ?? 'Signature Detailing',
        description: 'Multi-stage paint correction & wax protection.',
        price: (orderMap['amount_total'] as num?)?.toDouble() ?? 299.99,
        durationHours: 4.0,
        imageUrl: '',
        category: 'Signature Packages',
        whatsIncluded: [],
      );

      return Booking.fromOdooJson(orderMap, service);
    } catch (e) {
      debugPrint('Odoo getLiveTrackingBooking error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      await _ensureInitialized();
      final targetId = int.tryParse(customerId) ?? _partnerId ?? _uid;
      if (targetId == null) {
        return _savedUserInfo;
      }

      try {
        final response = await _callKw(
          model: 'res.partner',
          method: 'read',
          args: [
            [targetId],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'email',
              'phone',
              'street',
              'city',
              'zip',
              'image_1920',
            ],
          },
        );
        if ((response as List).isNotEmpty) {
          final data = Map<String, dynamic>.from(response[0] as Map);
          _savedUserInfo = data;
          await _persistProfileFields(data);
          return data;
        }
      } catch (e) {
        print(
          'res.partner read restricted: $e. Using user session info / res.users fallback.',
        );
        try {
          if (_uid != null) {
            final userResp = await _callKw(
              model: 'res.users',
              method: 'read',
              args: [
                [_uid],
              ],
              kwargs: {
                'fields': [
                  'id',
                  'name',
                  'login',
                  'email',
                  'phone',
                  'partner_id',
                  'image_1920',
                ],
              },
            );
            if ((userResp as List).isNotEmpty) {
              final u = userResp[0] as Map<String, dynamic>;
              final fetchedImg = u['image_1920'];
              final savedImg = await _storage.read(key: 'user_image');
              final validImg =
                  (fetchedImg != null &&
                      fetchedImg != false &&
                      fetchedImg is String &&
                      fetchedImg.isNotEmpty &&
                      fetchedImg != 'false')
                  ? fetchedImg
                  : (savedImg ?? _savedUserInfo?['image_1920']);

              _savedUserInfo = {
                'id': _partnerId ?? _uid,
                'name': u['name'] ?? _savedUserInfo?['name'] ?? '',
                'email':
                    u['email'] ?? u['login'] ?? _savedUserInfo?['email'] ?? '',
                'phone': u['phone'] ?? _savedUserInfo?['phone'] ?? '',
                if (validImg != null) 'image_1920': validImg,
              };
              await _persistProfileFields(_savedUserInfo!);
              return _savedUserInfo;
            }
          }
        } catch (_) {}
      }

      return _savedUserInfo;
    } catch (e) {
      print('Odoo getCustomerProfile error: $e');
      return _savedUserInfo;
    }
  }

  Future<void> _persistProfileFields(Map<String, dynamic> data) async {
    try {
      final name = data['name'];
      final email = data['email'];
      final phone = data['phone'];
      final img = data['image_1920'] ?? data['image_128'];
      if (name is String && name.isNotEmpty) {
        await _storage.write(key: 'user_name', value: name);
      }
      if (email is String && email.isNotEmpty) {
        await _storage.write(key: 'user_email', value: email);
      }
      if (phone is String && phone.isNotEmpty) {
        await _storage.write(key: 'user_phone', value: phone);
      }
      if (img is String && img.isNotEmpty && img != 'false') {
        await _storage.write(key: 'user_image', value: img);
      }
    } catch (_) {}
  }

  @override
  Future<bool> updateCustomerProfile({
    required String customerId,
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      await _ensureInitialized();
      final partnerId = int.tryParse(customerId) ?? _partnerId ?? _uid ?? 1;

      final Map<String, dynamic> writeData = {};
      if (name != null && name.isNotEmpty) writeData['name'] = name;
      if (phone != null && phone.isNotEmpty) writeData['phone'] = phone;
      if (email != null && email.isNotEmpty) writeData['email'] = email;

      if (writeData.isEmpty) return true;

      final response = await _callKw(
        model: 'res.partner',
        method: 'write',
        args: [
          [partnerId],
          writeData,
        ],
        kwargs: {},
      );

      return response == true;
    } catch (e) {
      debugPrint('Odoo updateCustomerProfile error: $e');
      return false;
    }
  }

  @override
  Future<bool> uploadProfileImage(
    String customerId,
    Uint8List imageBytes,
  ) async {
    try {
      await _ensureInitialized();
      final partnerId = int.tryParse(customerId) ?? _partnerId ?? _uid ?? 1;
      final base64Image = base64Encode(imageBytes);

      // Save locally to storage immediately so user picture is preserved locally
      await _storage.write(key: 'user_image', value: base64Image);
      if (_savedUserInfo != null) {
        _savedUserInfo!['image_1920'] = base64Image;
      } else {
        _savedUserInfo = {'image_1920': base64Image};
      }

      final response = await _callKw(
        model: 'res.partner',
        method: 'write',
        args: [
          [partnerId],
          {'image_1920': base64Image},
        ],
        kwargs: {},
      );

      return response == true;
    } catch (e) {
      debugPrint('Odoo uploadProfileImage error: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAccount() async {
    try {
      await _ensureInitialized();
      final partnerId = _partnerId ?? _uid;
      bool success = false;

      if (partnerId != null) {
        try {
          final partnerResp = await _callKw(
            model: 'res.partner',
            method: 'write',
            args: [
              [partnerId],
              {'active': false},
            ],
            kwargs: {},
          );
          if (partnerResp == true) success = true;
        } catch (e) {
          debugPrint('Odoo deleteAccount via res.partner failed: $e');
        }
      }

      if (success) {
        try {
          await logout();
        } catch (_) {}
      }
      return success;
    } catch (e) {
      debugPrint('Odoo deleteAccount error: $e');
      return false;
    }
  }

  @override
  Future<bool> clearProfilePicture(String customerId) async {
    try {
      await _ensureInitialized();
      final partnerId = int.tryParse(customerId) ?? _partnerId ?? _uid ?? 1;

      final response = await _callKw(
        model: 'res.partner',
        method: 'write',
        args: [
          [partnerId],
          {'image_1920': false},
        ],
        kwargs: {},
      );

      return response == true;
    } catch (e) {
      debugPrint('Odoo clearProfilePicture error: $e');
      return false;
    }
  }

  @override
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    debugPrint('🔵 Attempting password $oldPassword $newPassword');
    await _ensureInitialized();
    if (_dio == null) throw Exception('Not authenticated');

    try {
      final response = await _dio!.post(
        '/web/dataset/call_kw',
        data: {
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "res.users",
            "method": "change_password",
            "args": [oldPassword, newPassword],
            "kwargs": {},
          },
        },
      );

      return response.data['error'] == null;
    } catch (e) {
      debugPrint("Change password error: $e");
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getInvoiceDetails(int invoiceId) async {
    debugPrint(
      '🔵 [OdooApiService] getInvoiceDetails called for invoiceId=$invoiceId',
    );
    try {
      await _ensureInitialized();
      final res = await _callKw(
        model: 'account.move',
        method: 'web_read',
        args: [
          [invoiceId],
        ],
        kwargs: {
          'specification': {
            'id': {},
            'name': {},
            'invoice_date': {},
            'invoice_date_due': {},
            'state': {},
            'payment_state': {},
            'amount_untaxed': {},
            'amount_tax': {},
            'amount_total': {},
            'amount_residual': {},
            'currency_id': {},
            'timeless_is_down_payment_invoice': {},
            'timeless_content_snapshot': {},
            'timeless_payment_summary': {},
            'access_url': {},
            'access_token': {},
            'invoice_line_ids': {
              'fields': {
                'name': {},
                'quantity': {},
                'price_unit': {},
                'price_subtotal': {},
                'price_total': {},
              },
            },
          },
        },
      );

      if (res is List && res.isNotEmpty) {
        debugPrint(
          '🟢 [OdooApiService] getInvoiceDetails success for invoiceId=$invoiceId',
        );
        return Map<String, dynamic>.from(res[0]);
      }
      return null;
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getInvoiceDetails error: $e');
      return null;
    }
  }

  /// STEP 18: Get User Invoices (`account.move/web_search_read`)
  @override
  Future<List<Map<String, dynamic>>> getUserInvoices({int? partnerId}) async {
    try {
      final pid = partnerId ?? _partnerId ?? _uid;
      if (pid == null) {
        debugPrint('⚠️ [OdooApiService] partnerId is null for getUserInvoices');
        return [];
      }
      debugPrint(
        '🔵 [OdooApiService] getUserInvoices called for partnerId=$pid',
      );
      final response = await _callKw(
        model: 'account.move',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [
            ['move_type', '=', 'out_invoice'],
            ['state', '!=', 'draft'],
            ['partner_id', '=', pid],
          ],
          'specification': {
            'id': {},
            'name': {},
            'invoice_date': {},
            'state': {},
            'amount_total': {},
            'amount_residual': {},
            'payment_state': {},
            'timeless_is_down_payment_invoice': {},
          },
          'order': 'invoice_date desc',
        },
      );
      final List records = (response is Map && response['records'] is List)
          ? response['records'] as List
          : [];
      debugPrint(
        '🟢 [OdooApiService] getUserInvoices returned ${records.length} records',
      );
      return records.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      debugPrint('🔴 [OdooApiService] getUserInvoices error: $e');
      return [];
    }
  }
}
