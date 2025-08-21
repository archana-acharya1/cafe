import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<OrderModel>('orders').listenable(),
        builder: (context, Box<OrderModel> box, _) {
          if (box.values.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }
          return ListView(
            children: box.values.map((order) => OrderCard(order: order)).toList(),
          );
        },
      ),
    );
  }
}
