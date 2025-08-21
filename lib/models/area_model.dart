import 'package:hive/hive.dart';

part 'area_model.g.dart';

@HiveType(typeId: 4)
class AreaModel extends HiveObject {
  @HiveField(0)
  String name;

  AreaModel({required this.name});
}
