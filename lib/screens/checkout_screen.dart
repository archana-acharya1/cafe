import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  final int orderKey;

  const CheckoutScreen({super.key, required this.orderKey});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _paidController = TextEditingController();
  final _customerNameController = TextEditingController();
  String _paymentStatus = "Paid";

  @override
  Widget build(BuildContext context) {
    final orderBox = Hive.box<OrderModel>('orders');
    final order = orderBox.get(widget.orderKey)!;

    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if (didPop){
          return;
        }
        Navigator.pop(context);
      }),
      child: Scaffold(
        appBar: AppBar(title: const Text("Checkout")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Table: ${order.tableName} (${order.area})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Total Amount: ${order.totalAmount}"),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                items: const [
                  DropdownMenuItem(value: "Paid", child: Text("Paid")),
                  DropdownMenuItem(value: "Credit", child: Text("Credit")),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Payment Status"),
              ),

              const SizedBox(height: 10),
              if (_paymentStatus == "Paid")
                TextField(
                  controller: _paidController,
                  decoration: const InputDecoration(labelText: "Paid Amount"),
                  keyboardType: TextInputType.number,
                ),

              if (_paymentStatus == "Credit")
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                ),

              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  double paid = 0;
                  String? customerName;

                  if (_paymentStatus == "Paid") {
                    paid = double.tryParse(_paidController.text) ?? order.totalAmount;
                    order.paidAmount = paid;
                    order.dueAmount = order.totalAmount - paid;
                  } else if (_paymentStatus == "Credit") {
                    order.paidAmount = 0;
                    order.dueAmount = order.totalAmount;
                    customerName = _customerNameController.text.trim();
                    order.customerName = customerName;
                  }

                  order.paymentStatus = _paymentStatus;

                  order.save();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Checkout completed")),
                  );

                  Navigator.pop(context);
                },
                child: const Text("Complete Checkout"),
              )
            ],
          ),
        ),
      ),
    );
  }
}