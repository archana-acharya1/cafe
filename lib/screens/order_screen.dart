import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/order_item.dart';
import '../models/order_model.dart';
import '../models/item_model.dart';
import '../models/table_model.dart';
import '../screens/orders_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String? selectedTable;
  String? selectedArea;

  final List<OrderItem> orderItems = [];
  final Box<ItemModel> itemBox = Hive.box<ItemModel>('items');
  final Box<TableModel> tableBox = Hive.box<TableModel>('tables');

  double paidAmount = 0;
  String paymentStatus = "Paid";
  String? customerName;

  double get total =>
      orderItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  double get due => (total - paidAmount).clamp(0, double.infinity);

  void _chooseUnitAndAdd(ItemModel item) async {
    final unit = await showDialog<_ChosenUnit>(
      context: context,
      builder: (_) => _SelectUnitDialog(item: item),
    );

    if (unit == null) return;

    setState(() {
      final idx = orderItems.indexWhere(
              (o) => o.itemName == item.name && o.unitName == unit.unitName);
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
  }

  void _placeOrder() {
    if (selectedTable == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select table and items")),
      );
      return;
    }

    Hive.box<OrderModel>('orders').add(
      OrderModel(
        tableName: selectedTable!,
        area: selectedArea ?? "",
        items: orderItems,
        totalAmount: total,
        paidAmount: paidAmount,
        dueAmount: due,
        paymentStatus: paymentStatus,
        customerName: paymentStatus == "Credit" ? customerName : null,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order placed successfully!")),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableItems =
    itemBox.values.where((i) => i.isAvailable && i.units.isNotEmpty).toList();

    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if (didPop) {
          return;
        }
        Navigator.pop(context);
      }),
      child: Scaffold(
        appBar: AppBar(title: const Text("New Order")),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Table selection
              DropdownButtonFormField<String>(
                hint: const Text("Select Table"),
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
              const SizedBox(height: 10),

              // Available items list
              Expanded(
                child: ListView.builder(
                  itemCount: availableItems.length,
                  itemBuilder: (context, index) {
                    final item = availableItems[index];
                    final units = item.units
                        .map((u) => "${u.unitName} (${u.price.toStringAsFixed(2)})")
                        .join(" • ");
                    return Card(
                      child: ListTile(
                        leading: item.imagePath != null
                            ? Image.file(
                          File(item.imagePath!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.fastfood),
                        title: Text(item.name),
                        subtitle: Text(units),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _chooseUnitAndAdd(item),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Selected order items list
              if (orderItems.isNotEmpty) ...[
                const Divider(),
                ...orderItems.map((o) => Card(
                  child: ListTile(
                    leading: o.imagePath != null
                        ? Image.file(
                      File(o.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.fastfood),
                    title: Text("${o.itemName} (${o.unitName})"),
                    subtitle: Text(
                        "Qty: ${o.quantity}  |  Price: ${o.price.toStringAsFixed(2)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (o.quantity > 1) {
                                o.quantity--;
                              } else {
                                orderItems.remove(o);
                              }
                            });
                          },
                        ),
                        Text("${o.quantity}"),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              o.quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                Text(
                  "Total: ${total.toStringAsFixed(2)}",
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],

              const Divider(),

              TextFormField(
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Paid Amount"),
                onChanged: (val) {
                  setState(() {
                    paidAmount = double.tryParse(val) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: paymentStatus,
                items: const ["Paid", "Due", "Credit"]
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    paymentStatus = val!;
                  });
                },
              ),
              if (paymentStatus == "Credit")
                TextFormField(
                  decoration: const InputDecoration(labelText: "Customer Name"),
                  onChanged: (val) => setState(() => customerName = val),
                ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _placeOrder,
                child: const Text("Place Order"),
              ),
            ],
          ),
        ),
      ),
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
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
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
