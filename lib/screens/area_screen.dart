import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/area_model.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box<AreaModel>('areas');

    return Scaffold(
      appBar: AppBar(title: const Text("Areas")),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<AreaModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No areas added yet."));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final area = box.getAt(index)!;
              return ListTile(
                title: Text(area.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => area.delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddAreaDialog(context),
      ),
    );
  }

  void _showAddAreaDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Area"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Area Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Hive.box<AreaModel>('areas')
                    .add(AreaModel(name: nameController.text.trim()));
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
