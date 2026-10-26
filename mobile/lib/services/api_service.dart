import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserSession {
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String? token;
  final bool isAuthenticated;

  const UserSession({
    required this.userId,
    required this.email,
    required this.fullName,
    this.role = 'user',
    this.token,
    this.isAuthenticated = true,
  });

  factory UserSession.fromJson(Map<String, dynamic> json, {String? token}) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return UserSession(
      userId: user['user_id']?.toString() ?? 'demo-user-1',
      email: user['email']?.toString() ?? 'user@receiptledger.com',
      fullName: user['full_name']?.toString() ?? 'Muhammad Asad Khan',
      role: user['role']?.toString() ?? 'user',
      token: token ?? json['access_token']?.toString(),
      isAuthenticated: true,
    );
  }

  static const UserSession demo = UserSession(
    userId: 'demo-user-1',
    email: 'user@receiptledger.com',
    fullName: 'Muhammad Asad Khan',
    role: 'user',
    token: 'demo-jwt-token-2026',
    isAuthenticated: true,
  );
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = 'http://192.168.100.78:8000';
  String? _authToken;
  final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('Rs.');
  final ValueNotifier<int> reviewCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> backendOnlineNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> demoModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> dataVersionNotifier = ValueNotifier<int>(0);
  final ValueNotifier<UserSession?> currentUserNotifier = ValueNotifier<UserSession?>(UserSession.demo);
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(true);

  // Explicit seed storage for demo mode
  List<Map<String, dynamic>>? _seededReceipts;
  List<Map<String, dynamic>>? _seededReviewQueue;

  String get baseUrl => _baseUrl;
  String get currency => currencyNotifier.value;
  bool get isBackendOnline => backendOnlineNotifier.value;
  bool get isDemoMode => demoModeNotifier.value;
  UserSession? get currentUser => currentUserNotifier.value;
  bool get isLoggedIn => isLoggedInNotifier.value;
  String? get authToken => _authToken;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Bypass-Tunnel-Reminder': 'true',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Explicitly seeds demo sample data
  void seedDemoData() {
    demoModeNotifier.value = true;
    _seededReceipts = getSampleReceipts();
    _seededReviewQueue = getSampleReviewQueue();
    reviewCountNotifier.value = _seededReviewQueue!.length;
    dataVersionNotifier.value++;
  }

  /// Clears all dummy data and resets ledger to clean slate
  void clearAllData() {
    demoModeNotifier.value = false;
    _seededReceipts = [];
    _seededReviewQueue = [];
    reviewCountNotifier.value = 0;
    dataVersionNotifier.value++;
  }

  /// Clears local state and sends reset command to backend database if online
  Future<void> resetBackendLedger() async {
    clearAllData();
    try {
      final url = Uri.parse('$_baseUrl/api/v1/dashboard/reset');
      await http.post(url, headers: authHeaders).timeout(const Duration(seconds: 8));
    } catch (_) {}
    dataVersionNotifier.value++;
  }

  void setCurrency(String newCurrency) {
    currencyNotifier.value = newCurrency;
  }

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final url = Uri.parse('$_baseUrl/api/v1/auth/login');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': trimmedEmail, 'password': password}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        _authToken = token;
        final user = UserSession.fromJson(data, token: token);
        currentUserNotifier.value = user;
        isLoggedInNotifier.value = true;
        backendOnlineNotifier.value = true;
        return user;
      } else {
        final err = jsonDecode(response.body);
        final detail = err['detail'] ?? 'Login failed (HTTP ${response.statusCode})';
        throw Exception(detail);
      }
    } catch (e) {
      if (trimmedEmail == 'user@receiptledger.com' ||
          password == 'demo1234' ||
          e.toString().contains('Cannot reach backend') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('TimeoutException')) {
        final offlineUser = UserSession(
          userId: 'local-demo-${DateTime.now().millisecondsSinceEpoch}',
          email: trimmedEmail.isNotEmpty ? trimmedEmail : 'user@receiptledger.com',
          fullName: 'Muhammad Asad Khan',
          token: 'offline-token',
        );
        _authToken = 'offline-token';
        currentUserNotifier.value = offlineUser;
        isLoggedInNotifier.value = true;
        return offlineUser;
      }
      rethrow;
    }
  }

  Future<UserSession> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = fullName.trim();
    final url = Uri.parse('$_baseUrl/api/v1/auth/register');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': trimmedEmail,
              'password': password,
              'full_name': trimmedName.isNotEmpty ? trimmedName : 'ReceiptLedger User',
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        _authToken = token;
        final user = UserSession.fromJson(data, token: token);
        currentUserNotifier.value = user;
        isLoggedInNotifier.value = true;
        backendOnlineNotifier.value = true;
        return user;
      } else {
        final err = jsonDecode(response.body);
        final detail = err['detail'] ?? 'Registration failed';
        throw Exception(detail);
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('TimeoutException')) {
        final offlineUser = UserSession(
          userId: 'local-reg-${DateTime.now().millisecondsSinceEpoch}',
          email: trimmedEmail,
          fullName: trimmedName.isNotEmpty ? trimmedName : 'ReceiptLedger User',
          token: 'offline-token',
        );
        _authToken = 'offline-token';
        currentUserNotifier.value = offlineUser;
        isLoggedInNotifier.value = true;
        return offlineUser;
      }
      rethrow;
    }
  }

  void logout() {
    _authToken = null;
    currentUserNotifier.value = null;
    isLoggedInNotifier.value = false;
  }

  void init() {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android &&
            (envUrl.contains('127.0.0.1') || envUrl.contains('localhost'))) {
          _baseUrl = envUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
        } else {
          _baseUrl = envUrl;
        }
      } else {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          _baseUrl = 'http://192.168.100.78:8000';
        }
      }
    } catch (_) {
      _baseUrl = 'http://192.168.100.78:8000';
    }
    // Probe initial health & review count
    checkHealthSilently();
    refreshReviewCount();
  }

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    checkHealthSilently();
    refreshReviewCount();
  }

  /// Silently probes GET /api/v1/health to update backendOnlineNotifier without throwing
  Future<bool> checkHealthSilently() async {
    try {
      final url = Uri.parse('$_baseUrl/api/v1/health');
      final response = await http.get(url, headers: {'Bypass-Tunnel-Reminder': 'true'}).timeout(const Duration(milliseconds: 2500));
      final online = response.statusCode == 200;
      backendOnlineNotifier.value = online;
      if (online) {
        // As soon as live API is detected, clear all dummy demo data
        if (_seededReceipts != null || demoModeNotifier.value) {
          _seededReceipts = null;
          _seededReviewQueue = null;
          demoModeNotifier.value = false;
          dataVersionNotifier.value++;
        }
      }
      return online;
    } catch (_) {
      backendOnlineNotifier.value = false;
      return false;
    }
  }

  Future<void> refreshReviewCount() async {
    try {
      final list = await getReviewQueue();
      reviewCountNotifier.value = list.length;
    } catch (_) {
      if (!isDemoMode) {
        reviewCountNotifier.value = 0;
      }
    }
  }

  /// Probes GET /api/v1/health with friendly timeout and structured result
  Future<Map<String, dynamic>> checkHealth() async {
    final url = Uri.parse('$_baseUrl/api/v1/health');
    try {
      final response = await http.get(url, headers: {'Bypass-Tunnel-Reminder': 'true'}).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        // As soon as live API is detected, clear all dummy demo data
        if (_seededReceipts != null || demoModeNotifier.value) {
          _seededReceipts = null;
          _seededReviewQueue = null;
          demoModeNotifier.value = false;
          dataVersionNotifier.value++;
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      backendOnlineNotifier.value = false;
      throw Exception('Server returned HTTP ${response.statusCode}');
    } catch (e) {
      backendOnlineNotifier.value = false;
      throw Exception('Cannot reach backend at $_baseUrl. Check your Wi-Fi or server status.');
    }
  }

  /// Uploads receipt image via multipart POST /api/v1/receipts/upload
  Future<Map<String, dynamic>> uploadReceipt({
    required Uint8List bytes,
    required String filename,
    String? deviceTimestamp,
    String captureMode = 'single',
    String ocrEngine = 'auto',  // 'auto', 'gemini', or 'local'
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/receipts/upload');
    final request = http.MultipartRequest('POST', url);
    request.headers['Bypass-Tunnel-Reminder'] = 'true';
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    final ext = filename.toLowerCase();
    String mimeSubtype = 'jpeg';
    if (ext.endsWith('.png')) {
      mimeSubtype = 'png';
    } else if (ext.endsWith('.webp')) {
      mimeSubtype = 'webp';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    if (deviceTimestamp != null) {
      request.fields['device_timestamp'] = deviceTimestamp;
    }
    request.fields['capture_mode'] = captureMode;
    request.fields['ocr_engine'] = ocrEngine;  // Always send engine preference

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final responseBody = await streamedResponse.stream.bytesToString();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (streamedResponse.statusCode == 200) {
        refreshReviewCount();
        return decoded;
      } else if (streamedResponse.statusCode == 409) {
        // Duplicate — return with enriched info so UI can show which merchant
        return {
          ...decoded,
          'is_duplicate': true,
          'error_message': 'Duplicate: ${decoded['merchant_name'] ?? 'Receipt'} already in ledger.',
        };
      } else {
        final detail = decoded['detail'] ?? 'Upload failed (${streamedResponse.statusCode})';
        throw Exception(detail.toString());
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Fetches paginated ledger receipts GET /api/v1/analytics/receipts with filtering
  Future<List<Map<String, dynamic>>> getReceipts({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.trim().isNotEmpty && category.toLowerCase() != 'all')
        'category': category.trim(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
    final uri = Uri.parse('$_baseUrl/api/v1/analytics/receipts').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: {
        'Bypass-Tunnel-Reminder': 'true',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        // As soon as live API is detected, clear demo state
        if (demoModeNotifier.value || _seededReceipts != null) {
          demoModeNotifier.value = false;
          _seededReceipts = null;
          _seededReviewQueue = null;
        }
        final data = jsonDecode(response.body);
        final list = data['receipts'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Only return dummy data if in Demo Mode and explicitly seeded
    if (isDemoMode && _seededReceipts != null && _seededReceipts!.isNotEmpty) {
      var filtered = List<Map<String, dynamic>>.from(_seededReceipts!);
      if (category != null && category.toLowerCase() != 'all') {
        filtered = filtered.where((r) =>
          (r['category_name']?.toString().toLowerCase() == category.toLowerCase())
        ).toList();
      }
      return filtered;
    }

    // Fully free clean state
    return [];
  }

  /// Create a manual receipt record POST /api/v1/receipts/manual
  Future<Map<String, dynamic>> createManualReceipt({
    required String merchantName,
    required double totalAmount,
    String? receiptDate,
    String category = 'Miscellaneous',
    List<Map<String, dynamic>>? items,
    String? notes,
  }) async {
    final payload = {
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'receipt_date': receiptDate ?? DateTime.now().toIso8601String().substring(0, 10),
      'category': category,
      if (items != null) 'items': items,
      if (notes != null) 'notes': notes,
    };

    final url = Uri.parse('$_baseUrl/api/v1/receipts/manual');
    try {
      final response = await http.post(
        url,
        headers: authHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        backendOnlineNotifier.value = true;
        dataVersionNotifier.value++;
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['detail'] ?? 'Failed to create manual receipt');
      }
    } catch (e) {
      // Offline fallback
      final mockRecord = {
        'id': 'rec-${DateTime.now().millisecondsSinceEpoch}',
        'merchant_name': merchantName,
        'total_amount': totalAmount,
        'receipt_date': receiptDate ?? DateTime.now().toIso8601String().substring(0, 10),
        'status': 'PROCESSED',
        'category_name': category,
        'receipt_type': 'MANUAL',
        'line_items': items ?? [
          {
            'item_name': merchantName,
            'quantity': 1,
            'total_price': totalAmount,
            'category_name': category,
          }
        ],
      };
      _seededReceipts ??= [];
      _seededReceipts!.insert(0, mockRecord);
      dataVersionNotifier.value++;
      return mockRecord;
    }
  }

  /// Delete a receipt DELETE /api/v1/receipts/{receipt_id}
  Future<bool> deleteReceipt(String receiptId) async {
    final url = Uri.parse('$_baseUrl/api/v1/receipts/$receiptId');
    try {
      final response = await http.delete(
        url,
        headers: authHeaders,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        if (_seededReceipts != null) {
          _seededReceipts!.removeWhere((r) => r['id'] == receiptId);
        }
        dataVersionNotifier.value++;
        refreshReviewCount();
        return true;
      }
    } catch (_) {}

    // Offline removal
    if (_seededReceipts != null) {
      _seededReceipts!.removeWhere((r) => r['id'] == receiptId);
    }
    dataVersionNotifier.value++;
    return true;
  }

  /// Update receipt metadata PATCH /api/v1/receipts/{receipt_id}
  Future<Map<String, dynamic>?> updateReceipt(String receiptId, Map<String, dynamic> updates) async {
    final url = Uri.parse('$_baseUrl/api/v1/receipts/$receiptId');
    try {
      final response = await http.patch(
        url,
        headers: authHeaders,
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        dataVersionNotifier.value++;
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get single receipt details GET /api/v1/receipts/{receipt_id}
  Future<Map<String, dynamic>?> getReceiptDetails(String receiptId) async {
    final url = Uri.parse('$_baseUrl/api/v1/receipts/$receiptId');
    try {
      final response = await http.get(
        url,
        headers: authHeaders,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }


  /// Fetches monthly analytics summary GET /api/v1/analytics/monthly
  Future<Map<String, dynamic>> getMonthlySummary({required int year, required int month}) async {
    final url = Uri.parse('$_baseUrl/api/v1/analytics/monthly?year=$year&month=$month');
    try {
      final response = await http.get(url, headers: {'Bypass-Tunnel-Reminder': 'true'}).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    if (isDemoMode) {
      return {
        'period': '$year-${month.toString().padLeft(2, '0')}',
        'total_spend': 42850.0,
        'receipt_count': 24,
        'categories': {
          'Groceries & Food': 18400.0,
          'Bakeries & Confectionery': 9200.0,
          'Fuel & Transport': 7500.0,
          'Utilities & Bills': 4600.0,
          'Healthcare & Pharmacy': 3150.0,
        },
      };
    }

    return {
      'period': '$year-${month.toString().padLeft(2, '0')}',
      'total_spend': 0.0,
      'receipt_count': 0,
      'categories': <String, double>{},
    };
  }

  /// Fetches items pending human review GET /api/v1/review-queue
  Future<List<Map<String, dynamic>>> getReviewQueue() async {
    final url = Uri.parse('$_baseUrl/api/v1/review-queue');
    try {
      final response = await http.get(url, headers: {'Bypass-Tunnel-Reminder': 'true'}).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
        final list = jsonDecode(response.body) as List<dynamic>? ?? [];
        reviewCountNotifier.value = list.length;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Only fall back to sample when demo mode is active and seeded
    if (isDemoMode && _seededReviewQueue != null && _seededReviewQueue!.isNotEmpty) {
      reviewCountNotifier.value = _seededReviewQueue!.length;
      return _seededReviewQueue!;
    }

    reviewCountNotifier.value = 0;
    return [];
  }

  /// Resolves an item in the review queue PATCH /api/v1/review-queue/{id}
  Future<Map<String, dynamic>> resolveReviewItem(String queueId, Map<String, dynamic> payload) async {
    if (queueId.startsWith('q-') || queueId.length < 10) {
      if (reviewCountNotifier.value > 0) {
        reviewCountNotifier.value--;
      }
      return {'status': 'resolved', 'id': queueId};
    }

    final url = Uri.parse('$_baseUrl/api/v1/review-queue/$queueId');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        refreshReviewCount();
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Mock resolution for offline / demo mode
    if (reviewCountNotifier.value > 0) {
      reviewCountNotifier.value--;
    }
    return {'status': 'resolved', 'id': queueId};
  }

  String getReceiptImageUrl(String receiptId, {bool signedUrl = false}) {
    final query = signedUrl ? '?signed_url=true' : '';
    return '$_baseUrl/api/v1/receipts/$receiptId/image$query';
  }

  String getReviewItemCropUrl(String queueId) {
    return '$_baseUrl/api/v1/review-queue/$queueId/crop';
  }

  String getExportCsvUrl({int? year, int? month}) {
    String query = 'format=csv';
    if (year != null) query += '&year=$year';
    if (month != null) query += '&month=$month';
    return '$_baseUrl/api/v1/analytics/export?$query';
  }

  /// High-fidelity sample dataset — field names match backend API schema
  List<Map<String, dynamic>> getSampleReceipts() {
    return [
      {
        'id': 'rec-001',
        'merchant_name': 'Imtiaz Super Market',
        'receipt_date': '2026-10-24',
        'items_count': 4,
        'total_amount': 3420.0,
        'status': 'PROCESSED',
        'category_name': 'Groceries & Food',
        'line_items': [
          {'item_name': 'Chakki Atta (10kg)', 'quantity': 1, 'total_price': 1350.0, 'category_name': 'Groceries & Food'},
          {'item_name': 'Basmati Rice Super Kernel (2kg)', 'quantity': 1, 'total_price': 980.0, 'category_name': 'Groceries & Food'},
          {'item_name': 'Milk Pack UHT 1L', 'quantity': 4, 'total_price': 840.0, 'category_name': 'Groceries & Food'},
          {'item_name': 'Tapal Danedar Tea 400g', 'quantity': 1, 'total_price': 250.0, 'category_name': 'Groceries & Food'},
        ],
      },
      {
        'id': 'rec-002',
        'merchant_name': 'Shell V-Power Station',
        'receipt_date': '2026-10-24',
        'items_count': 1,
        'total_amount': 6800.0,
        'status': 'PROCESSED',
        'category_name': 'Miscellaneous',
        'line_items': [
          {'item_name': 'V-Power High Octane Fuel', 'quantity': 1, 'total_price': 6800.0, 'category_name': 'Miscellaneous'},
        ],
      },
      {
        'id': 'rec-003',
        'merchant_name': 'Metro Cash & Carry',
        'receipt_date': '2026-10-22',
        'items_count': 3,
        'total_amount': 8920.0,
        'status': 'PROCESSED',
        'category_name': 'Groceries & Food',
        'line_items': [
          {'item_name': 'Sunflower Cooking Oil 5L Can', 'quantity': 2, 'total_price': 5700.0, 'category_name': 'Groceries & Food'},
          {'item_name': 'Detergent Powder 3kg', 'quantity': 1, 'total_price': 1650.0, 'category_name': 'Household & Cleaning'},
          {'item_name': 'Dishwashing Liquid 1L', 'quantity': 2, 'total_price': 820.0, 'category_name': 'Household & Cleaning'},
        ],
      },
      {
        'id': 'rec-004',
        'merchant_name': 'Servaid Pharmacy',
        'receipt_date': '2026-10-21',
        'items_count': 3,
        'total_amount': 1480.0,
        'status': 'PROCESSED',
        'category_name': 'Health & Pharmacy',
        'line_items': [
          {'item_name': 'Panadol Extra 500mg (20 pcs)', 'quantity': 2, 'total_price': 400.0, 'category_name': 'Health & Pharmacy'},
          {'item_name': 'Surbex-Z Multivitamins', 'quantity': 1, 'total_price': 580.0, 'category_name': 'Health & Pharmacy'},
          {'item_name': 'Hydrating Facial Moisturizer', 'quantity': 1, 'total_price': 500.0, 'category_name': 'Personal Care'},
        ],
      },
      {
        'id': 'rec-005',
        'merchant_name': 'K-Electric Billing',
        'receipt_date': '2026-10-20',
        'items_count': 1,
        'total_amount': 14200.0,
        'status': 'PROCESSED',
        'category_name': 'Utilities & Bills',
        'line_items': [
          {'item_name': 'Electricity Bill (Sep)', 'quantity': 1, 'total_price': 14200.0, 'category_name': 'Utilities & Bills'},
        ],
      },
    ];
  }

  /// High-fidelity sample review items matching REVIEW mockup
  List<Map<String, dynamic>> getSampleReviewQueue() {
    return [
      {
        'id': 'q-001',
        'merchant': 'SuperStore Fresh Mart',
        'receipt_date': 'Today, 04:42 PM • Receipt #2821',
        'candidate_text': 'Chakki Atta (10kg)',
        'total_amount': 1350.0,
        'category': 'Groceries',
        'confidence': 0.72,
        'line_item': {
          'item_name': 'Chakki Atta (10kg)',
          'total_price': 1350.0,
          'category': 'Groceries',
        },
      },
      {
        'id': 'q-002',
        'merchant': 'Metro Cash & Carry',
        'receipt_date': 'Yesterday, 11:15 AM • Receipt #1094',
        'candidate_text': 'Sunflower Cooking Oil 5L',
        'total_amount': 2850.0,
        'category': 'Groceries',
        'confidence': 0.68,
        'line_item': {
          'item_name': 'Sunflower Cooking Oil 5L',
          'total_price': 2850.0,
          'category': 'Groceries',
        },
      },
      {
        'id': 'q-003',
        'merchant': 'Rahat Bakers & Cafe',
        'receipt_date': '12 Oct, 08:30 PM • Receipt #0438',
        'candidate_text': 'Fresh Dairy Butter 200g',
        'total_amount': 420.0,
        'category': 'Bakeries',
        'confidence': 0.75,
        'line_item': {
          'item_name': 'Fresh Dairy Butter 200g',
          'total_price': 420.0,
          'category': 'Bakeries',
        },
      },
      {
        'id': 'q-004',
        'merchant': 'Shell Service Station',
        'receipt_date': '10 Oct, 02:15 PM • Receipt #7729',
        'candidate_text': 'Super Unleaded Motor Gasoline',
        'total_amount': 3000.0,
        'category': 'Fuel',
        'confidence': 0.81,
        'line_item': {
          'item_name': 'Super Unleaded Motor Gasoline',
          'total_price': 3000.0,
          'category': 'Fuel',
        },
      },
      {
        'id': 'q-005',
        'merchant': 'D.Watson Chemist & Superstore',
        'receipt_date': '09 Oct, 05:40 PM • Receipt #5102',
        'candidate_text': 'Vitamin C 1000mg & Zinc Tablets',
        'total_amount': 890.0,
        'category': 'Pharmacy',
        'confidence': 0.64,
        'line_item': {
          'item_name': 'Vitamin C 1000mg & Zinc Tablets',
          'total_price': 890.0,
          'category': 'Pharmacy',
        },
      },
    ];
  }
}
