// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawer_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawerItemModelAdapter extends TypeAdapter<DrawerItemModel> {
  @override
  final int typeId = 3;

  @override
  DrawerItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawerItemModel(
      title: fields[0] as String,
      icon: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DrawerItemModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawerItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
