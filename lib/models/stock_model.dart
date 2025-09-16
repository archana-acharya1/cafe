 import 'package:hive/hive.dart';

 part 'stock_model.g.dart';

@HiveType(typeId: 11)
 class StockModel extends HiveObject {
  @HiveField(0)
  String itemName;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double pricePerUnit;

  @HiveField(4)
  double totalCost;

  @HiveField(5)
  DateTime purchasedAt;

  StockModel({
   required this.itemName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalCost,
    required this.purchasedAt,

});
}
