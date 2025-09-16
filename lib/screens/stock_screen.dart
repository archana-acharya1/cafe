import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/stock_model.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final Box<StockModel> stockBox = Hive.box<StockModel>('stocks');
  DateTime? filterDate;

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFF57C00);
    final accentColor = const Color(0xFFFF7043);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text("Stock Manager",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: filterDate ?? DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => filterDate = picked);
              }
            },
          ),
          if (filterDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () => setState(() => filterDate = null),
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: stockBox.listenable(),
        builder: (context, Box<StockModel> box, _) {
          final stocks = box.values.toList();

          // Apply filter
          final filteredStocks = filterDate == null
              ? stocks
              : stocks.where((s) {
            return s.purchasedAt.year == filterDate!.year &&
                s.purchasedAt.month == filterDate!.month &&
                s.purchasedAt.day == filterDate!.day;
          }).toList();

          final totalValue = filteredStocks.fold(
              0.0, (sum, s) => sum + (s.quantity * s.pricePerUnit));

          if (filteredStocks.isEmpty) {
            return const Center(child: Text("No stock records found."));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  elevation: 3,
                  color: accentColor.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Stock Value:",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          "Rs.${totalValue.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredStocks.length,
                  itemBuilder: (context, index) {
                    final stock = filteredStocks[index];
                    final isOutOfStock = stock.quantity <= 0;
                    final isLowStock = stock.quantity > 0 && stock.quantity < 10;

                    if (isLowStock) {
                      Future.delayed(Duration.zero, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "⚠️ Low Stock: ${stock.itemName} (${stock.quantity} ${stock.unit})"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      });
                    }

                    return Card(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        title: Text(stock.itemName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                          isOutOfStock
                              ? "🚨 Out of Stock"
                              : "Qty: ${stock.quantity} ${stock.unit} "
                              "• Price/Unit: Rs.${stock.pricePerUnit.toStringAsFixed(2)}\n"
                              "Total: Rs.${stock.totalCost.toStringAsFixed(2)} • "
                              "Date: ${DateFormat('yyyy-MM-dd').format(stock.purchasedAt)}",
                          style: TextStyle(
                            fontSize: 13,
                            color: isOutOfStock
                                ? Colors.red
                                : (isLowStock ? Colors.orange : Colors.black),
                          ),
                        ),
                        trailing: isOutOfStock
                            ? const Icon(Icons.warning, color: Colors.red)
                            : IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.redAccent),
                          onPressed: () => _stockOutDialog(stock),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentColor,
        icon: const Icon(Icons.add),
        label: const Text("Add Stock"),
        onPressed: _showAddStockDialog,
      ),
    );
  }

  void _showAddStockDialog() {
    final itemController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Stock"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(labelText: "Item Name"),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: "Unit (kg/ltr/pcs)"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price per Unit"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final itemName = itemController.text.trim();
              final qty = double.tryParse(qtyController.text) ?? 0;
              final unit = unitController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0;
              final total = qty * price;

              if (itemName.isEmpty || qty <= 0 || price <= 0) return;

              final stock = StockModel(
                itemName: itemName,
                quantity: qty,
                unit: unit,
                pricePerUnit: price,
                totalCost: total,
                purchasedAt: DateTime.now(),
              );
              stockBox.add(stock);

              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _stockOutDialog(StockModel stock) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Use ${stock.itemName}"),
        content: TextField(
          controller: qtyController,
          decoration: InputDecoration(
              labelText: "Quantity to use (Available: ${stock.quantity})"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final usedQty = double.tryParse(qtyController.text) ?? 0;
              if (usedQty > 0 && usedQty <= stock.quantity) {
                setState(() {
                  stock.quantity -= usedQty;
                  stock.totalCost = stock.quantity * stock.pricePerUnit;
                  stock.save(); // keep record even if 0
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
