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

  @HiveField(11)
  bool isCheckedOut;

  @HiveField(12)
  int? orderId;

  OrderModel({
    this.orderId = 0,
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
    this.isCheckedOut = false,

  }) : createdAt = createdAt ?? DateTime.now();
    required this.orderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'tableName': tableName,
      'area': area,
      'items': items.map((item) => {
        'itemName': item.itemName,
        'unitName': item.unitName,
        'price': item.price,
        'quantity': item.quantity,
        'imagePath': item.imagePath,
      }).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'paymentStatus': paymentStatus,
      'customerName': customerName,
      'discount': discount,
      'taxId': taxId,
      'orderId': orderId,
    };
  }
}
