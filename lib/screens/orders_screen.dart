import 'package:deskgoo_cafe/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

import '../models/order_model.dart';
import '../models/table_model.dart';
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
    final themeColor = const Color(0xFF8B4513); // Coffee Brown

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6EC),
        appBar: AppBar(
          title: const Text(
            "Orders",
            style: TextStyle(fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: themeColor,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list,
              color: Colors.white
              ),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final orders = box.values.where((order) {
              if (fromDate != null) {
                final startOfFromDate = DateTime(
                    fromDate!.year, fromDate!.month, fromDate!.day, 0, 0, 0);
                if (order.createdAt.isBefore(startOfFromDate)) return false;
              }
              if (toDate != null) {
                final endOfToDate = DateTime(
                    toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
                if (order.createdAt.isAfter(endOfToDate)) return false;
              }
              return true;
            }).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                  )
                else
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
                    children: orders.map((order) {
                      return OrderCard(
                        order: order,
                        onCheckout: () async => await _onCheckoutPressed(order),
                        onUpdate: (updatedOrder) => setState(() {}),
                        onTap: order.isCheckedOut
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderScreen(
                                order: order,
                                isEdit: true,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onCheckoutPressed(OrderModel order) async {
    final choice = await showDialog<_CheckoutAction>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Checkout"),
          content: const Text(
            "Complete checkout for this order? What would you like to do with the record?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _CheckoutAction.cancel),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _CheckoutAction.completeKeep),
              child: const Text("Complete & Keep Record"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, _CheckoutAction.completeRemove),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Complete & Remove"),
            ),
          ],
        );
      },
    );

    if (choice == null || choice == _CheckoutAction.cancel) return;

    // Make table available
    final tableBox = Hive.box<TableModel>('tables');
    for (final t in tableBox.values) {
      if (t.name == order.tableName) {
        t.status = "Available";
        await t.save();
        break;
      }
    }

    if (choice == _CheckoutAction.completeKeep) {
      order.isCheckedOut = true;
      order.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout completed, record kept.")),
      );
    } else if (choice == _CheckoutAction.completeRemove) {
      await order.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout completed, order removed.")),
      );
    }

    setState(() {});
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
                    final picked = await showNepaliDatePicker(
                      context: context,
                      initialDate: NepaliDateTime.now(),
                      firstDate: NepaliDateTime(2070, 1, 1),
                      lastDate: NepaliDateTime(2090, 12, 30),
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
                    final picked = await showNepaliDatePicker(
                      context: context,
                      initialDate: NepaliDateTime.now(),
                      firstDate: NepaliDateTime(2070, 1, 1),
                      lastDate: NepaliDateTime(2090, 12, 30),
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
                    if (picked != null) setState(() => fromDate = picked);
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
                    if (picked != null) setState(() => toDate = picked);
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

enum _CheckoutAction { cancel, completeKeep, completeRemove }
