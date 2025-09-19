// import 'package:flutter/material.dart';
// import '../models/manage_user_model.dart';
//
// class ManageUserScreen extends StatefulWidget {
//   final String token;
//   final String role;
//
//   const ManageUserScreen({super.key, required this.token, required this.role});
//
//   @override
//   State<ManageUserScreen> createState() => _ManageUserScreenState();
// }
//
// class _ManageUserScreenState extends State<ManageUserScreen> {
//   List<ManageUserModel> users = [];
//   bool isLoading = true;
//
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   String selectedRole = 'staff';
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUsers();
//   }
//
//   Future<void> fetchUsers() async {
//     setState(() => isLoading = true);
//     try {
//       if (widget.role == 'admin') {
//         users = await ManageUserService(baseUrl: "http://202.51.3.168:5006", token: widget.token).fetchManagers();
//         final staff = await ManageUserService(baseUrl: "http://202.51.3.168:5006", token: widget.token).fetchStaffs();
//         users.addAll(staff);
//       } else if (widget.role == 'manager') {
//         users = await ManageUserService(baseUrl: "http://202.51.3.168:5006", token: widget.token).fetchStaffs();
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching users: $e")));
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   Future<void> createUser() async {
//     if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required")));
//       return;
//     }
//
//     try {
//       await ManageUserService(baseUrl: "http://202.51.3.168:5006", token: widget.token).createUser(
//         name: nameController.text,
//         email: emailController.text,
//         password: passwordController.text,
//         role: selectedRole,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User created successfully")));
//       nameController.clear();
//       emailController.clear();
//       passwordController.clear();
//       fetchUsers();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating user: $e")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 children: [
//                   TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
//                   const SizedBox(height: 8),
//                   TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
//                   const SizedBox(height: 8),
//                   TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password")),
//                   const SizedBox(height: 8),
//                   if (widget.role == 'admin')
//                     DropdownButton<String>(
//                       value: selectedRole,
//                       items: const [
//                         DropdownMenuItem(value: 'manager', child: Text('Manager')),
//                         DropdownMenuItem(value: 'staff', child: Text('Staff')),
//                       ],
//                       onChanged: (v) {
//                         if (v != null) setState(() => selectedRole = v);
//                       },
//                     ),
//                   const SizedBox(height: 12),
//                   ElevatedButton(onPressed: createUser, child: const Text("Create User")),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//               itemCount: users.length,
//               itemBuilder: (ctx, i) {
//                 final u = users[i];
//                 return ListTile(
//                   title: Text(u.name),
//                   subtitle: Text("${u.email} | ${u.role}"),
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
