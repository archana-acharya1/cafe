import 'dart:convert';
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

List<TableResponseModel> tableResponseModelFromJson(String str) =>
    List<TableResponseModel>.from(
        json.decode(str).map((x) => TableResponseModel.fromJson(x)));

String tableResponseModelToJson(List<TableResponseModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TableResponseModel {
  String? id;
  String? name;
  String? area;
  String? imagePath;
  String? status;
  String? currentOrderId;

  TableResponseModel({
    this.id,
    this.name,
    this.area,
    this.imagePath,
    this.status,
    this.currentOrderId,
  });

  factory TableResponseModel.fromJson(Map<String, dynamic> json) =>
      TableResponseModel(
        id: json["_id"],
        name: json["name"],
        area: json["area"],
        imagePath: json["imagePath"],
        status: json["status"],
        currentOrderId: json["currentOrderId"],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "area": area,
    "imagePath": imagePath,
    "status": status,
    "currentOrderId": currentOrderId,
  };
}
