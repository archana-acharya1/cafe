import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import 'package:image_picker/image_picker.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final Box<ItemModel> itemsBox = Hive.box<ItemModel>('items');
  final ImagePicker _picker = ImagePicker();

  void _addOrEditItem({ItemModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    bool isAvailable = item?.isAvailable ?? true;
    String? imagePath = item?.imagePath;

    final List<_UnitRow> unitRows = (item?.units ?? [UnitOption(unitName: '', price: 0)])
        .map((u) => _UnitRow(
      nameController: TextEditingController(text: u.unitName),
      priceController:
      TextEditingController(text: u.price == 0 ? '' : u.price.toString()),
    ))
        .toList();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void addUnitRow() {
              setModalState(() {
                unitRows.add(_UnitRow(
                  nameController: TextEditingController(),
                  priceController: TextEditingController(),
                ));
              });
            }

            void removeUnitRow(int index) {
              setModalState(() {
                if (unitRows.length > 1) {
                  unitRows.removeAt(index);
                }
              });
            }

            Future<void> pickImage() async {
              final picked = await _picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setModalState(() {
                  imagePath = picked.path;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                item == null ? 'Add Item' : 'Edit Item',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Available"),
                        const SizedBox(width: 8),
                        Switch(
                          activeColor: Colors.green,
                          value: isAvailable,
                          onChanged: (val) => setModalState(() {
                            isAvailable = val;
                          }),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Units & Prices",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: addUnitRow,
                          icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                          label: const Text("Add Unit"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(unitRows.length, (i) {
                      final row = unitRows[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: row.nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Unit (Small, 250ml...)',
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: row.priceController,
                                decoration: const InputDecoration(
                                  hintText: 'Price',
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            IconButton(
                              onPressed: () => removeUnitRow(i),
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Item Image",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.orange),
                          onPressed: pickImage,
                        ),
                      ],
                    ),
                    if (imagePath != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(imagePath!),
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043), // orange accent
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final units = <UnitOption>[];
                    for (final r in unitRows) {
                      final uName = r.nameController.text.trim();
                      final price = double.tryParse(
                          r.priceController.text.trim().replaceAll(',', '')) ??
                          0;
                      if (uName.isNotEmpty && price > 0) {
                        units.add(UnitOption(unitName: uName, price: price));
                      }
                    }

                    if (units.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add at least one valid unit.')),
                      );
                      return;
                    }

                    if (item == null) {
                      itemsBox.add(ItemModel(
                        name: name,
                        units: units,
                        isAvailable: isAvailable,
                        imagePath: imagePath,
                      ));
                    } else {
                      item
                        ..name = name
                        ..units = units
                        ..isAvailable = isAvailable
                        ..imagePath = imagePath;
                      item.save();
                    }

                    Navigator.pop(context);
                  },
                  child: Text(item == null ? "Add" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteItem(ItemModel item) {
    item.delete();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF8B4513); // Coffee brown
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: Colors.white,
              title: const Text(
                'Exit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.red,
                ),
              ),
              content: const Text(
                'Are you sure you want to exit?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Yes"),
                ),
              ],
            );
          },
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6EC), // warm cream
        appBar: AppBar(
          title: const Text("Items"),
          centerTitle: true,
          backgroundColor: themeColor,
          elevation: 2,
        ),
        body: ValueListenableBuilder(
          valueListenable: itemsBox.listenable(),
          builder: (context, Box<ItemModel> box, _) {
            if (box.isEmpty) {
              return Center(
                child: Text(
                  "No items added yet",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final item = box.getAt(index)!;
                final unitsLabel = item.units
                    .map((u) => "${u.unitName}: ₹${u.price.toStringAsFixed(2)}")
                    .join("  •  ");

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imagePath != null
                          ? Image.file(
                        File(item.imagePath!),
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, color: Colors.brown),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "${item.isAvailable ? 'Available' : 'Not Available'}\n$unitsLabel",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _addOrEditItem(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFF7043),
          onPressed: () => _addOrEditItem(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _UnitRow {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _UnitRow({
    required this.nameController,
    required this.priceController,
  });
}
