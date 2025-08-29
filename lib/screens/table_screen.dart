import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/table_model.dart';
import '../models/area_model.dart';
import 'package:image_picker/image_picker.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    var tableBox = Hive.box<TableModel>('tables');

    return Scaffold(
      appBar: AppBar(title: const Text("Tables")),
      body: ValueListenableBuilder(
        valueListenable: tableBox.listenable(),
        builder: (context, Box<TableModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No tables added yet."));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final table = box.getAt(index)!;
              return ListTile(
                leading: table.imagePath != null
                    ? Image.file(
                  File(table.imagePath!),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.table_chart),
                title: Text(table.name),
                subtitle: Text("Area: ${table.area}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddOrEditTableDialog(context, table: table),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTable(table),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddOrEditTableDialog(context),
      ),
    );
  }

  void _showAddOrEditTableDialog(BuildContext context, {TableModel? table}) {
    final nameController = TextEditingController(text: table?.name ?? '');
    var areaBox = Hive.box<AreaModel>('areas');
    String? selectedArea = table?.area;
    String? imagePath = table?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickImage() async {
            final picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              setModalState(() {
                imagePath = picked.path;
              });
            }
          }

          void removeImage() {
            setModalState(() {
              imagePath = null;
            });
          }

          return AlertDialog(
            title: Text(table == null ? "Add Table" : "Edit Table"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Table Name"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedArea,
                    hint: const Text("Select Area"),
                    items: areaBox.values.map((area) {
                      return DropdownMenuItem(
                        value: area.name,
                        child: Text(area.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedArea = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Table Image",
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
                              icon: const Icon(Icons.delete, color: Colors.red),
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty || selectedArea == null) return;

                  if (table == null) {
                    Hive.box<TableModel>('tables').add(
                      TableModel(name: name, area: selectedArea!, imagePath: imagePath),
                    );
                  } else {
                    table
                      ..name = name
                      ..area = selectedArea!
                      ..imagePath = imagePath
                      ..save();
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Table"),
        content: const Text("Are you sure you want to delete this table?"),
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
      table.delete();
    }
  }
}
