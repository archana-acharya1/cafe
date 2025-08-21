import 'package:hive/hive.dart';

part 'drawer_item_model.g.dart';

@HiveType(typeId: 3)
class DrawerItemModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String icon;

  DrawerItemModel({
    required this.title,
    required this.icon,
  });
}
