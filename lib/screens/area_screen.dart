import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/area_model.dart';

class AreaScreen extends StatefulWidget {
  const AreaScreen({super.key});

  @override
  State<AreaScreen> createState() => _AreaScreenState();
}

class _AreaScreenState extends State<AreaScreen> {
  final Box<AreaModel> areaBox = Hive.box<AreaModel>('areas');
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }




  void _addOrEditArea({AreaModel? area}) {
    final nameController = TextEditingController(text: area?.name ?? '');
    String? imagePath = area?.imagePath;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final picked = await _picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                final docsDir = await getApplicationDocumentsDirectory();
                final imagesDir = Directory(p.join(docsDir.path, 'images'));
                if (!imagesDir.existsSync()) {
                  imagesDir.createSync(recursive: true);
                }

                final newPath = p.join(imagesDir.path, p.basename(picked.path));
                final newFile = await File(picked.path).copy(newPath);

                setModalState(() {
                  imagePath = newFile.path;
                });
              }
            }


            void removeImage() {
              setModalState(() {
                imagePath = null;
              });
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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.image),
                              onPressed: pickImage,
                            ),
                            if (imagePath != null)
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
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

  Future<void> _deleteArea(AreaModel area) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Area"),
        content: const Text("Are you sure you want to delete this area?"),
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

      if ( area.imagePath != null) {
        final file = File(area.imagePath!);
        if (await file.exists()){
          await file.delete();
        }
      }
     await area.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFF57C00);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(

        appBar: AppBar(
            title: const Text("Add Area",
            style: TextStyle(color: Colors.white,
            fontWeight:  FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: themeColor,
            elevation:2,

        ),
        body: ValueListenableBuilder(
          valueListenable: areaBox.listenable(),
          builder: (context, Box<AreaModel> box, _) {
            if (box.isEmpty) {
              return const Center(child: Text("No areas added yet."));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final area = box.getAt(index)!;
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          area.imagePath != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(area.imagePath!),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(Icons.map, size: 60),
                          const SizedBox(height: 6),
                          Text(
                            area.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                onPressed: () => _addOrEditArea(area: area),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _deleteArea(area),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          // onPressed: () => _addOrEditArea(),
          onPressed: () async => _addOrEditArea(),
        ),
      ),
    );
  }
}