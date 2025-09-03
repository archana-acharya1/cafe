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

    final List<_UnitRow> unitRows =
    (item?.units ?? [UnitOption(unitName: '', price: 0)])
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
              final savedImage = await File(picked.path).copy(
                p.join(imagesDir.path, fileName),
              );

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
            title: Text(item == null ? 'Add Item' : 'Edit Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: 8),
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
                      const Text(
                        "Units & Prices",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: addUnitRow,
                        icon: const Icon(Icons.add),
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
                                hintText: 'Unit name (Small, 250ml...)',
                                labelText: 'Unit',
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
                              ),
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ),
                          IconButton(
                            onPressed: () => removeUnitRow(i),
                            icon: const Icon(Icons.remove_circle_outline),
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image),
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
                      child: Image.file(
                        File(imagePath!),
                        height: 100,
                        fit: BoxFit.cover,
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
                        r.priceController.text
                            .trim()
                            .replaceAll(',', '')) ??
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
    return Scaffold(
      appBar: AppBar(title: const Text("Items")),
      body: ValueListenableBuilder(
        valueListenable: itemsBox.listenable(),
        builder: (context, Box<ItemModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No items added yet"));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final item = box.getAt(index)!;
              final unitsLabel = item.units
                  .map((u) => "${u.unitName}: ${u.price.toStringAsFixed(2)}")
                  .join("  •  ");

              return Card(
                child: ListTile(
                  leading: item.imagePath != null
                      ? Image.file(File(item.imagePath!),
                      width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood),
                  title: Text(item.name),
                  subtitle: Text(
                      "${item.isAvailable ? 'Available' : 'Not Available'}\n$unitsLabel"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _addOrEditItem(item: item)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(item)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditItem(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UnitRow {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _UnitRow({required this.nameController, required this.priceController});
}
