import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/table_model.dart';

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'available':
      return Colors.green;
    case 'occupied':
      return Colors.red;
    case 'reserved':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

Future<void> updateTableStatusByName(String tableName, String status) async {
  final box = Hive.box<TableModel>('tables');
  for (final t in box.values) {
    if (t.name == tableName) {
      t.status = status;
      await t.save();
      break;
    }
  }
}
