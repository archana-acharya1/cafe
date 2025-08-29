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
