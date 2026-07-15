import 'package:dio/dio.dart';
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
  Future<bool> forgotPassword(String email);
}

class OdooApiService implements BaseOdooService {
  Dio? _dio;
  PersistCookieJar? _cookieJar;

  final String baseUrl;
  final String db;
  int? _uid;
  String? _sessionId;

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
      );

      final error = response.data['error'];
      if (error != null) {
        throw Exception(error['data']?['message'] ?? error['message'] ?? 'Odoo JSON-RPC Error');
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
          'params': {
            'db': db,
            'login': email,
            'password': password,
          },
        },
      );

      print('Odoo login response code: ${response.statusCode}');
      print('Odoo login response data: ${response.data}');

      final result = response.data['result'];

      if (result != null && result['uid'] != null && result['uid'] != false) {
        print('Odoo authentication successful! UID=${result['uid']}');
        _uid = result['uid'];
        _sessionId = result['session_id'];

        // Secure save credentials for future auto logins
        await _storage.write(key: 'instance_url', value: baseUrl);
        await _storage.write(key: 'database', value: db);
        await _storage.write(key: 'username', value: email);
        await _storage.write(key: 'uid', value: _uid.toString());
        await _storage.write(key: 'session_id', value: _sessionId ?? '');

        return true;
      }
      print('Odoo authentication failed: Invalid username or password (result is null/false).');
      return false;
    } catch (e) {
      print('Odoo authenticate caught exception: $e');
      return false;
    }
  }

  @override
  Future<bool> signup(String name, String email, String phone, String password) async {
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
      final tokenRegex = RegExp(r'name="csrf_token"\s+value="([^"]+)"|csrf_token:\s*"([^"]+)"');
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
      final success = response.statusCode == 200 && response.realUri.path != '/web/signup';
      print('Odoo signup result: success=$success');
      return success;
    } catch (e) {
      print('Odoo signup error: $e');
      return false;
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    try {
      await _ensureInitialized();
      
      // 1. Fetch CSRF token via GET request first
      print('Odoo reset password: fetching CSRF token from page...');
      final getResponse = await _dio!.get(
        '/web/reset_password',
        queryParameters: {'db': db},
      );
      
      String? csrfToken;
      final html = getResponse.data.toString();
      final tokenRegex = RegExp(r'name="csrf_token"\s+value="([^"]+)"|csrf_token:\s*"([^"]+)"');
      final match = tokenRegex.firstMatch(html);
      if (match != null) {
        csrfToken = match.group(1) ?? match.group(2);
      }
      
      print('Odoo reset password CSRF: $csrfToken');

      // 2. Perform POST request with CSRF token
      final response = await _dio!.post(
        '/web/reset_password',
        data: {
          'csrf_token': csrfToken ?? '',
          'db': db,
          'login': email,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      print('Odoo reset password response path: ${response.realUri.path}');
      final success = response.statusCode == 200 && response.realUri.path != '/web/reset_password';
      print('Odoo reset password result: success=$success');
      return success;
    } catch (e) {
      print('Odoo reset password error: $e');
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
  Future<List<DetailService>> getServices() async {
    try {
      final response = await _callKw(
        model: 'product.product',
        method: 'search_read',
        args: [
          [
            ['sale_ok', '=', true],
          ]
        ],
        kwargs: {
          'fields': ['id', 'name', 'description_sale', 'lst_price', 'categ_id', 'detailing_duration', 'whats_included', 'image_url'],
          'limit': 50,
        },
      );

      return (response as List).map((item) => DetailService.fromOdooJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Odoo getServices error: $e');
      rethrow;
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
          ]
        ],
        kwargs: {
          'fields': [
            'id', 'name', 'state', 'amount_total', 'date_order', 'note',
            'vehicle_name', 'vehicle_plate', 'technician_name', 'technician_avatar',
            'before_images', 'after_images'
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
          'categ_id': [1, 'Full Packages']
        };
        final service = DetailService.fromOdooJson(serviceJson);
        bookings.add(Booking.fromOdooJson(order as Map<String, dynamic>, service));
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
          }
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
          }
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
          [int.parse(bookingId)]
        ],
        kwargs: {
          'fields': [
            'id', 'name', 'state', 'amount_total', 'date_order', 'note',
            'vehicle_name', 'vehicle_plate', 'technician_name', 'technician_avatar',
            'before_images', 'after_images'
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
      final response = await _callKw(
        model: 'res.partner',
        method: 'read',
        args: [
          [int.tryParse(customerId) ?? _uid ?? 1]
        ],
        kwargs: {
          'fields': ['id', 'name', 'email', 'phone', 'street', 'city', 'zip', 'image_1920'],
        },
      );
      if ((response as List).isNotEmpty) {
        return response[0] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Odoo getCustomerProfile error: $e');
      return null;
    }
  }
}
