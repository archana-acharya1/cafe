import 'package:flutter/material.dart';
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

  Future<void> printPdf() async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final customPageFormat = PdfPageFormat(
      58 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 1 * PdfPageFormat.mm,
    );
    final items = [
      {'description': 'Chicken momo (full plate)', 'qty': 1, 'subtotal': 180.00},
      {'description': 'Veg Chowmein', 'qty': 2, 'subtotal': 240.00},
      {'description': 'Cold Drink', 'qty': 3, 'subtotal': 150.00},
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: customPageFormat,
        build: (pw.Context context) {
          return
            pw.SizedBox(
              width: 58 * PdfPageFormat.mm,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('Deskgoo Cafe',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Tax ID:', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('45678987', style: pw.TextStyle(fontSize: 8)),
                      ]),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Invoice:', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('SRN #123563', style: pw.TextStyle(fontSize: 8)),
                      ]),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Invoice Date:', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('${DateTime.now().toString().split('.')[0]}', style: pw.TextStyle(fontSize: 8)),
                      ]),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Customer:', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('Archana Acharya', style: pw.TextStyle(fontSize: 8)),
                      ]),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Table:', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('r1 (roof-top)', style: pw.TextStyle(fontSize: 8)),
                      ]),
                  pw.SizedBox(height: 5),

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

                  ...items.map((item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                          flex: 5,
                          child: pw.Text(item['description'] as String,
                              style: pw.TextStyle(fontSize: 8))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('${item['qty']}',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 8))),
                      pw.Expanded(
                          flex: 3,
                          child: pw.Text('${item['subtotal']}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 8))),
                    ],
                  )),
                  pw.SizedBox(height: 10),
                  dottedDivider(),
                  pw.SizedBox(height: 10),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total VAT:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('74.1', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Discount:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('0.00', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('644.1', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  dottedDivider(),
                  // pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child:
                    pw.Text('Thank you for visiting!',
                        style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                  ),
                ],
              ),
            );
        },
      ),
    );

    // Preview & print the generated PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
