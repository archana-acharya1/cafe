import 'package:hive/hive.dart';
import 'order_item.dart';

part 'order_model.g.dart';

@HiveType(typeId: 7)
class OrderModel extends HiveObject {
  @HiveField(0)
  String tableName;

  @HiveField(1)
  String area;

  @HiveField(2)
  List<OrderItem> items;

  @HiveField(3)
  double totalAmount;

  @HiveField(4)
  double paidAmount;

  @HiveField(5)
  double dueAmount;

  @HiveField(6)
  String paymentStatus;

  @HiveField(7)
  String? customerName;

  @HiveField(8)
  double? discount;

  @HiveField(9)
  int? taxId;

  @HiveField(10)
  DateTime createdAt;


  OrderModel({
    required this.tableName,
    required this.area,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    this.customerName,
    this.discount,
    this.taxId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
