import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
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

  String _generateInvoiceNumber() {
    final settingsBox = Hive.box('settings');
    int lastInvoice = settingsBox.get('lastInvoiceNumber', defaultValue:1000);

    int newInvoice = lastInvoice + 1;
    settingsBox.put('lastInvoiceNumber', newInvoice);

    return "SRN#$newInvoice";
  }

  Future<void> _printOrder(OrderModel order) async {
    final pdf = pw.Document();

    final customPageFormat = PdfPageFormat(
      58 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 1 * PdfPageFormat.mm,
    );

    final invoiceNumber = _generateInvoiceNumber();

    final vatAmount = order.totalAmount * 0.13;
    final discount = order.discount ?? 0;
    final grandTotal = order.totalAmount + vatAmount - discount;

    pdf.addPage(
      pw.Page(
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

                _rowText('Tax ID:', order.taxId?.toString() ?? "N/A"),
                _rowText('Invoice:', invoiceNumber),
                _rowText('Invoice Date:',
                    '${DateTime.now().toString().split('.')[0]}'),
                _rowText('Customer:', order.customerName ?? "Guest"),
                _rowText('Table:', '${order.tableName} (${order.area})'),

                pw.SizedBox(height: 5),
                dottedDivider(),
                pw.SizedBox(height: 5),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        flex: 5,
                        child: pw.Text('Description',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Qty',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text('Subtotal',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),

                pw.SizedBox(height: 5),
                dottedDivider(),
                pw.SizedBox(height: 10),

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
                pw.SizedBox(height: 10),

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
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _rowText(String label, String value, {bool bold = false}) {
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

  pw.Widget dottedDivider() {
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