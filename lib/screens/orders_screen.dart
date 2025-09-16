import 'package:deskgoo_cafe/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  bool selectionMode = false;
  final Set<dynamic> _selectedKeys = {};

  void _enterSelectionWith(dynamic key) {
    setState(() {
      selectionMode = true;
      _selectedKeys.add(key);
    });
  }

  void _toggleSelection(dynamic key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
        if (_selectedKeys.isEmpty) selectionMode = false;
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedKeys.clear();
      selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFF57C00);

    return WillPopScope(
      onWillPop: () async {
        if (selectionMode) {
          _clearSelection();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6EC),
        appBar: AppBar(
          title: selectionMode
              ? Text(
            "${_selectedKeys.length} selected",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          )
              : const Text(
            "Orders",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: themeColor,
          elevation: 2,
          leading: selectionMode
              ? IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _clearSelection,
          )
              : null,
          actions: selectionMode
              ? [
            IconButton(
              tooltip: "Select All (visible)",
              icon: const Icon(Icons.select_all, color: Colors.white),
              onPressed: () => _selectAllVisible(),
            ),
            IconButton(
              tooltip: "Print Selected",
              icon: const Icon(Icons.print, color: Colors.white),
              onPressed: () => _printSelected(),
            ),
            IconButton(
              tooltip: "Checkout Selected",
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: () => _checkoutSelected(),
            ),
          ]
              : [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
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

            final filtered = box.values.where((order) {
              if (fromDate != null) {
                final startOfFromDate =
                DateTime(fromDate!.year, fromDate!.month, fromDate!.day, 0, 0, 0);
                if (order.createdAt.isBefore(startOfFromDate)) return false;
              }
              if (toDate != null) {
                final endOfToDate =
                DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
                if (order.createdAt.isAfter(endOfToDate)) return false;
              }
              return true;
            }).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final double total = filtered.fold(0.0, (sum, o) => sum + o.totalAmount);
            final double paid = filtered
                .where((o) => o.paymentStatus == "Paid")
                .fold(0.0, (sum, o) => sum + o.totalAmount);
            final double due = total - paid;

            return Column(
              children: [
                if (fromDate != null || toDate != null)
                  _SummaryPanel.filtered(
                    fromDate: fromDate,
                    toDate: toDate,
                    total: total,
                    paid: paid,
                    due: due,
                  )
                else
                  _SummaryPanel.allTime(
                    total: total,
                    paid: paid,
                    due: due,
                  ),

                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final isSelected = _selectedKeys.contains(order.key);

                      return GestureDetector(
                        onLongPress: () => _enterSelectionWith(order.key),
                        onTap: () {
                          if (selectionMode) {
                            _toggleSelection(order.key);
                            return;
                          }
                          if (!order.isCheckedOut) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderScreen(order: order, isEdit: true),
                              ),
                            ).then((_) => setState(() {}));
                          }
                        },
                        child: Stack(
                          children: [
                            OrderCard(
                              order: order,
                              onCheckout: () async => await _onCheckoutPressed(order),
                              onUpdate: (updated) => setState(() {}),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 10,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            if (selectionMode && !isSelected)
                              Positioned(
                                top: 10,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.grey, size: 18),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String?> _askPaymentMethod() async {
    return await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text("Select Payment Method"),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, "Cash"),
              child: const Text("Cash"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, "Mobile Bankling"),
              child: const Text("Mobile Banking"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, "Card"),
              child: const Text("Card"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, "Other"),
              child: const Text("Other"),
            ),
          ],
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
              "Complete checkout for this order? What would you like to do with the record?"),
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

    final paymentMethod = await _askPaymentMethod();
    if (paymentMethod == null) return;

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
      order.paymentStatus = "Paid";
      order.paymentMethod = paymentMethod;
      await order.save();
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

  // ===================== MULTI-PRINT =====================
  Future<void> _printSelected() async {
    if (_selectedKeys.isEmpty) return;

    final ordersBox = Hive.box<OrderModel>('orders');
    final List<OrderModel> selectedOrders = ordersBox.values
        .where((o) => _selectedKeys.contains(o.key))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final doc = pw.Document();
    for (final o in selectedOrders) {
      doc.addPage(OrderCard.buildOrderPdfPage(o));
    }
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _checkoutSelected() async {
    if (_selectedKeys.isEmpty) return;

    final choice = await showDialog<_BulkAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Checkout ${_selectedKeys.length} selected?"),
        content: const Text(
            "Choose what to do with the checked-out orders:\n\n"
                "• Complete & Keep: marks as checked-out and keeps records.\n"
                "• Complete & Remove: deletes orders after checkout."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _BulkAction.cancel),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _BulkAction.keep),
            child: const Text("Complete & Keep"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _BulkAction.remove),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Complete & Remove"),
          ),
        ],
      ),
    );

    if (choice == null || choice == _BulkAction.cancel) return;

    final tableBox = Hive.box<TableModel>('tables');
    final ordersBox = Hive.box<OrderModel>('orders');
    final Map<String, TableModel> tableByName = {
      for (final t in tableBox.values) t.name: t
    };

    final List<OrderModel> toProcess =
    ordersBox.values.where((o) => _selectedKeys.contains(o.key)).toList();

    if (choice == _BulkAction.keep) {
      final method = await _askPaymentMethod();
      if (method == null) return;

      for (final o in toProcess) {
        final tbl = tableByName[o.tableName];
        if (tbl != null) {
          tbl.status = "Available";
          await tbl.save();
        }

        if (!o.isCheckedOut) {
          o.isCheckedOut = true;
          o.paymentStatus = "Paid";
          o.paymentMethod = method;
          await o.save();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout completed. Kept ${toProcess.length} record(s).")),
      );
    } else if (choice == _BulkAction.remove) {
      for (final o in toProcess) {
        final tbl = tableByName[o.tableName];
        if (tbl != null) {
          tbl.status = "Available";
          await tbl.save();
        }
        await o.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout completed. Removed ${toProcess.length} order(s).")),
      );
    }

    _clearSelection();
    setState(() {});
  }


  void _selectAllVisible() {
    final box = Hive.box<OrderModel>('orders');
    final visibleKeys = box.values.where((order) {
      if (fromDate != null) {
        final startOfFromDate =
        DateTime(fromDate!.year, fromDate!.month, fromDate!.day, 0, 0, 0);
        if (order.createdAt.isBefore(startOfFromDate)) return false;
      }
      if (toDate != null) {
        final endOfToDate =
        DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
        if (order.createdAt.isAfter(endOfToDate)) return false;
      }
      return true;
    }).map((o) => o.key);

    setState(() {
      selectionMode = true;
      _selectedKeys.addAll(visibleKeys);
    });
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
}

enum _CheckoutAction { cancel, completeKeep, completeRemove }
enum _BulkAction { cancel, keep, remove }

class _SummaryPanel extends StatelessWidget {
  final bool filtered;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double total;
  final double paid;
  final double due;

  const _SummaryPanel._({
    required this.filtered,
    required this.fromDate,
    required this.toDate,
    required this.total,
    required this.paid,
    required this.due,
    super.key,
  });

  factory _SummaryPanel.allTime({
    required double total,
    required double paid,
    required double due,
  }) {
    return _SummaryPanel._(
      filtered: false,
      fromDate: null,
      toDate: null,
      total: total,
      paid: paid,
      due: due,
    );
  }

  factory _SummaryPanel.filtered({
    required DateTime? fromDate,
    required DateTime? toDate,
    required double total,
    required double paid,
    required double due,
  }) {
    return _SummaryPanel._(
      filtered: true,
      fromDate: fromDate,
      toDate: toDate,
      total: total,
      paid: paid,
      due: due,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = filtered ? Colors.blueGrey.shade50 : Colors.green.shade50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filtered) ...[
            Text("From: ${_fmt(fromDate)}"),
            Text("To: ${_fmt(toDate)}"),
            const SizedBox(height: 6),
          ] else ...[
            const Text(
              "Showing All Time Transactions",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text("Total: Rs. ${total.toStringAsFixed(2)}"),
              Text("Paid: Rs. ${paid.toStringAsFixed(2)}"),
              Text("Due: Rs. ${due.toStringAsFixed(2)}"),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return "-";
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$yyyy-$mm-$dd";
  }
}