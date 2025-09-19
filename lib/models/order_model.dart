import 'dart:convert';
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

  @HiveField(13)
  String? paymentMethod;

  @HiveField(14)
  String? note;

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
    this.paymentMethod,
    this.note,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tableName': tableName,
      'area': area,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'paymentStatus': paymentStatus,
      'customerName': customerName,
      'discount': discount,
      'taxId': taxId,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'note': note,
    };
  }
}


List<OrderResponseModel> orderResponseModelFromJson(String str) =>
    List<OrderResponseModel>.from(
        json.decode(str).map((x) => OrderResponseModel.fromJson(x)));

String orderResponseModelToJson(List<OrderResponseModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrderResponseModel {
  String? id;
  String? tableName;
  String? area;
  List<OrderItemResponse>? items;
  double? totalAmount;
  double? paidAmount;
  double? dueAmount;
  String? paymentStatus;
  String? customerName;
  double? discount;
  int? taxId;
  int? orderId;
  String? paymentMethod;
  String? note;
  bool? isCheckedOut;
  DateTime? createdAt;

  OrderResponseModel({
    this.id,
    this.tableName,
    this.area,
    this.items,
    this.totalAmount,
    this.paidAmount,
    this.dueAmount,
    this.paymentStatus,
    this.customerName,
    this.discount,
    this.taxId,
    this.orderId,
    this.paymentMethod,
    this.note,
    this.isCheckedOut,
    this.createdAt,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) =>
      OrderResponseModel(
        id: json["_id"],
        tableName: json["tableName"],
        area: json["area"],
        items: json["items"] == null
            ? []
            : List<OrderItemResponse>.from(
            (json["items"] as List).map((x) => OrderItemResponse.fromJson(x))),
        totalAmount: (json["totalAmount"] as num?)?.toDouble(),
        paidAmount: (json["paidAmount"] as num?)?.toDouble(),
        dueAmount: (json["dueAmount"] as num?)?.toDouble(),
        paymentStatus: json["paymentStatus"],
        customerName: json["customerName"],
        discount: (json["discount"] as num?)?.toDouble(),
        taxId: json["taxId"],
        orderId: json["orderId"],
        paymentMethod: json["paymentMethod"],
        note: json["note"],
        isCheckedOut: json["isCheckedOut"],
        createdAt: json["createdAt"] != null
            ? DateTime.tryParse(json["createdAt"])
            : null,
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "tableName": tableName,
    "area": area,
    "items": items?.map((x) => x.toJson()).toList(),
    "totalAmount": totalAmount,
    "paidAmount": paidAmount,
    "dueAmount": dueAmount,
    "paymentStatus": paymentStatus,
    "customerName": customerName,
    "discount": discount,
    "taxId": taxId,
    "orderId": orderId,
    "paymentMethod": paymentMethod,
    "note": note,
    "isCheckedOut": isCheckedOut,
    "createdAt": createdAt?.toIso8601String(),
  };
}

class OrderItemResponse {
  String? itemName;
  String? unitName;
  double? price;
  int? quantity;
  String? imagePath;

  OrderItemResponse({
    this.itemName,
    this.unitName,
    this.price,
    this.quantity,
    this.imagePath,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) =>
      OrderItemResponse(
        itemName: json["itemName"],
        unitName: json["unitName"],
        price: (json["price"] as num?)?.toDouble(),
        quantity: json["quantity"],
        imagePath: json["imagePath"],
      );

  Map<String, dynamic> toJson() => {
    "itemName": itemName,
    "unitName": unitName,
    "price": price,
    "quantity": quantity,
    "imagePath": imagePath,
  };
}
