// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orderId_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderIdModelAdapter extends TypeAdapter<OrderIdModel> {
  @override
  final int typeId = 10;

  @override
  OrderIdModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderIdModel(
      orderId: fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OrderIdModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.orderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderIdModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
