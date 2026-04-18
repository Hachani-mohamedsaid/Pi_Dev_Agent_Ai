// NEW FILE: n8n webhook service for Finance features (separate from NestJS backend)
// Do not modify existing backend or auth services.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/network/request_headers.dart';
import '../core/observability/sentry_api.dart';

class N8nFinanceService {
  // FIXED: Use correct base URL
  static const String _baseUrl =
      'https://n8n-production-1e13.up.railway.app/webhook';

  /// Get current month financial statistics
  /// Returns: { status, month, income, expenses, profit, savingsRate, transactionCount }
  Future<Map<String, dynamic>> getCurrentMonthStats(String userId) async {
    try {
      print('📊 Fetching current month stats...');

      // FIXED: Use correct URL path /webhook/current-month-stats
      final response = await http.get(
        Uri.parse('$_baseUrl/current-month-stats')
            .replace(queryParameters: {'userId': userId}),
        headers: buildJsonHeaders(),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data =
            response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
        print('✅ Month stats loaded: ${data['month']}');
        return data;
      }
      reportHttpResponseError(
        feature: 'n8n_finance.month_stats',
        response: response,
      );
      throw Exception('Failed to load month stats: ${response.statusCode}');
    } catch (e, stackTrace) {
      reportApiException(
        feature: 'n8n_finance.month_stats',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Error loading month stats: $e');
      rethrow;
    }
  }

  /// Get vendor breakdown with spending by vendor
  /// Returns: { status, total, vendors: [{ vendor, amount, percentage }] }
  Future<Map<String, dynamic>> getVendorBreakdown(String userId) async {
    try {
      print('🏪 Fetching vendor breakdown...');
      final response = await http.get(
        Uri.parse('$_baseUrl/vendor-breakdown')
            .replace(queryParameters: {'userId': userId}),
        headers: buildJsonHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Vendor breakdown loaded: ${data['vendors']?.length ?? 0} vendors',
        );
        return data;
      }
      reportHttpResponseError(
        feature: 'n8n_finance.vendor_breakdown',
        response: response,
      );
      throw Exception(
        'Failed to load vendor breakdown: ${response.statusCode}',
      );
    } catch (e, stackTrace) {
      reportApiException(
        feature: 'n8n_finance.vendor_breakdown',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Error loading vendor breakdown: $e');
      rethrow;
    }
  }

  /// Get category breakdown with spending by category
  /// Returns: { status, total, breakdown: [{ category, amount, percentage }] }
  Future<Map<String, dynamic>> getCategoryBreakdown(String userId) async {
    try {
      print('📂 Fetching category breakdown...');
      final response = await http.get(
        Uri.parse('$_baseUrl/category-breakdown')
            .replace(queryParameters: {'userId': userId}),
        headers: buildJsonHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Category breakdown loaded: ${data['breakdown']?.length ?? 0} categories',
        );
        return data;
      }
      reportHttpResponseError(
        feature: 'n8n_finance.category_breakdown',
        response: response,
      );
      throw Exception(
        'Failed to load category breakdown: ${response.statusCode}',
      );
    } catch (e, stackTrace) {
      reportApiException(
        feature: 'n8n_finance.category_breakdown',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Error loading category breakdown: $e');
      rethrow;
    }
  }

  /// Get spending by day of week
  /// Returns: { status, byDay: [{ day, total, average, count }] }
  Future<Map<String, dynamic>> getSpendingByDay(String userId) async {
    try {
      print('📅 Fetching spending by day...');
      final response = await http.get(
        Uri.parse('$_baseUrl/spending-by-day')
            .replace(queryParameters: {'userId': userId}),
        headers: buildJsonHeaders(),
      );

      if (response.statusCode == 200) {
        final data =
            response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
        print('✅ Spending by day loaded: ${data['byDay']?.length ?? 0} days');
        return data;
      }
      reportHttpResponseError(
        feature: 'n8n_finance.spending_by_day',
        response: response,
      );
      throw Exception('Failed to load spending by day: ${response.statusCode}');
    } catch (e, stackTrace) {
      reportApiException(
        feature: 'n8n_finance.spending_by_day',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Error loading spending by day: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMlPredictions(String userId) async {
    try {
      print('🧠 Fetching ML predictions...');
      final response = await http.post(
        Uri.parse('$_baseUrl/ml-predict'),
        headers: buildJsonHeaders(),
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data =
            response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
        print('✅ ML predictions loaded');
        return data;
      }
      reportHttpResponseError(feature: 'n8n_finance.ml_predict', response: response);
      throw Exception('Failed to load ML predictions: ${response.statusCode}');
    } catch (e, stackTrace) {
      reportApiException(
        feature: 'n8n_finance.ml_predict',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Error loading ML predictions: $e');
      rethrow;
    }
  }
}
