import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/table_model.dart';
import '../models/area_model.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

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
                title: Text(table.name),
                subtitle: Text("Area: ${table.area}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => table.delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddTableDialog(context),
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final nameController = TextEditingController();
    var areaBox = Hive.box<AreaModel>('areas');

    String? selectedArea;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Table"),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && selectedArea != null) {
                Hive.box<TableModel>('tables').add(
                  TableModel(
                    name: nameController.text.trim(),
                    area: selectedArea!,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
