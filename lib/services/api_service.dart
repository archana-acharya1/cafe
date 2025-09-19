import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/area_model.dart';
import '../models/item_model.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000/api/v1";

  static Map<String, String> headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Future<List<AreaResponseModel>> fetchAreas(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/areas'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AreaResponseModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load areas: ${response.body}");
    }
  }

  // static Future<List<ItemResponseModel>> fetchItems(String token) async {
  //   final response = await http.get(
  //     Uri.parse('$baseUrl/items'),
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "application/json",
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = jsonDecode(response.body);
  //     return data.map((json) => ItemResponseModel.fromJson(json)).toList();
  //   } else {
  //     throw Exception("Failed to load items: ${response.body}");
  //   }
  // }

  static Future<List<TableResponseModel>> fetchTables(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tables'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TableResponseModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load tables: ${response.body}");
    }
  }

  static Future<List<OrderResponseModel>> fetchOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderResponseModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load orders: ${response.body}");
    }
  }

  static Future<OrderResponseModel> createOrder(String token, Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return OrderResponseModel.fromJson(data);
    } else {
      throw Exception("Failed to create order: ${response.body}");
    }
  }
}
