// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class AuthService {
//   static const String baseUrl = "http://202.51.3.168:5006/api/v1";
//
//   static Future<Map<String, dynamic>> login(String email, String password) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/admin/login'), // you can change dynamically if needed
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body); // { token, id, role, email }
//     } else {
//       throw Exception('Login failed: ${response.body}');
//     }
//   }
// }
