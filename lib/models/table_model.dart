import 'package:hive/hive.dart';

part 'table_model.g.dart';

@HiveType(typeId: 5)
class TableModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String area;

  TableModel({
    required this.name,
    required this.area,
  });
}
