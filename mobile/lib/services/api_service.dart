import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = 'http://192.168.100.78:8000';
  final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('Rs.');
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
  final ValueNotifier<int> reviewCountNotifier = ValueNotifier<int>(5);
  final ValueNotifier<bool> backendOnlineNotifier = ValueNotifier<bool>(false);

  String get baseUrl => _baseUrl;
  String get currency => currencyNotifier.value;
  bool get isBackendOnline => backendOnlineNotifier.value;

  void setCurrency(String newCurrency) {
    currencyNotifier.value = newCurrency;
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
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
      final response = await http.get(url).timeout(const Duration(milliseconds: 2500));
      final online = response.statusCode == 200;
      backendOnlineNotifier.value = online;
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
      if (reviewCountNotifier.value == 0) {
        reviewCountNotifier.value = 5;
      }
    }
  }

  /// Probes GET /api/v1/health with friendly timeout and structured result
  Future<Map<String, dynamic>> checkHealth() async {
    final url = Uri.parse('$_baseUrl/api/v1/health');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        backendOnlineNotifier.value = true;
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
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/receipts/upload');
    final request = http.MultipartRequest('POST', url);

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

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (streamedResponse.statusCode == 200) {
        refreshReviewCount();
        return decoded;
      } else if (streamedResponse.statusCode == 409) {
        return {
          ...decoded,
          'is_duplicate': true,
          'error_message': 'Duplicate receipt already recorded in ledger.',
        };
      } else {
        final detail = decoded['detail'] ?? 'Upload failed (${streamedResponse.statusCode})';
        throw Exception(detail.toString());
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Fetches paginated ledger receipts GET /api/v1/analytics/receipts
  Future<List<Map<String, dynamic>>> getReceipts({int page = 1, int pageSize = 50}) async {
    final url = Uri.parse('$_baseUrl/api/v1/analytics/receipts?page=$page&page_size=$pageSize');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['receipts'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          return list.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    // If server is not responding, return mock sample receipts matching mockup LEDGER.png
    return getSampleReceipts();
  }

  /// Fetches monthly analytics summary GET /api/v1/analytics/monthly
  Future<Map<String, dynamic>> getMonthlySummary({required int year, required int month}) async {
    final url = Uri.parse('$_baseUrl/api/v1/analytics/monthly?year=$year&month=$month');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

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

  /// Fetches items pending human review GET /api/v1/review-queue
  Future<List<Map<String, dynamic>>> getReviewQueue() async {
    final url = Uri.parse('$_baseUrl/api/v1/review-queue');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          reviewCountNotifier.value = list.length;
          return list.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    // Mock items matching REVIEW.png if backend queue empty
    return getSampleReviewQueue();
  }

  /// Resolves an item in the review queue PATCH /api/v1/review-queue/{id}
  Future<Map<String, dynamic>> resolveReviewItem(String queueId, Map<String, dynamic> payload) async {
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

  /// High-fidelity sample dataset covering all realistic categories
  List<Map<String, dynamic>> getSampleReceipts() {
    return [
      {
        'id': 'rec-001',
        'merchant': 'Imtiaz Super Market',
        'date': 'Today, 2:38 PM',
        'items_count': 8,
        'total_amount': 3420.0,
        'status': 'VERIFIED',
        'category': 'Groceries',
        'payment_method': 'VISA ••4921',
        'tax': 162.0,
        'line_items': [
          {'item_name': 'Chakki Atta (10kg)', 'qty': 1, 'price': 1350.0, 'category': 'Groceries'},
          {'item_name': 'Basmati Rice Super Kernel (2kg)', 'qty': 1, 'price': 980.0, 'category': 'Groceries'},
          {'item_name': 'Milk Pack UHT 1L', 'qty': 4, 'price': 840.0, 'category': 'Groceries'},
          {'item_name': 'Tapal Danedar Tea 400g', 'qty': 1, 'price': 250.0, 'category': 'Groceries'},
        ],
      },
      {
        'id': 'rec-002',
        'merchant': 'Shell V-Power Station',
        'date': 'Today, 10:14 AM',
        'items_count': 1,
        'total_amount': 6800.0,
        'status': 'VERIFIED',
        'category': 'Fuel',
        'payment_method': 'Mastercard ••8104',
        'tax': 0.0,
        'line_items': [
          {'item_name': 'V-Power High Octane Fuel (23.4L)', 'qty': 1, 'price': 6800.0, 'category': 'Fuel'},
        ],
      },
      {
        'id': 'rec-003',
        'merchant': "Espresso Cafe & Roastery",
        'date': 'Yesterday, 5:12 PM',
        'items_count': 3,
        'total_amount': 2150.0,
        'status': 'VERIFIED',
        'category': 'Dining',
        'payment_method': 'Cash',
        'tax': 275.0,
        'line_items': [
          {'item_name': 'Iced Caramel Macchiato', 'qty': 2, 'price': 1300.0, 'category': 'Dining'},
          {'item_name': 'Butter Croissant', 'qty': 1, 'price': 450.0, 'category': 'Dining'},
          {'item_name': 'Belgian Chocolate Brownie', 'qty': 1, 'price': 400.0, 'category': 'Dining'},
        ],
      },
      {
        'id': 'rec-004',
        'merchant': 'Servaid Pharmacy',
        'date': 'Yesterday, 1:45 PM',
        'items_count': 3,
        'total_amount': 1480.0,
        'status': 'VERIFIED',
        'category': 'Pharmacy',
        'payment_method': 'VISA ••4921',
        'tax': 0.0,
        'line_items': [
          {'item_name': 'Panadol Extra 500mg (Pack of 20)', 'qty': 2, 'price': 400.0, 'category': 'Pharmacy'},
          {'item_name': 'Surbex-Z Multivitamins', 'qty': 1, 'price': 580.0, 'category': 'Pharmacy'},
          {'item_name': 'Hydrating Facial Moisturizer', 'qty': 1, 'price': 500.0, 'category': 'Pharmacy'},
        ],
      },
      {
        'id': 'rec-005',
        'merchant': 'Metro Cash & Carry',
        'date': '18 Oct, 3:20 PM',
        'items_count': 6,
        'total_amount': 8920.0,
        'status': 'VERIFIED',
        'category': 'Groceries',
        'payment_method': 'Mastercard ••8104',
        'tax': 420.0,
        'line_items': [
          {'item_name': 'Sunflower Cooking Oil (5L Can)', 'qty': 2, 'price': 5700.0, 'category': 'Groceries'},
          {'item_name': 'Detergent Powder 3kg', 'qty': 1, 'price': 1650.0, 'category': 'Household'},
          {'item_name': 'Dishwashing Liquid 1L', 'qty': 2, 'price': 820.0, 'category': 'Household'},
          {'item_name': 'Paper Towel Jumbo Pack', 'qty': 1, 'price': 750.0, 'category': 'Household'},
        ],
      },
      {
        'id': 'rec-006',
        'merchant': 'K-Electric Billing',
        'date': '16 Oct, 11:00 AM',
        'items_count': 1,
        'total_amount': 14200.0,
        'status': 'VERIFIED',
        'category': 'Utilities',
        'payment_method': 'Bank Transfer',
        'tax': 1200.0,
        'line_items': [
          {'item_name': 'Residential Electricity Bill (Sep)', 'qty': 1, 'price': 14200.0, 'category': 'Utilities'},
        ],
      },
      {
        'id': 'rec-007',
        'merchant': 'Tehzeeb Bakers',
        'date': '15 Oct, 7:15 PM',
        'items_count': 4,
        'total_amount': 1890.0,
        'status': 'VERIFIED',
        'category': 'Bakeries',
        'payment_method': 'Cash',
        'tax': 140.0,
        'line_items': [
          {'item_name': 'Chicken Patties (6 pcs)', 'qty': 1, 'price': 720.0, 'category': 'Bakeries'},
          {'item_name': 'Cream Caramel Pastry', 'qty': 2, 'price': 520.0, 'category': 'Bakeries'},
          {'item_name': 'Multi-grain Bread', 'qty': 1, 'price': 280.0, 'category': 'Bakeries'},
          {'item_name': 'Almond Macarons Box', 'qty': 1, 'price': 370.0, 'category': 'Bakeries'},
        ],
      },
      {
        'id': 'rec-008',
        'merchant': "Agha's Supermarket",
        'date': '14 Oct, 4:50 PM',
        'items_count': 4,
        'total_amount': 4310.0,
        'status': 'VERIFIED',
        'category': 'Groceries',
        'payment_method': 'VISA ••4921',
        'tax': 210.0,
        'line_items': [
          {'item_name': 'Organic Hass Avocados (Pack of 3)', 'qty': 1, 'price': 1450.0, 'category': 'Groceries'},
          {'item_name': 'Imported Olive Oil Extra Virgin 500ml', 'qty': 1, 'price': 1850.0, 'category': 'Groceries'},
          {'item_name': 'Greek Yogurt 400g', 'qty': 2, 'price': 650.0, 'category': 'Groceries'},
          {'item_name': 'Artisan Baguette', 'qty': 1, 'price': 360.0, 'category': 'Bakeries'},
        ],
      },
      {
        'id': 'rec-009',
        'merchant': 'PTCL Flash Fiber',
        'date': '12 Oct, 9:30 AM',
        'items_count': 1,
        'total_amount': 4199.0,
        'status': 'VERIFIED',
        'category': 'Utilities',
        'payment_method': 'Online Payment',
        'tax': 580.0,
        'line_items': [
          {'item_name': '100 Mbps Unlimited Fiber Internet (Monthly)', 'qty': 1, 'price': 4199.0, 'category': 'Utilities'},
        ],
      },
      {
        'id': 'rec-010',
        'merchant': 'Total Parco Fuel Station',
        'date': '10 Oct, 6:18 PM',
        'items_count': 1,
        'total_amount': 4500.0,
        'status': 'VERIFIED',
        'category': 'Fuel',
        'payment_method': 'Mastercard ••8104',
        'tax': 0.0,
        'line_items': [
          {'item_name': 'Super Unleaded Motor Gasoline', 'qty': 1, 'price': 4500.0, 'category': 'Fuel'},
        ],
      },
      {
        'id': 'rec-011',
        'merchant': 'Fazal Din Pharma Plus',
        'date': '08 Oct, 2:10 PM',
        'items_count': 2,
        'total_amount': 2340.0,
        'status': 'VERIFIED',
        'category': 'Pharmacy',
        'payment_method': 'Cash',
        'tax': 0.0,
        'line_items': [
          {'item_name': 'Digital Blood Pressure Monitor Strips', 'qty': 1, 'price': 1850.0, 'category': 'Pharmacy'},
          {'item_name': 'First Aid Antiseptic Bandages', 'qty': 1, 'price': 490.0, 'category': 'Pharmacy'},
        ],
      },
      {
        'id': 'rec-012',
        'merchant': 'Al-Fatah Department Store',
        'date': '05 Oct, 8:40 PM',
        'items_count': 5,
        'total_amount': 5600.0,
        'status': 'VERIFIED',
        'category': 'Shopping',
        'payment_method': 'VISA ••4921',
        'tax': 380.0,
        'line_items': [
          {'item_name': 'Ceramic Planter Sage Finish', 'qty': 2, 'price': 2200.0, 'category': 'Shopping'},
          {'item_name': 'Cotton Kitchen Towels (3-pack)', 'qty': 1, 'price': 950.0, 'category': 'Shopping'},
          {'item_name': 'Glass Storage Jar Set', 'qty': 1, 'price': 1650.0, 'category': 'Shopping'},
          {'item_name': 'Scented Soy Candle Cedarwood', 'qty': 1, 'price': 800.0, 'category': 'Shopping'},
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
