import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if (didPop) return;
        Navigator.pop(context);
      }),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Orders"),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<OrderModel>('orders').listenable(),
          builder: (context, Box<OrderModel> box, _) {
            if (box.values.isEmpty) {
              return const Center(child: Text("No orders yet"));
            }

            // Filter orders
            final orders = box.values.where((order) {
              if (fromDate != null && order.createdAt.isBefore(fromDate!)) {
                return false;
              }
              if (toDate != null && order.createdAt.isAfter(toDate!)) {
                return false;
              }
              return true;
            }).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first

            // Totals
            double total = orders.fold(0, (sum, o) => sum + o.totalAmount);
            double paid = orders
                .where((o) => o.paymentStatus == "Paid")
                .fold(0, (sum, o) => sum + o.totalAmount);
            double due = total - paid;

            return Column(
              children: [
                if (fromDate != null || toDate != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blueGrey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("From: ${_formatDate(fromDate)}"),
                        Text("To: ${_formatDate(toDate)}"),
                        const SizedBox(height: 8),
                        Text("Total: Rs. ${total.toStringAsFixed(2)}"),
                        Text("Paid: Rs. ${paid.toStringAsFixed(2)}"),
                        Text("Due: Rs. ${due.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                if (fromDate == null && toDate == null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.green.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Showing All Time Transactions"),
                        const SizedBox(height: 8),
                        Text("Total: Rs. ${total.toStringAsFixed(2)}"),
                        Text("Paid: Rs. ${paid.toStringAsFixed(2)}"),
                        Text("Due: Rs. ${due.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: orders.map((order) => OrderCard(order: order)).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Filter Orders"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  child: const Text("Pick From Date (Nepali)"),
                  onPressed: () async {
                    final picked = await showMaterialDatePicker(
                      context: context,
                      initialDate: NepaliDateTime.now(),
                      firstDate: NepaliDateTime(2070),
                      lastDate: NepaliDateTime(2090),
                    );
                    if (picked != null) {
                      setState(() {
                        fromDate = picked.toDateTime();
                      });
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("Pick To Date (Nepali)"),
                  onPressed: () async {
                    final picked = await showMaterialDatePicker(
                      context: context,
                      initialDate: NepaliDateTime.now(),
                      firstDate: NepaliDateTime(2070),
                      lastDate: NepaliDateTime(2090),
                    );
                    if (picked != null) {
                      setState(() {
                        toDate = picked.toDateTime();
                      });
                    }
                  },
                ),
                const Divider(),
                ElevatedButton(
                  child: const Text("English From Date"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => fromDate = picked);
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("English To Date"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => toDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("All Time"),
              onPressed: () {
                setState(() {
                  fromDate = null;
                  toDate = null;
                });
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Apply"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final nepali = NepaliDateTime.fromDateTime(date);
    return "${date.toString().split(' ')[0]} (BS: ${nepali.year}-${nepali.month}-${nepali.day})";
  }
}
