import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/area_model.dart';
import 'tables_by_area_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final areaBox = Hive.box<AreaModel>('areas');

    return Scaffold(
      appBar: AppBar(title: const Text("Areas")),
      body: ValueListenableBuilder(
        valueListenable: areaBox.listenable(),
        builder: (context, Box<AreaModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No areas added yet."));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final area = box.getAt(index)!;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TablesByAreaScreen(areaName: area.name),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      area.imagePath != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(area.imagePath!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Icon(Icons.map, size: 60),
                      const SizedBox(height: 8),
                      Text(
                        area.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
