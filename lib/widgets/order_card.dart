import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../screens/order_screen.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onCheckout;
  final VoidCallback? onDelete;
  final Function(OrderModel updatedOrder)? onUpdate;

  const OrderCard({
    super.key,
    required this.order,
    this.onCheckout,
    this.onDelete,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFF57C00);
    final accentColor = const Color(0xFFFF7043);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (!order.isCheckedOut) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderScreen(
                order: order,
                isEdit: true,
              ),
            ),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: Colors.white,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #${order.orderId}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: themeColor,
                    ),
                  ),
                  Chip(
                    label: Text(
                      order.paymentStatus,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: order.paymentStatus == "Paid"
                        ? Colors.green
                        : (order.paymentStatus == "Due"
                        ? Colors.redAccent
                        : Colors.amber),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                _formatOrderDate(order.createdAt),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 6),
              Text(
                "Table: ${order.tableName} (${order.area})",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "Customer: ${order.customerName ?? "Guest"}",
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                "Total: Rs.${order.totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: accentColor,
                ),
              ),

              if (order.paymentStatus == "Paid" && order.paymentMethod != null)
                Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "Payment Method: ${order.paymentMethod}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: order.paymentStatus == "Paid"
                        ? "Payment Completed"
                        : "Mark as Paid",
                    child: IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: order.paymentStatus == "Paid"
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: order.paymentStatus == "Paid"
                          ? null
                          : () {
                        order.paymentStatus = "Paid";
                        order.save();
                        onUpdate?.call(order);
                      },
                    ),
                  ),
                  if (onDelete != null)
                    Tooltip(
                      message: "Delete Order",
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: onDelete,
                      ),
                    ),
                  Tooltip(
                    message: "Print Bill",
                    child: IconButton(
                      icon: Icon(Icons.print, color: themeColor),
                      onPressed: () async {
                        await _printSingleOrder(order);
                      },
                    ),
                  ),
                  if (onCheckout != null)
                    order.isCheckedOut
                        ? ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey),
                      child: const Text("Checked Out"),
                    )
                        : ElevatedButton(
                      onPressed: onCheckout,
                      child: const Text("Checkout"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatOrderDate(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final formatter = DateFormat('hh:mm a');

    if (orderDate == today) {
      return "Today at ${formatter.format(createdAt)}";
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday at ${formatter.format(createdAt)}";
    } else {
      return "${DateFormat('yyyy-MM-dd').format(createdAt)} at ${formatter.format(createdAt)}";
    }
  }

  String _generateInvoiceNumber() {
    final settingsBox = Hive.box('settings');
    int lastInvoice = settingsBox.get('lastInvoiceNumber', defaultValue: 1000);
    int newInvoice = lastInvoice + 1;
    settingsBox.put('lastInvoiceNumber', newInvoice);
    return "SRN#$newInvoice";
  }

  static pw.Page buildOrderPdfPage(OrderModel order) {
    final customPageFormat = PdfPageFormat(
      58 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 1 * PdfPageFormat.mm,
    );

    final invoiceNumber =
        "SRN#${DateTime.now().millisecondsSinceEpoch % 100000}";

    final vatAmount = order.totalAmount * 0.13;
    final discount = order.discount ?? 0;
    final grandTotal = order.totalAmount + vatAmount - discount;

    return pw.Page(
      pageFormat: customPageFormat,
      build: (pw.Context context) {
        return pw.SizedBox(
          width: 58 * PdfPageFormat.mm,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Deskgoo Cafe',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              _rowText('Invoice:', invoiceNumber),
              _rowText('Invoice Date:',
                  '${DateTime.now().toString().split('.')[0]}'),
              _rowText('Customer:', order.customerName ?? "Guest"),
              _rowText('Table:', '${order.tableName} (${order.area})'),
              pw.SizedBox(height: 5),
              dottedDivider(),
              pw.SizedBox(height: 5),
              ...order.items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      flex: 5,
                      child: pw.Text(item.itemName,
                          style: pw.TextStyle(fontSize: 8))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('${item.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8))),
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                          (item.price * item.quantity).toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 8))),
                ],
              )),
              pw.SizedBox(height: 10),
              dottedDivider(),
              pw.SizedBox(height: 10),
              _rowText('Total VAT:', vatAmount.toStringAsFixed(2), bold: true),
              _rowText('Total Discount:', discount.toStringAsFixed(2),
                  bold: true),
              _rowText('Total:', grandTotal.toStringAsFixed(2), bold: true),
              pw.SizedBox(height: 10),
              dottedDivider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Thank you for visiting!',
                    style: pw.TextStyle(
                        fontSize: 9, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printSingleOrder(OrderModel order) async {
    final pdf = pw.Document();
    pdf.addPage(OrderCard.buildOrderPdfPage(order));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _rowText(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  static pw.Widget dottedDivider() {
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 2.0;
        final dashSpace = 2.0;
        final totalWidth = constraints!.maxWidth;
        final dashCount = (totalWidth / (dashWidth + dashSpace)).floor();

        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return pw.SizedBox(
              width: dashWidth,
              height: 1,
              child: pw.DecoratedBox(
                decoration: const pw.BoxDecoration(color: PdfColors.black),
              ),
            );
          }),
        );
      },
    );
  }
}
