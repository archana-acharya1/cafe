import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/orderId_model.dart';
import '../models/order_item.dart';
import '../models/order_model.dart';
import '../models/item_model.dart';
import '../models/table_model.dart';
import '../screens/orders_screen.dart';

class OrderScreen extends StatefulWidget {
  final String? initialTableName;
  final bool isEdit;
  final OrderModel? order;

  const OrderScreen({
    super.key,
    this.order,
    this.isEdit = false,
    this.initialTableName,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String? selectedTable;
  String? selectedArea;
  OrderModel? order;

  final List<OrderItem> orderItems = [];
  final Box<ItemModel> itemBox = Hive.box<ItemModel>('items');
  final Box<TableModel> tableBox = Hive.box<TableModel>('tables');

  double paidAmount = 0;
  String paymentStatus = "Paid";
  String? customerName;
  final TextEditingController _paidAmountController = TextEditingController();

  double get total =>
      orderItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  double get due => (total - paidAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();

    // Pre-select table if provided
    if (widget.initialTableName != null) {
      final table = tableBox.values.firstWhere(
            (t) => t.name == widget.initialTableName,
        orElse: () => tableBox.values.isNotEmpty
            ? tableBox.values.first
            : TableModel(name: "", area: ""),
      );
      selectedTable = table.name;
      selectedArea = table.area;
    }

    // Load existing order if editing
    if (widget.order != null) {
      order = widget.order;
      selectedTable = order!.tableName;
      selectedArea = order!.area;
      customerName = order!.customerName;
      paidAmount = order!.paidAmount ?? 0;
      paymentStatus = order!.paymentStatus ?? "Paid";
      orderItems.addAll(order!.items);
      _paidAmountController.text = paidAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<int> _getNextOrderId() async {
    final box = Hive.box<OrderIdModel>('orderId');
    if (box.isEmpty) {
      final orderIdModel = OrderIdModel(orderId: 1);
      await box.add(orderIdModel);
      return 1;
    } else {
      final orderIdModel = box.getAt(0)!;
      final nextId = (orderIdModel.orderId ?? 0) + 1;
      orderIdModel.orderId = nextId;
      await orderIdModel.save();
      return nextId;
    }
  }

  void _chooseUnitAndAdd(ItemModel item) async {
    final unit = await showDialog<_ChosenUnit>(
      context: context,
      builder: (_) => _SelectUnitDialog(item: item),
    );

    if (unit == null) return;

    setState(() {
      final idx = orderItems.indexWhere(
            (o) => o.itemName == item.name && o.unitName == unit.unitName,
      );
      if (idx != -1) {
        orderItems[idx].quantity += unit.qty;
      } else {
        orderItems.add(OrderItem(
          itemName: item.name,
          unitName: unit.unitName,
          price: unit.price,
          quantity: unit.qty,
          imagePath: item.imagePath,
        ));
      }
    });

    // update Paid Amount automatically if Paid selected
    if (paymentStatus == "Paid") {
      setState(() {
        paidAmount = total;
        _paidAmountController.text = total.toStringAsFixed(2);
      });
    }
  }

  Future<void> _updateOrder() async {
    if (selectedTable == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select table and items")),
      );
      return;
    }

    final existingOrder = widget.order;
    if (existingOrder != null) {
      existingOrder.tableName = selectedTable!;
      existingOrder.area = selectedArea ?? "";
      existingOrder.items = orderItems;
      existingOrder.totalAmount = total;
      existingOrder.paidAmount = paidAmount;
      existingOrder.dueAmount = due;
      existingOrder.paymentStatus = paymentStatus;
      existingOrder.customerName =
      paymentStatus == "Credit" ? customerName : null;

      await existingOrder.save();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order #${existingOrder.orderId} updated successfully!"),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OrdersScreen()),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (selectedTable == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select table and items")),
      );
      return;
    }

    final newOrderId = await _getNextOrderId();

    final createdOrder = OrderModel(
      orderId: newOrderId,
      tableName: selectedTable!,
      area: selectedArea ?? "",
      items: orderItems,
      totalAmount: total,
      paidAmount: paidAmount,
      dueAmount: due,
      paymentStatus: paymentStatus,
      customerName: paymentStatus == "Credit" ? customerName : null,
    );

    Hive.box<OrderModel>('orders').add(createdOrder);

    // update table status
    for (final t in tableBox.values) {
      if (t.name == selectedTable) {
        t.status = "Occupied";
        t.currentOrderId = createdOrder.orderId.toString();
        t.save();
        break;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order #$newOrderId placed successfully!")),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OrdersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableItems =
    itemBox.values.where((i) => i.isAvailable && i.units.isNotEmpty).toList();

    final themeColor = const Color(0xFFF57C00);
    final accentColor = const Color(0xFFFF7043);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: Text(
          widget.isEdit ? "Edit Order" : "New Order",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: "Table Selection",
              icon: Icons.table_restaurant,
              color: themeColor,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTable,
              decoration: _inputDecoration("Select Table"),
              items: tableBox.values.map((t) {
                return DropdownMenuItem(
                  value: t.name,
                  child: Text("${t.name} (${t.area})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTable = value;
                  selectedArea =
                      tableBox.values.firstWhere((t) => t.name == value).area;
                });
              },
            ),

            // ⚡ Available Items
            const SizedBox(height: 20),
            SectionHeader(
              title: "Available Items",
              icon: Icons.fastfood,
              color: themeColor,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableItems.length,
                itemBuilder: (context, index) {
                  final item = availableItems[index];

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _chooseUnitAndAdd(item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: item.imagePath != null
                                      ? Image.file(File(item.imagePath!),
                                      width: double.infinity,
                                      fit: BoxFit.cover)
                                      : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood,
                                        size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                  item.units
                                      .map((u) =>
                                  "${u.unitName} (${u.price.toStringAsFixed(2)})")
                                      .join(" • "),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ⚡ Order Items
            if (orderItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(
                title: "Your Order",
                icon: Icons.shopping_cart,
                color: themeColor,
              ),
              const SizedBox(height: 8),
              ...orderItems.map((o) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 2,
                child: ListTile(
                  leading: o.imagePath != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(o.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(Icons.fastfood, color: accentColor),
                  title: Text("${o.itemName} (${o.unitName})"),
                  subtitle: Text(
                    "Qty: ${o.quantity}  |  Price: ${o.price.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            if (o.quantity > 1) {
                              o.quantity--;
                            } else {
                              orderItems.remove(o);
                            }
                          });
                          if (paymentStatus == "Paid") {
                            setState(() {
                              paidAmount = total;
                              _paidAmountController.text =
                                  total.toStringAsFixed(2);
                            });
                          }
                        },
                      ),
                      Text("${o.quantity}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: accentColor),
                        onPressed: () {
                          setState(() {
                            o.quantity++;
                          });
                          if (paymentStatus == "Paid") {
                            setState(() {
                              paidAmount = total;
                              _paidAmountController.text =
                                  total.toStringAsFixed(2);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      "Rs.${total.toStringAsFixed(2)}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor),
                    ),
                  ],
                ),
              ),
            ],

            // ⚡ Payment Section
            const SizedBox(height: 20),
            SectionHeader(
              title: "Payment",
              icon: Icons.payment,
              color: themeColor,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _paidAmountController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration("Paid Amount"),
              onChanged: (val) {
                setState(() {
                  paidAmount = double.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: paymentStatus,
              decoration: _inputDecoration("Payment Status"),
              items: const ["Due", "Paid", "Credit"]
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  paymentStatus = val!;
                  if (paymentStatus == "Paid") {
                    paidAmount = total;
                    _paidAmountController.text = total.toStringAsFixed(2);
                  } else if (paymentStatus == "Due") {
                    paidAmount = 0;
                    _paidAmountController.clear();
                  }
                });
              },
            ),
            if (paymentStatus == "Credit")
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextFormField(
                  initialValue: customerName,
                  decoration: _inputDecoration("Customer Name"),
                  onChanged: (val) => setState(() => customerName = val),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: widget.isEdit ? _updateOrder : _placeOrder,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                widget.isEdit ? "Update Order" : "Place Order",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const SectionHeader(
      {required this.title, required this.icon, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _SelectUnitDialog extends StatefulWidget {
  final ItemModel item;
  const _SelectUnitDialog({required this.item});

  @override
  State<_SelectUnitDialog> createState() => _SelectUnitDialogState();
}

class _SelectUnitDialogState extends State<_SelectUnitDialog> {
  UnitOption? selected;
  int qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.item.units.isNotEmpty) {
      selected = widget.item.units.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add ${widget.item.name}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<UnitOption>(
            value: selected,
            items: widget.item.units
                .map((u) => DropdownMenuItem(
              value: u,
              child: Text("${u.unitName} (${u.price.toStringAsFixed(2)})"),
            ))
                .toList(),
            onChanged: (val) => setState(() => selected = val),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Qty"),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => setState(() {
                  if (qty > 1) qty--;
                }),
              ),
              Text("$qty"),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => qty++),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: selected == null
              ? null
              : () => Navigator.pop(
            context,
            _ChosenUnit(
              unitName: selected!.unitName,
              price: selected!.price,
              qty: qty,
            ),
          ),
          child: const Text("Add"),
        ),
      ],
    );
  }
}

class _ChosenUnit {
  final String unitName;
  final double price;
  final int qty;

  _ChosenUnit({
    required this.unitName,
    required this.price,
    required this.qty,
  });
}
