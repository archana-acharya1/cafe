import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/table_model.dart';
import 'order_screen.dart';

class TablesByAreaScreen extends StatelessWidget {
  final String areaName;
  const TablesByAreaScreen({super.key, required this.areaName});

  @override
  Widget build(BuildContext context) {
    final tableBox = Hive.box<TableModel>('tables');

    return Scaffold(
      appBar: AppBar(title: Text("Tables in $areaName")),
      body: ValueListenableBuilder(
        valueListenable: tableBox.listenable(),
        builder: (context, Box<TableModel> box, _) {
          final tables = box.values.where((t) => t.area == areaName).toList();

          if (tables.isEmpty) {
            return const Center(child: Text("No tables in this area yet."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(
                        initialTableName: table.name,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        table.imagePath != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(table.imagePath!),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(Icons.table_chart, size: 60),
                        const SizedBox(height: 6),
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
}
