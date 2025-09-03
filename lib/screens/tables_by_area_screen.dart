import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import 'order_screen.dart';
import '../helpers/table_helpers.dart';

class TablesByAreaScreen extends StatelessWidget {
  final String areaName;
  const TablesByAreaScreen({super.key, required this.areaName});

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF8B4513);
    final tableBox = Hive.box<TableModel>('tables');
    final orderBox = Hive.box<OrderModel>('orders');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
          title: Text("Tables in $areaName",
           style: TextStyle(fontWeight: FontWeight.bold,
           color: Colors.white),
          ),
        centerTitle: true,
        backgroundColor: themeColor,
        elevation: 2,
      ),
      body: ValueListenableBuilder(
        valueListenable: tableBox.listenable(),
        builder: (context, Box<TableModel> box, _) {
          final tables = box.values.where((t) => t.area == areaName).toList();

          if (tables.isEmpty) {
            return const Center(child: Text("No tables in this area yet."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return InkWell(
                onTap: () async {
                  OrderModel? order;

                  if (table.currentOrderId != null) {
                    final existingOrder =
                        orderBox.get(table.currentOrderId) as OrderModel?;
                    if (existingOrder != null && !existingOrder.isCheckedOut) {
                      order = existingOrder;
                    }
                  }
                  if (order == null) {
                    final newOrder = OrderModel(
                        tableName: table.name,
                        area: table.area,
                        items: [],
                        totalAmount: 0,
                        paidAmount: 0,
                        dueAmount: 0,
                        paymentStatus: "Unpaid",
                    );
                    final newKey = await orderBox.add(newOrder);

                    table.status = "Occupied";
                    table.currentOrderId = newKey.toString();
                    await table.save();

                    order = newOrder;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(
                        initialTableName: table.name,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: statusColor(table.status),
                          ),
                        ),
                        table.imagePath != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(table.imagePath!),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(Icons.table_chart, size: 60),
                        const SizedBox(height: 6),
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
