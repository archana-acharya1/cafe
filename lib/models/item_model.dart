import 'dart:convert';
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

  @HiveField(3)
  String? imagePath;

  ItemModel({
    required this.name,
    required this.units,
    required this.isAvailable,
    this.imagePath,
  });
}

@HiveType(typeId: 8)
class UnitOption extends HiveObject {
  @HiveField(0)
  String unitName;

  @HiveField(1)
  double price;

  UnitOption({
    required this.unitName,
    required this.price,
  });

  // local -> json helper (optional ho)
  Map<String, dynamic> toJson() => {
    'unitName': unitName,
    'price': price,
  };
}


List<ItemResponseModel> itemResponseModelFromJson(String str) =>
    List<ItemResponseModel>.from(
        json.decode(str).map((x) => ItemResponseModel.fromJson(x)));

String itemResponseModelToJson(List<ItemResponseModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ItemResponseModel {
  String? id;
  String? name;
  List<UnitOptionResponse>? units;
  bool? isAvailable;
  String? category;
  String? image;

  ItemResponseModel({
    this.id,
    this.name,
    this.units,
    this.isAvailable,
    this.category,
    this.image,
  });

  factory ItemResponseModel.fromJson(Map<String, dynamic> json) =>
      ItemResponseModel(
        id: json["_id"],
        name: json["name"],
        units: json["units"] == null
            ? []
            : List<UnitOptionResponse>.from(
            (json["units"] as List).map((x) => UnitOptionResponse.fromJson(x))),
        isAvailable: json["isAvailable"],
        category: json["category"],
        image: json["image"] ?? json["imagePath"],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "units": units?.map((x) => x.toJson()).toList(),
    "isAvailable": isAvailable,
    "category": category,
    "image": image,
  };
}

class UnitOptionResponse {
  String? unitName;
  double? price;

  UnitOptionResponse({
    this.unitName,
    this.price,
  });

  factory UnitOptionResponse.fromJson(Map<String, dynamic> json) =>
      UnitOptionResponse(
        unitName: json["unitName"],
        price: (json["price"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "unitName": unitName,
    "price": price,
  };
}
