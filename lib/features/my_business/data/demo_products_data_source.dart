import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/business_product.dart';

/// API publique sans clé : https://fakestoreapi.com/products
/// Données compatibles avec l’interface Mon business (produits, prix).
const String demoProductsApiUrl = 'https://fakestoreapi.com/products';

/// Charge les produits depuis l’API démo (Fake Store). Aucune clé requise.
Future<List<BusinessProduct>> fetchDemoProducts() async {
  try {
    final response = await http
        .get(Uri.parse(demoProductsApiUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final list = jsonDecode(response.body) as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final id = m['id'];
      final title = m['title'] as String? ?? '';
      final price = m['price'] is num ? (m['price'] as num).toDouble() : null;
      final rating = m['rating'];
      final count = rating is Map
          ? (rating['count'] is num ? (rating['count'] as num).toInt() : 0)
          : 0;
      return BusinessProduct(
        id: id?.toString() ?? '',
        name: title,
        price: price,
        quantity: count,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}
