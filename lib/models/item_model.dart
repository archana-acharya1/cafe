import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 1)
class ItemModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<UnitOption> units;

  @HiveField(2)
  bool isAvailable;

  ItemModel({
    required this.name,
    required this.units,
    required this.isAvailable,
  });
}

@HiveType(typeId: 8)
class UnitOption {
  @HiveField(0)
  String unitName;

  @HiveField(1)
  double price;

  UnitOption({
    required this.unitName,
    required this.price,
  });
}
