import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/bookable_slot_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

abstract class BaseOdooService {
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

  // Mobile API Guide Endpoints (1-9)
  Future<List<DetailService>> getServicesFromProductTemplate();
  Future<List<ProductVariant>> getServiceDetailsWithVariants(int templateId);
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
        receiveTimeout: const Duration(seconds: 30),
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
      final response = await _dio!.post(
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
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final error = response.data['error'];
      if (error != null) {
        throw Exception(
          error['data']?['message'] ??
              error['message'] ??
              'Odoo JSON-RPC Error',
        );
      }

      return response.data['result'];
    } catch (e) {
      print('Odoo call_kw error on $model/$method: $e');
      rethrow;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    print('Odoo login attempt: URL=$baseUrl, DB=$db, Login=$email');
    try {
      await _ensureInitialized();
      await _cookieJar?.deleteAll();

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

        // Secure save credentials for future auto logins
        await _storage.write(key: 'instance_url', value: baseUrl);
        await _storage.write(key: 'database', value: db);
        await _storage.write(key: 'username', value: email);
        await _storage.write(key: 'password', value: password);
        await _storage.write(key: 'is_logged_in', value: 'true');
        await _storage.write(key: 'uid', value: _uid.toString());
        if (_partnerId != null) {
          await _storage.write(key: 'partner_id', value: _partnerId.toString());
        }
        await _storage.write(key: 'session_id', value: _sessionId ?? '');
        await _storage.write(key: 'user_name', value: userName);
        await _storage.write(key: 'user_email', value: email);
        await _storage.write(key: 'user_phone', value: userPhone);

        return true;
      }
      print(
        'Odoo authentication failed: Invalid username or password (result is null/false).',
      );
      return false;
    } catch (e) {
      print('Odoo authenticate caught exception: $e');
      return false;
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
  Future<void> logout() async {
    try {
      await _clearSession();
      _dio = null;
    } catch (e) {
      print('Odoo logout error: $e');
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    try {
      await _ensureInitialized();

      final savedUid = await _storage.read(key: 'uid');
      final isLoggedInFlag = await _storage.read(key: 'is_logged_in');
      final savedEmail =
          await _storage.read(key: 'username') ??
          await _storage.read(key: 'user_email');
      final savedPassword = await _storage.read(key: 'password');

      if ((savedUid == null || savedUid.isEmpty) &&
          isLoggedInFlag != 'true' &&
          (savedEmail == null || savedEmail.isEmpty)) {
        return false;
      }

      if (savedUid != null && savedUid.isNotEmpty) {
        _uid = int.tryParse(savedUid);
      }
      final savedPartnerId = await _storage.read(key: 'partner_id');
      if (savedPartnerId != null && savedPartnerId.isNotEmpty) {
        _partnerId = int.tryParse(savedPartnerId);
      }
      _sessionId = await _storage.read(key: 'session_id');

      final savedName = await _storage.read(key: 'user_name');
      final savedPhone = await _storage.read(key: 'user_phone');
      final savedImage = await _storage.read(key: 'user_image');
      if (savedName != null || savedEmail != null) {
        _savedUserInfo = {
          'id': _partnerId ?? _uid ?? 1,
          'name': savedName ?? 'Customer',
          'email': savedEmail ?? '',
          'phone': savedPhone ?? '',
          if (savedImage != null && savedImage.isNotEmpty)
            'image_1920': savedImage,
        };
      }

      // 1. If password and email are saved, attempt background re-authentication to refresh session cookies with 15s timeout
      if (savedEmail != null &&
          savedPassword != null &&
          savedEmail.isNotEmpty &&
          savedPassword.isNotEmpty) {
        try {
          final success = await login(
            savedEmail,
            savedPassword,
          ).timeout(const Duration(seconds: 15), onTimeout: () => false);
          if (success) {
            return true;
          }
        } catch (e) {
          debugPrint('Silent re-auth timeout or error: $e');
        }
      }

      // 2. Try querying session info from Odoo server directly
      try {
        final sessionResp = await _dio!.post(
          '/web/session/get_session_info',
          data: {'jsonrpc': '2.0', 'method': 'call', 'params': {}},
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        final sessionResult = sessionResp.data['result'];
        if (sessionResult != null &&
            sessionResult['uid'] != null &&
            sessionResult['uid'] != false) {
          return true;
        }
      } catch (_) {}

      // PERSISTENCE FIX: If stored credentials/UID exist, user IS logged in!
      // Return true so user bypasses onboarding and goes straight to dashboard.
      if ((_uid != null ||
              _savedUserInfo != null ||
              isLoggedInFlag == 'true' ||
              savedEmail != null) &&
          isLoggedInFlag != 'false') {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
      final savedUid = await _storage.read(key: 'uid');
      final isLoggedInFlag = await _storage.read(key: 'is_logged_in');
      final savedEmail = await _storage.read(key: 'username');
      if ((savedUid != null && savedUid.isNotEmpty) ||
          isLoggedInFlag == 'true' ||
          (savedEmail != null && savedEmail.isNotEmpty)) {
        if (savedUid != null) _uid = int.tryParse(savedUid);
        return true;
      }
      return false;
    }
  }

  Future<void> _clearSession() async {
    try {
      await _cookieJar?.deleteAll();
      await _storage.deleteAll();
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
          args: [
            [],
          ],
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
          args: [
            [],
          ],
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
  // MOBILE API INTEGRATION GUIDE ENDPOINTS (1 to 9)
  // =========================================================================

  /// ENDPOINT 1: Get Main Services (`product.template/web_search_read`)
  @override
  Future<List<DetailService>> getServicesFromProductTemplate() async {
    debugPrint('🔵 [OdooApiService] Calling product.template/web_search_read...');
    try {
      final response = await _callKw(
        model: 'product.template',
        method: 'web_search_read',
        args: [],
        kwargs: {
          'domain': [],
          'specification': {
            'id': {},
            'name': {},
            'list_price': {},
            'currency_id': {},
            'product_variant_count': {},
          },
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      if (records.isNotEmpty) {
        debugPrint('🟢 [OdooApiService] web_search_read returned ${records.length} records');
        return records.map((item) {
          return DetailService.fromOdooJson(Map<String, dynamic>.from(item as Map));
        }).toList();
      }

      debugPrint('🟡 [OdooApiService] web_search_read returned 0 records. Trying getServices()...');
      final fallbackServices = await getServices();
      if (fallbackServices.isNotEmpty) {
        return fallbackServices;
      }
      return _getFallbackServices();
    } catch (e) {
      debugPrint('🔴 [OdooApiService] Endpoint 1 error: $e. Using fallback services');
      return getServices();
    }
  }

  /// ENDPOINT 2: Get Service Details with Variants (`product.product/web_search_read`)
  @override
  Future<List<ProductVariant>> getServiceDetailsWithVariants(int templateId) async {
    debugPrint('🔵 [OdooApiService] Calling Endpoint 2 (product.product/web_search_read) for templateId=$templateId...');
    try {
      final response = await _callKw(
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
              'fields': {
                'id': {},
                'name': {},
              },
            },
            'appointment_type_id': {
              'fields': {
                'id': {},
                'name': {},
                'appointment_duration': {},
                'message_intro': {},
              },
            },
          },
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      if (records.isNotEmpty) {
        debugPrint('🟢 [OdooApiService] Endpoint 2 returned ${records.length} variants');
        return records.map((item) {
          return ProductVariant.fromJson(Map<String, dynamic>.from(item as Map));
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
          'fields': ['id', 'name', 'display_name', 'lst_price'],
          'limit': 50,
        },
      );

      if (fallbackResponse is List && fallbackResponse.isNotEmpty) {
        debugPrint('🟢 [OdooApiService] Endpoint 2 fallback search_read returned ${fallbackResponse.length} variants');
        return fallbackResponse.map((item) {
          return ProductVariant.fromJson(Map<String, dynamic>.from(item as Map));
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('🔴 [OdooApiService] Endpoint 2 error for templateId=$templateId: $e');
      return [];
    }
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
        return BookableSlotsResult.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      print('Endpoint 3 (appointment.type/get_bookable_slots) error: $e');
      return null;
    }
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
      final formattedPartnerIds = partnerIds.map((id) => [6, 0, [id]]).toList();
      final bookingLines = resourceId != null
          ? [
              [
                0,
                0,
                {
                  'appointment_resource_id': resourceId,
                  'capacity_reserved': 1,
                }
              ]
            ]
          : [];

      final formattedImages = (vehicleImagesBase64 != null && vehicleImagesBase64.isNotEmpty)
          ? vehicleImagesBase64.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final rawB64 = entry.value;
              final b64 = rawB64.contains(',') ? rawB64.split(',').last : rawB64;
              return [
                0,
                0,
                {
                  'name': 'vehicle_photo_$idx.jpg',
                  'type': 'binary',
                  'datas': b64,
                  'mimetype': 'image/jpeg',
                }
              ];
            }).toList()
          : [];

      final payload = {
        'name': name,
        'appointment_type_id': appointmentTypeId,
        if (productId != null) 'product_id': productId,
        'appointment_booker_id': appointmentBookerId,
        'partner_ids': formattedPartnerIds,
        'start': start,
        'stop': stop,
        'duration': duration,
        'booking_line_ids': bookingLines,
        if (phone != null) 'phone': phone,
        if (collectorName != null) 'collector_name': collectorName,
        if (collectorLicense != null) 'collector_license': collectorLicense,
        if (vehicleMake != null) 'vehicle_make': vehicleMake,
        if (vehicleModel != null) 'vehicle_model': vehicleModel,
        'vehicle_images': formattedImages,
      };

      final response = await _callKw(
        model: 'calendar.event',
        method: 'web_save',
        args: [
          [],
          payload,
        ],
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
              'fields': {
                'id': {},
                'name': {},
              },
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
      debugPrint('🔴 [OdooApiService] Endpoint 4 (calendar.event/web_save) error: $errStr');
      if (errStr.contains('cannot be used for') && appointmentTypeId != 2) {
        debugPrint('🟡 [OdooApiService] Retrying Endpoint 4 with appointmentTypeId=2...');
        return bookAppointment(
          name: name,
          appointmentTypeId: 2,
          productId: productId,
          appointmentBookerId: appointmentBookerId,
          partnerIds: partnerIds,
          start: start,
          stop: stop,
          duration: duration,
          resourceId: resourceId,
          phone: phone,
          collectorName: collectorName,
          collectorLicense: collectorLicense,
          vehicleMake: vehicleMake,
          vehicleModel: vehicleModel,
          vehicleImagesBase64: vehicleImagesBase64,
        );
      }
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
            ['appointment_booker_id', '=', partnerId],
            ['appointment_type_id', '!=', false],
          ],
          'specification': {
            'id': {},
            'name': {},
            'start': {},
            'stop': {},
            'duration': {},
            'active': {},
            'appointment_type_id': {
              'fields': {
                'id': {},
                'name': {},
              },
            },
            'appointment_resource_ids': {
              'fields': {
                'id': {},
                'name': {},
              },
            },
            'booking_phone': {},
            'booking_vehicle_make': {},
            'booking_vehicle_model': {},
            'booking_collector_required': {},
            'booking_collector_name': {},
            'booking_collector_license': {},
            'opportunity_id': {
              'fields': {
                'id': {},
                'name': {},
              },
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
              'fields': {
                'id': {},
                'name': {},
              },
            },
            'appointment_resource_ids': {
              'fields': {
                'id': {},
                'name': {},
              },
            },
            'booking_phone': {},
            'booking_vehicle_make': {},
            'booking_vehicle_model': {},
            'booking_collector_required': {},
            'booking_collector_name': {},
            'booking_collector_license': {},
            'opportunity_id': {
              'fields': {
                'id': {},
                'name': {},
              },
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
        kwargs: {
          'partner_ids': partnerIds,
        },
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
          'order': 'name asc',
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      return records.map((item) {
        return ProjectModel.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (e) {
      print('Endpoint 8 (project.project/web_search_read) error: $e');
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
              'fields': {
                'id': {},
                'name': {},
              },
            },
            'project_id': {
              'fields': {
                'id': {},
                'name': {},
              },
            },
          },
          'order': 'id desc',
        },
      );

      final List records = (response is Map && response.containsKey('records'))
          ? (response['records'] as List)
          : (response is List ? response : []);

      return records.map((item) {
        return ProjectTaskModel.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (e) {
      print('Endpoint 9 (project.task/web_search_read) error: $e');
      return [];
    }
  }

  @override
  Future<List<Booking>> getBookings(String customerId) async {
    try {
      final response = await _callKw(
        model: 'sale.order',
        method: 'search_read',
        args: [
          [
            ['partner_id', '=', int.tryParse(customerId) ?? _uid],
          ],
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

      List<Booking> bookings = [];
      for (var order in (response as List)) {
        final serviceJson = {
          'id': '1',
          'name': 'Premium Detail',
          'lst_price': order['amount_total'],
          'categ_id': [1, 'Full Packages'],
        };
        final service = DetailService.fromOdooJson(serviceJson);
        bookings.add(
          Booking.fromOdooJson(order as Map<String, dynamic>, service),
        );
      }
      return bookings;
    } catch (e) {
      print('Odoo getBookings error: $e');
      rethrow;
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
      final response = await _callKw(
        model: 'sale.order',
        method: 'read',
        args: [
          [int.parse(bookingId)],
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

      if ((response as List).isEmpty) return null;
      final service = DetailService(
        id: '1',
        name: 'Signature Detailing',
        description: 'Multi-stage paint correction & wax protection.',
        price: (response[0]['amount_total'] as num?)?.toDouble() ?? 299.99,
        durationHours: 4.0,
        imageUrl: '',
        category: 'Signature Packages',
        whatsIncluded: [],
      );

      return Booking.fromOdooJson(response[0] as Map<String, dynamic>, service);
    } catch (e) {
      print('Odoo getLiveTrackingBooking error: $e');
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

      if (_uid != null) {
        try {
          final userResp = await _callKw(
            model: 'res.users',
            method: 'write',
            args: [
              [_uid],
              writeData,
            ],
            kwargs: {},
          );
          if (userResp == true) {
            return true;
          }
        } catch (e) {
          debugPrint(
            'Odoo updateCustomerProfile via res.users failed: $e. Trying res.partner fallback.',
          );
        }
      }

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

      if (_uid != null) {
        try {
          final userResp = await _callKw(
            model: 'res.users',
            method: 'write',
            args: [
              [_uid],
              {'image_1920': base64Image},
            ],
            kwargs: {},
          );
          if (userResp == true) {
            return true;
          }
        } catch (e) {
          debugPrint(
            'Odoo uploadProfileImage via res.users failed: $e. Trying res.partner fallback.',
          );
        }
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

      if (_uid != null) {
        try {
          final userResp = await _callKw(
            model: 'res.users',
            method: 'write',
            args: [
              [_uid],
              {'active': false},
            ],
            kwargs: {},
          );
          if (userResp == true) success = true;
        } catch (e) {
          debugPrint(
            'Odoo deleteAccount via res.users failed: $e. Trying res.partner fallback.',
          );
        }
      }

      if (!success && partnerId != null) {
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

      if (_uid != null) {
        try {
          final userResp = await _callKw(
            model: 'res.users',
            method: 'write',
            args: [
              [_uid],
              {'image_1920': false},
            ],
            kwargs: {},
          );
          if (userResp == true) {
            return true;
          }
        } catch (e) {
          debugPrint(
            'Odoo clearProfilePicture via res.users failed: $e. Trying res.partner fallback.',
          );
        }
      }

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
}
