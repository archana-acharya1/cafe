import 'package:hive/hive.dart';

part 'order_item.g.dart';

@HiveType(typeId: 6)
class OrderItem extends HiveObject {
  @HiveField(0)
  String itemName;

  @HiveField(1)
  String unitName;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String? imagePath;

  OrderItem({
    required this.itemName,
    required this.unitName,
    required this.price,
    required this.quantity,
    this.imagePath,
  });
}
