import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Table: ${order.tableName} (${order.area})",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Total: ${order.totalAmount.toStringAsFixed(2)}"),
            Text("Status: ${order.paymentStatus}"),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    order.paymentStatus = "Paid";
                    order.save();
                  },
                ),

                // Print Button
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () async {
                    await _printOrder(order);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printOrder(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Order Receipt',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Table: ${order.tableName} (${order.area})'),
              pw.Text('Customer: ${order.customerName ?? "N/A"}'),
              pw.SizedBox(height: 10),
              pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item.itemName} (${item.unitName})'),
                      pw.Text('${item.quantity} x ${item.price.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total: ${order.totalAmount.toStringAsFixed(2)}'),
              pw.Text('Paid: ${order.paidAmount.toStringAsFixed(2)}'),
              pw.Text('Due: ${order.dueAmount.toStringAsFixed(2)}'),
              pw.Text('Payment Status: ${order.paymentStatus}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
