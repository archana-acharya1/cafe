import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/order_model.dart';

class ReceiptGenerator {
  static Future<Uint8List> generateReceipt(OrderModel order) async {
    final pdf = pw.Document();

    final customPage = PdfPageFormat(10 * PdfPageFormat.mm, 50 * PdfPageFormat.mm, marginAll: 1.25 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        // pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5),
        pageFormat: customPage,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("My Restaurant",
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Thank you for dining with us!",
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 4),
                  ],
                ),
              ),
              pw.Divider(),

              pw.Text("Table: ${order.tableName} (${order.area})",
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),

              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total:",
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(order.totalAmount.toStringAsFixed(2),
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Status:", style: pw.TextStyle(fontSize: 10)),
                  pw.Text(order.paymentStatus, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Center(
                child: pw.Text("Powered by Flutter POS",
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
