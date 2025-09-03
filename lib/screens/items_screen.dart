import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
      priceController: TextEditingController(
          text: u.price == 0 ? '' : u.price.toString()),
    ))
        .toList();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickImage() async {
            final picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              final appDir = await getApplicationDocumentsDirectory();
              final imagesDir = Directory(p.join(appDir.path, 'item_images'));
              if (!await imagesDir.exists()) {
                await imagesDir.create(recursive: true);
              }
              final fileName = p.basename(picked.path);
              final savedImage =
              await File(picked.path).copy(p.join(imagesDir.path, fileName));
              setModalState(() {
                imagePath = savedImage.path;
              });
            }
          }

          void removeImage() {
            if (imagePath != null) {
              final file = File(imagePath!);
              if (file.existsSync()) {
                file.deleteSync();
              }
            }
            setModalState(() {
              imagePath = null;
            });
          }

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
              if (unitRows.length > 1) unitRows.removeAt(index);
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(item == null ? 'Add Item' : 'Edit Item'),
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
                      const Text("Units & Prices",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: addUnitRow,
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.orange),
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
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ),
                          IconButton(
                            onPressed: () => removeUnitRow(i),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Item Image",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.orange),
                            onPressed: pickImage,
                          ),
                          if (imagePath != null)
                            IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.red),
                              onPressed: removeImage,
                            ),
                        ],
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
                  child: const Text("Cancel")),
              ElevatedButton(
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
                      const SnackBar(
                          content: Text('Add at least one valid unit.')),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(item == null ? "Add" : "Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (item.imagePath != null) {
        final file = File(item.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await item.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const  Color(0xFF8B4520);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text("Add Items",
        style: TextStyle(color: Colors.white),
        ),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
                      child:
                      const Icon(Icons.fastfood, color: Colors.brown),
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
    );
  }
}

class _UnitRow {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _UnitRow({required this.nameController, required this.priceController});
}
