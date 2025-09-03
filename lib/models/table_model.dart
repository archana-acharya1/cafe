import 'package:hive/hive.dart';

part 'table_model.g.dart';

@HiveType(typeId: 5)
class TableModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String area;

  @HiveField(2)
  String? imagePath;

  @HiveField(3)
  String status;

  @HiveField(4)
  String? currentOrderId;

  TableModel({
    required this.name,
    required this.area,
    this.imagePath,
    this.status = "Available",
    this.currentOrderId,
  });
}
