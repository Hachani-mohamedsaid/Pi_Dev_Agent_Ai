// NEW FILE: n8n webhook service for Finance features (separate from NestJS backend)
// Do not modify existing backend or auth services.

import 'dart:convert';
import 'package:http/http.dart' as http;

class N8nFinanceService {
  // FIXED: Use correct base URL
  static const String _baseUrl = 'https://n8n-production-1e13.up.railway.app/webhook';

  /// Get current month financial statistics
  /// Returns: { status, month, income, expenses, profit, savingsRate, transactionCount }
  Future<Map<String, dynamic>> getCurrentMonthStats() async {
    try {
      print('📊 Fetching current month stats...');
      
      // FIXED: Use correct URL path /webhook/current-month-stats
      final response = await http.get(Uri.parse('$_baseUrl/current-month-stats'));
      
      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Month stats loaded: ${data['month']}');
        return data;
      }
      throw Exception('Failed to load month stats: ${response.statusCode}');
    } catch (e) {
      print('❌ Error loading month stats: $e');
      rethrow;
    }
  }

  /// Get vendor breakdown with spending by vendor
  /// Returns: { status, total, vendors: [{ vendor, amount, percentage }] }
  Future<Map<String, dynamic>> getVendorBreakdown() async {
    try {
      print('🏪 Fetching vendor breakdown...');
      final response = await http.get(Uri.parse('$_baseUrl/vendor-breakdown'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Vendor breakdown loaded: ${data['vendors']?.length ?? 0} vendors');
        return data;
      }
      throw Exception('Failed to load vendor breakdown: ${response.statusCode}');
    } catch (e) {
      print('❌ Error loading vendor breakdown: $e');
      rethrow;
    }
  }

  /// Get category breakdown with spending by category
  /// Returns: { status, total, breakdown: [{ category, amount, percentage }] }
  Future<Map<String, dynamic>> getCategoryBreakdown() async {
    try {
      print('📂 Fetching category breakdown...');
      final response = await http.get(Uri.parse('$_baseUrl/category-breakdown'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Category breakdown loaded: ${data['breakdown']?.length ?? 0} categories');
        return data;
      }
      throw Exception('Failed to load category breakdown: ${response.statusCode}');
    } catch (e) {
      print('❌ Error loading category breakdown: $e');
      rethrow;
    }
  }

  /// Get spending by day of week
  /// Returns: { status, byDay: [{ day, total, average, count }] }
  Future<Map<String, dynamic>> getSpendingByDay() async {
    try {
      print('📅 Fetching spending by day...');
      final response = await http.get(Uri.parse('$_baseUrl/spending-by-day'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Spending by day loaded: ${data['byDay']?.length ?? 0} days');
        return data;
      }
      throw Exception('Failed to load spending by day: ${response.statusCode}');
    } catch (e) {
      print('❌ Error loading spending by day: $e');
      rethrow;
    }
  }
}
