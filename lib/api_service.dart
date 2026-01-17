import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  // =======================
  // AUTH
  // =======================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String nama,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal terhubung ke server: $e'};
    }
  }

  // =======================
  // SERVICES
  // =======================

  static Future<List<dynamic>> getServices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/services'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat layanan');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> addService(
    String nama,
    String harga,
    String satuan,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/services'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'harga': int.parse(harga),
          'satuan': satuan,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal menambah layanan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateService(
    int id,
    String nama,
    String harga,
    String satuan,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/services/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'harga': int.parse(harga),
          'satuan': satuan,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal update layanan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteService(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/services/$id'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal hapus layanan: $e'};
    }
  }

  // =======================
  // PAYMENT SETTINGS
  // =======================

  static Future<List<dynamic>> getAllPaymentSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payment-settings'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat payment settings');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<List<dynamic>> getPaymentSettings(String type) async {
    try {
      print('📤 Request Payment Settings: $baseUrl/payment-settings/$type');

      final response = await http
          .get(
            Uri.parse('$baseUrl/payment-settings/$type'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat payment settings');
      }
    } catch (e) {
      print('❌ Error getPaymentSettings: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> addPaymentSetting(
    String paymentType,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment-settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_type': paymentType,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder': accountHolder,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal menambah payment setting: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePaymentSetting(
    int id,
    String paymentType,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payment-settings/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_type': paymentType,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder': accountHolder,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal update payment setting: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadQrisImage(
    int paymentSettingId,
    XFile qrisImage,
  ) async {
    try {
      print(
          '📤 Uploading QRIS to: $baseUrl/payment-settings/$paymentSettingId/qris');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment-settings/$paymentSettingId/qris'),
      );

      final bytes = await qrisImage.readAsBytes();

      String mimeType = 'image/jpeg';
      if (qrisImage.name.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (qrisImage.name.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      final mediaType = mimeType.split('/');

      request.files.add(
        http.MultipartFile.fromBytes(
          'qris',
          bytes,
          filename: qrisImage.name,
          contentType: MediaType(mediaType[0], mediaType[1]),
        ),
      );

      final response = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Upload timeout');
            },
          );

      final responseBody = await response.stream.bytesToString();

      print('📥 Upload Status: ${response.statusCode}');
      print('📥 Upload Response: $responseBody');

      final result = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return result;
      } else {
        return {
          'error': result['message'] ?? result['error'] ?? 'Gagal upload QRIS',
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'error': 'Gagal upload QRIS: $e'};
    }
  }

  static Future<Map<String, dynamic>> deletePaymentSetting(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payment-settings/$id'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal hapus payment setting: $e'};
    }
  }

  // =======================
  // ORDERS
  // =======================

  static Future<Map<String, dynamic>> createOrder(
    int userId,
    String layanan,
    String jumlah,
    int harga,
    String paymentMethod,
  ) async {
    try {
      final body = jsonEncode({
        'user_id': userId,
        'layanan': layanan,
        'jumlah': int.parse(jumlah),
        'harga': harga,
        'payment_method': paymentMethod,
      });

      print('📤 Sending POST to: $baseUrl/orders/user');
      print('📤 Body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/user'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return result;
      } else {
        return {
          'error':
              result['message'] ?? result['error'] ?? 'Gagal membuat pesanan',
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'error': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadPaymentProof(
    int orderId,
    XFile buktiBayar,
  ) async {
    try {
      print('📤 Uploading to: $baseUrl/orders/upload/$orderId');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/orders/upload/$orderId'),
      );

      final bytes = await buktiBayar.readAsBytes();

      String mimeType = 'image/jpeg';
      if (buktiBayar.name.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (buktiBayar.name.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (buktiBayar.name.toLowerCase().endsWith('.pdf')) {
        mimeType = 'application/pdf';
      }

      final mediaType = mimeType.split('/');

      request.files.add(
        http.MultipartFile.fromBytes(
          'bukti',
          bytes,
          filename: buktiBayar.name,
          contentType: MediaType(mediaType[0], mediaType[1]),
        ),
      );

      final response = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Upload timeout');
            },
          );

      final responseBody = await response.stream.bytesToString();

      print('📥 Upload Status: ${response.statusCode}');
      print('📥 Upload Response: $responseBody');

      final result = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return result;
      } else {
        return {
          'error': result['message'] ?? result['error'] ?? 'Gagal upload',
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'error': 'Gagal upload: $e'};
    }
  }

  static Future<List<dynamic>> getUserOrders(int userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders/user/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil riwayat');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<List<dynamic>> getActiveOrders(int userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders/user/$userId/active'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil pesanan aktif');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<List<dynamic>> getOrderHistory(int userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders/user/$userId/history'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil riwayat pesanan');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> confirmOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/confirm'),
        headers: {'Content-Type': 'application/json'},
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return result;
      } else {
        return {
          'error': result['message'] ??
              result['error'] ??
              'Gagal konfirmasi pesanan',
        };
      }
    } catch (e) {
      return {'error': 'Gagal terhubung ke server: $e'};
    }
  }

  // =======================
  // ADMIN
  // =======================

  static Future<List<dynamic>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil pesanan');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal update status: $e'};
    }
  }

  static Future<Map<String, dynamic>> rejectOrder(
    int orderId,
    String? reason,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal menolak pesanan: $e'};
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(
    int orderId,
    String? reason,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Gagal membatalkan pesanan: $e'};
    }
  }

  // ========================================
  // ✅ ADMIN - GET ALL USERS
  // ========================================
  static Future<List<dynamic>> getAllUsers() async {
    try {
      print('📤 Request GET /users');
      
      final response = await http.get(Uri.parse('$baseUrl/users')).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil daftar user');
      }
    } catch (e) {
      print('❌ Error getAllUsers: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // ========================================
  // ✅ ADMIN - CREATE ORDER FOR USER (UPDATED WITH MANUAL CUSTOMER)
  // ========================================
  static Future<Map<String, dynamic>> createOrderByAdmin(
    int userId,
    String layanan,
    String jumlah,
    int harga,
    String paymentMethod, {
    String? manualCustomerName, // ✅ PARAMETER BARU
  }) async {
    try {
      final body = jsonEncode({
        'user_id': userId,
        'layanan': layanan,
        'jumlah': int.parse(jumlah),
        'harga': harga,
        'payment_method': paymentMethod,
        'manual_customer_name': manualCustomerName, // ✅ KIRIM KE BACKEND
      });

      print('📤 Admin creating order');
      print('📤 Body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/user'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return result;
      } else {
        return {
          'error':
              result['message'] ?? result['error'] ?? 'Gagal membuat pesanan',
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'error': 'Gagal terhubung ke server: $e'};
    }
  }

  // =======================
  // REPORTS (LAPORAN)
  // =======================

  static Future<Map<String, dynamic>> getDailyReport(
    String date, // yyyy-mm-dd
  ) async {
    try {
      print('📤 Request Daily Report: $baseUrl/reports/daily?date=$date');

      final response = await http
          .get(
            Uri.parse('$baseUrl/reports/daily?date=$date'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'total_pesanan': 0,
          'total_pendapatan': 0,
          'data': [],
          'error': 'Gagal mengambil laporan (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error getDailyReport: $e');
      return {
        'total_pesanan': 0,
        'total_pendapatan': 0,
        'data': [],
        'error': 'Gagal terhubung ke server: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMonthlyReport(
    int year,
    int month,
  ) async {
    try {
      print(
          '📤 Request Monthly Report: $baseUrl/reports/monthly?year=$year&month=$month');

      final response = await http
          .get(
            Uri.parse('$baseUrl/reports/monthly?year=$year&month=$month'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'total_pesanan': 0,
          'total_pendapatan': 0,
          'data': [],
          'error': 'Gagal mengambil laporan (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error getMonthlyReport: $e');
      return {
        'total_pesanan': 0,
        'total_pendapatan': 0,
        'data': [],
        'error': 'Gagal terhubung ke server: $e',
      };
    }
  }
}