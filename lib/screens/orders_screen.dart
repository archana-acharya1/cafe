import 'package:deskgoo_cafe/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF8B4513); // Coffee Brown

    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if (didPop) return;
        Navigator.pop(context);
      }),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6EC), // Warm cream background
        appBar: AppBar(
          title: const Text("Orders",
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: themeColor,
          elevation: 2,
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<OrderModel>('orders').listenable(),
          builder: (context, Box<OrderModel> box, _) {
            if (box.values.isEmpty) {
              return Center(
                child: Text(
                  "No orders yet",
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              );
            }

            final keys = box.keys.cast<int>().toList().reversed.toList();

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                final order = box.get(key)!;

                return OrderCard(
                  order: order,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          OrderScreen(order: order, isEdit: true),
                    ));
                  },
                  onDelete: () async {
                    await box.delete(key);
                  },
                  onUpdate: (updatedOrder) async {
                    await box.put(key, updatedOrder);
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 4),
            );
          },
        ),
      ),
    );
  }
}
