import 'package:deskgoo_cafe/models/order_item.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/user_model.dart';
import 'models/item_model.dart';
import 'models/area_model.dart';
import 'models/table_model.dart';
import 'models/order_model.dart';

import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();


  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ItemModelAdapter());
  Hive.registerAdapter(UnitOptionAdapter());
  Hive.registerAdapter(AreaModelAdapter());
  Hive.registerAdapter(TableModelAdapter());
  Hive.registerAdapter(OrderModelAdapter());
  Hive.registerAdapter(OrderItemAdapter());

  await Hive.openBox<UserModel>('users');
  await Hive.openBox<ItemModel>('items');
  await Hive.openBox<AreaModel>('areas');
  await Hive.openBox<TableModel>('tables');
  await Hive.openBox<OrderModel>('orders');

  final userBox = Hive.box<UserModel>('users');
  if (userBox.isEmpty) {
    userBox.add(UserModel(username: 'admin', password: '1234'));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
