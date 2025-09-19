// import 'dart:convert';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;
//
// part 'manage_user_model.g.dart';
//
// @HiveType(typeId: 12)
// class ManageUserModel {
//   @HiveField(0)
//   final String id;
//
//   @HiveField(1)
//   final String name;
//
//   @HiveField(2)
//   final String email;
//
//   @HiveField(3)
//   final String role;
//
//   ManageUserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.role,
//   });
//
//   factory ManageUserModel.fromJson(Map<String, dynamic> json) {
//     return ManageUserModel(
//       id: json['_id'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       role: json['role'] ?? 'staff',
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "_id": id,
//       "name": name,
//       "email": email,
//       "role": role,
//     };
//   }
// }
//
// class ManageUserService {
//   final String baseUrl;
//   final String token;
//
//   ManageUserService({required this.baseUrl, required this.token});
//
//   Future<List<ManageUserModel>> fetchManagers() async {
//     final res = await http.get(
//       Uri.parse('$baseUrl/api/managers'),
//       headers: {"Authorization": "Bearer $token"},
//     );
//     if (res.statusCode == 200) {
//       final List data = jsonDecode(res.body);
//       return data.map((e) => ManageUserModel.fromJson(e)).toList();
//     } else {
//       throw Exception('Failed to load managers');
//     }
//   }
//
//   Future<List<ManageUserModel>> fetchStaffs() async {
//     final res = await http.get(
//       Uri.parse('$baseUrl/api/staffs'),
//       headers: {"Authorization": "Bearer $token"},
//     );
//     if (res.statusCode == 200) {
//       final List data = jsonDecode(res.body);
//       return data.map((e) => ManageUserModel.fromJson(e)).toList();
//     } else {
//       throw Exception('Failed to load staff');
//     }
//   }
//
//
//   Future<void> createUser({
//     required String name,
//     required String email,
//     required String password,
//     required String role, // "manager" or "staff"
//   }) async {
//     final url = role == "manager"
//         ? '$baseUrl/api/managers'
//         : '$baseUrl/api/staffs';
//
//     final res = await http.post(
//       Uri.parse(url),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({"name": name, "email": email, "password": password}),
//     );
//
//     if (res.statusCode != 201) {
//       throw Exception(jsonDecode(res.body)['error'] ?? "Failed to create $role");
//     }
//   }
// }
