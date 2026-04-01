import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../datasources/auth_local_data_source.dart';

/// Appelle le backend NestJS pour créer une [Stripe Checkout Session] (abonnement),
/// puis retourne l’URL à ouvrir dans le navigateur / WebView.
///
/// **Backend à ajouter** (exemple NestJS) :
/// - `POST /billing/create-checkout-session`
/// - Headers : `Authorization: Bearer <jwt>`, `Content-Type: application/json`
/// - Body : `{ "plan": "monthly" | "yearly" }`
/// - Réponse : `{ "url": "<https://checkout.stripe.com/c/pay/...>" }`
///
/// Côté Stripe Dashboard : créer 2 **Prices** (récurrents, mensuel + annuel),
/// mettre les IDs (`price_…`) en variables d’env du serveur, et dans le handler
/// appeler `stripe.checkout.sessions.create({ mode: 'subscription', line_items: [...], success_url, cancel_url, customer_email? })`.
class StripeCheckoutService {
  StripeCheckoutService({required AuthLocalDataSource authLocalDataSource})
    : _auth = authLocalDataSource;

  final AuthLocalDataSource _auth;

  static const Duration _timeout = Duration(seconds: 25);

  /// Validate coupon status from backend before applying it in UI.
  Future<CouponValidationResult> validateCoupon({
    required String couponCode,
    required String plan,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const StripeCheckoutException('login_required');
    }

    final uri = Uri.parse('$apiBaseUrl/coupons/validate');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'couponCode': couponCode,
            'plan': plan,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StripeCheckoutException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final trimmed = response.body.trim();
    if (trimmed.isEmpty) {
      throw const StripeCheckoutException('empty_body');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      throw const StripeCheckoutException('invalid_json');
    }

    return CouponValidationResult.fromJson(json);
  }

  /// [plan] : `monthly` ou `yearly` — doit correspondre à ce que ton API attend.
  /// [couponCode] : optionnel, pour appliquer une promo serveur (ex: champion mensuel).
  Future<String> createCheckoutSessionUrl({
    required String plan,
    String? couponCode,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const StripeCheckoutException('login_required');
    }

    final uri = Uri.parse('$apiBaseUrl$stripeCreateCheckoutSessionPath');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'plan': plan,
            if (couponCode != null && couponCode.trim().isNotEmpty)
              'couponCode': couponCode.trim(),
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StripeCheckoutException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final trimmed = response.body.trim();
    if (trimmed.isEmpty) {
      throw const StripeCheckoutException('empty_body');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      throw const StripeCheckoutException('invalid_json');
    }

    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const StripeCheckoutException('no_url');
    }
    return url;
  }
}

class StripeCheckoutException implements Exception {
  const StripeCheckoutException(this.code, {this.body});

  /// Codes : `login_required`, `http_*`, `empty_body`, `invalid_json`, `no_url`
  final String code;
  final String? body;

  @override
  String toString() => 'StripeCheckoutException($code)';
}

class CouponValidationResult {
  const CouponValidationResult({
    required this.active,
    required this.valid,
    this.discountPercent,
    this.message,
  });

  final bool active;
  final bool valid;
  final int? discountPercent;
  final String? message;

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      active: json['active'] as bool? ?? false,
      valid: json['valid'] as bool? ?? false,
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
