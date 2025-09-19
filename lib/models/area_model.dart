import 'dart:convert';

import 'package:hive/hive.dart';

part 'area_model.g.dart';

@HiveType(typeId: 4)
class AreaModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? imagePath;

  AreaModel({
    required this.name,
    this.imagePath,
  });
}


List<AreaResponseModel> areaResponseModelFromJson(String str) => List<AreaResponseModel>.from(json.decode(str).map((x) => AreaResponseModel.fromJson(x)));

String areaResponseModelToJson(List<AreaResponseModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AreaResponseModel {
  String? id;
  String? name;
  String? description;
  String? createdBy;
  String? createdByModel;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  AreaResponseModel({
    this.id,
    this.name,
    this.description,
    this.createdBy,
    this.createdByModel,
    this.createdAt,
    this.updatedAt,
  });

  factory AreaResponseModel.fromJson(Map<String, dynamic> json) => AreaResponseModel(
    id: json["_id"],
    name: json["name"],
    description: json["description"],
    createdBy: json["createdBy"],
    createdByModel: json["createdByModel"],
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "description": description,
    "createdBy": createdBy,
    "createdByModel": createdByModel,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
