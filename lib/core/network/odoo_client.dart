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
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';

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

  final _storage = const FlutterSecureStorage();

  OdooApiService({required this.baseUrl, required this.db});

  /// Initialize the API client with instance URL, persistent cookies and headers
  Future<void> initialize() async {
    if (_dio != null) return;

    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

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
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
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
        _savedUserInfo = {
          'id': _partnerId ?? _uid,
          'name': userName,
          'email': result['username'] ?? email,
          'phone': '',
        };

        // Secure save credentials for future auto logins
        await _storage.write(key: 'instance_url', value: baseUrl);
        await _storage.write(key: 'database', value: db);
        await _storage.write(key: 'username', value: email);
        await _storage.write(key: 'uid', value: _uid.toString());
        if (_partnerId != null) {
          await _storage.write(key: 'partner_id', value: _partnerId.toString());
        }
        await _storage.write(key: 'session_id', value: _sessionId ?? '');
        await _storage.write(key: 'user_name', value: userName);
        await _storage.write(key: 'user_email', value: email);

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
      await _cookieJar?.deleteAll();
      await _storage.deleteAll();
      _uid = null;
      _sessionId = null;
      _dio = null;
    } catch (e) {
      print('Odoo logout error: $e');
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    try {
      final savedUid = await _storage.read(key: 'uid');
      if (savedUid != null && savedUid.isNotEmpty) {
        _uid = int.tryParse(savedUid);
        final savedPartnerId = await _storage.read(key: 'partner_id');
        if (savedPartnerId != null && savedPartnerId.isNotEmpty) {
          _partnerId = int.tryParse(savedPartnerId);
        }
        _sessionId = await _storage.read(key: 'session_id');

        final savedName = await _storage.read(key: 'user_name');
        final savedEmail = await _storage.read(key: 'user_email');
        if (savedName != null || savedEmail != null) {
          _savedUserInfo = {
            'id': _partnerId ?? _uid,
            'name': savedName ?? '',
            'email': savedEmail ?? '',
            'phone': '',
          };
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  List<DetailService> _getFallbackServices() {
    return const [
      DetailService(
        id: 'srv_1',
        name: 'Exterior Wash & Wax',
        description:
            'Comprehensive exterior hand wash, wheel cleaning, and hydrophobic wax spray application.',
        price: 49.99,
        durationHours: 1.5,
        imageUrl:
            'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?auto=format&fit=crop&q=80&w=800',
        category: 'Exterior',
        whatsIncluded: [
          'Hand wash & micro-fiber dry',
          'Wheel & tire decontamination',
          'Spray wax sealant',
        ],
      ),
      DetailService(
        id: 'srv_2',
        name: 'Interior Deep Clean',
        description:
            'Deep vacuuming, steam cleaning, leather conditioning, and interior surface sanitizer application.',
        price: 89.99,
        durationHours: 2.5,
        imageUrl:
            'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&q=80&w=800',
        category: 'Interior',
        whatsIncluded: [
          'Deep vacuum & steam extraction',
          'Leather clean & condition',
          'Dashboard & console detail',
        ],
      ),
      DetailService(
        id: 'srv_3',
        name: 'Full Signature Detailing',
        description:
            'Ultimate paint correction, ceramic sealant protection, and complete interior restoration package.',
        price: 199.99,
        durationHours: 4.5,
        imageUrl:
            'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?auto=format&fit=crop&q=80&w=800',
        category: 'Signature Packages',
        whatsIncluded: [
          '1-Stage paint polishing',
          'Ceramic spray coating',
          'Full interior steam extraction',
        ],
      ),
    ];
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
            [
              ['sale_ok', '=', true],
            ],
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
            [
              ['sale_ok', '=', true],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'description_sale',
              'lst_price',
              'categ_id',
              'detailing_duration',
              'whats_included',
              'image_url',
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
            'date_order': booking.bookingDateTime.toIso8601String(),
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

      // Try reading res.partner with targetId
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
          return data;
        }
      } catch (e) {
        print(
          'res.partner read restricted: $e. Using user session info / res.users fallback.',
        );
        // Fallback: try reading res.users for current user
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
                ],
              },
            );
            if ((userResp as List).isNotEmpty) {
              final u = userResp[0] as Map<String, dynamic>;
              _savedUserInfo = {
                'id': _partnerId ?? _uid,
                'name': u['name'] ?? _savedUserInfo?['name'] ?? '',
                'email':
                    u['email'] ?? u['login'] ?? _savedUserInfo?['email'] ?? '',
                'phone': u['phone'] ?? _savedUserInfo?['phone'] ?? '',
              };
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
}
