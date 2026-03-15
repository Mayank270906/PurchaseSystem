/// API Service
/// 
/// Centralized HTTP client for all backend API calls.
/// Automatically injects JWT token into request headers.
/// Base URL configurable for dev/prod environments.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your backend URL
  // For Android emulator use: http://10.0.2.2:3000
  // For iOS simulator use: http://localhost:3000
  // For physical device use your machine's IP: http://192.168.x.x:3000
  // Production URL (Render.com)
  static const String baseUrl = 'https://purchase-registry-api.onrender.com/api';

  /// Get stored JWT token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Build headers with optional auth token
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTH ──────────────────────────────────────────

  /// Login and return response with token
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  /// Register a new user account
  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: await _headers(),
      body: jsonEncode({'current_password': currentPassword, 'new_password': newPassword}),
    );
    return jsonDecode(response.body);
  }

  /// Get current user info
  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // ─── USERS (Admin) ────────────────────────────────

  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: await _headers(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return data['users'] ?? [];
  }

  // ─── ITEMS ────────────────────────────────────────

  static Future<Map<String, dynamic>> createItem({
    required String itemName,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: await _headers(),
      body: jsonEncode({
        'item_name': itemName,
        'description': description,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getItems({String? search}) async {
    final uri = Uri.parse('$baseUrl/items')
        .replace(queryParameters: search != null ? {'search': search} : null);
    final response = await http.get(uri, headers: await _headers());
    final data = jsonDecode(response.body);
    return data['items'] ?? [];
  }

  // ─── VENDORS ──────────────────────────────────────

  static Future<Map<String, dynamic>> createVendor({
    required String vendorName,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vendors'),
      headers: await _headers(),
      body: jsonEncode({
        'vendor_name': vendorName,
        'phone': phone,
        'address': address,
        'notes': notes,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getVendors({String? search}) async {
    final uri = Uri.parse('$baseUrl/vendors')
        .replace(queryParameters: search != null ? {'search': search} : null);
    final response = await http.get(uri, headers: await _headers());
    final data = jsonDecode(response.body);
    return data['vendors'] ?? [];
  }

  static Future<Map<String, dynamic>> updateVendor(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vendors/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getVendorProfile(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vendors/$id'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // ─── VENDOR PRICES ────────────────────────────────

  static Future<Map<String, dynamic>> setVendorPrice({
    required int vendorId,
    required int itemId,
    required double price,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vendors/$vendorId/prices'),
      headers: await _headers(),
      body: jsonEncode({'item_id': itemId, 'price': price}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getVendorPrices(int vendorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vendors/$vendorId/prices'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return data['prices'] ?? [];
  }

  // ─── PURCHASES ────────────────────────────────────

  static Future<Map<String, dynamic>> recordPurchase({
    required int vendorId,
    required int itemId,
    required double quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchases'),
      headers: await _headers(),
      body: jsonEncode({
        'vendor_id': vendorId,
        'item_id': itemId,
        'quantity': quantity,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPurchases({
    int? vendorId,
    int? itemId,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (vendorId != null) params['vendor_id'] = vendorId.toString();
    if (itemId != null) params['item_id'] = itemId.toString();
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;

    final uri = Uri.parse('$baseUrl/purchases').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    return jsonDecode(response.body);
  }

  // ─── PAYMENTS ─────────────────────────────────────

  static Future<Map<String, dynamic>> recordPayment({
    required int vendorId,
    required double amount,
    String? purpose,
    String? paymentMethod,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: await _headers(),
      body: jsonEncode({
        'vendor_id': vendorId,
        'amount': amount,
        'purpose': purpose,
        'payment_method': paymentMethod,
        'notes': notes,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPayments({
    int? vendorId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (vendorId != null) params['vendor_id'] = vendorId.toString();
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;

    final uri = Uri.parse('$baseUrl/payments').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    return jsonDecode(response.body);
  }

  // ─── DASHBOARD ────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/summary'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getVendorBalances() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/vendor-balances'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return data['vendor_balances'] ?? [];
  }
}
