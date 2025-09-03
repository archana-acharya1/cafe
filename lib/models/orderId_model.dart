import 'package:hive/hive.dart';

part 'orderId_model.g.dart';  // <- this connects to the generated file

@HiveType(typeId: 10)
class OrderIdModel extends HiveObject {
  @HiveField(0)
  late int orderId;

  OrderIdModel({required this.orderId});
}