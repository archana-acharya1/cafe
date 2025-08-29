import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/area_model.dart';

class AreaScreen extends StatefulWidget {
  const AreaScreen({super.key});

  @override
  State<AreaScreen> createState() => _AreaScreenState();
}

class _AreaScreenState extends State<AreaScreen> {
  final Box<AreaModel> areaBox = Hive.box<AreaModel>('areas');
  final ImagePicker _picker = ImagePicker();

  void _addOrEditArea({AreaModel? area}) {
    final nameController = TextEditingController(text: area?.name ?? '');
    String? imagePath = area?.imagePath;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final picked =
              await _picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setModalState(() {
                  imagePath = picked.path;
                });
              }
            }

            return AlertDialog(
              title: Text(area == null ? 'Add Area' : 'Edit Area'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                      const InputDecoration(labelText: 'Area Name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Area Image",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: pickImage,
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
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    if (area == null) {
                      areaBox.add(
                        AreaModel(name: name, imagePath: imagePath),
                      );
                    } else {
                      area
                        ..name = name
                        ..imagePath = imagePath;
                      area.save();
                    }

                    Navigator.pop(context);
                  },
                  child: Text(area == null ? "Add" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteArea(AreaModel area) {
    area.delete();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if (didPop) return;
        Navigator.pop(context);
      }),
      child: Scaffold(
        appBar: AppBar(title: const Text("Areas")),
        body: ValueListenableBuilder(
          valueListenable: areaBox.listenable(),
          builder: (context, Box<AreaModel> box, _) {
            if (box.isEmpty) {
              return const Center(child: Text("No areas added yet."));
            }
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final area = box.getAt(index)!;
                return Card(
                  child: ListTile(
                    leading: area.imagePath != null
                        ? Image.file(
                      File(area.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.map),
                    title: Text(area.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                          const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _addOrEditArea(area: area),
                        ),
                        IconButton(
                          icon:
                          const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteArea(area),
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
          child: const Icon(Icons.add),
          onPressed: () => _addOrEditArea(),
        ),
      ),
    );
  }
}
