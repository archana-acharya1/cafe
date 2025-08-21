// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 7;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      tableName: fields[0] as String,
      area: fields[1] as String,
      items: (fields[2] as List).cast<OrderItem>(),
      totalAmount: fields[3] as double,
      paidAmount: fields[4] as double,
      dueAmount: fields[5] as double,
      paymentStatus: fields[6] as String,
      customerName: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.tableName)
      ..writeByte(1)
      ..write(obj.area)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.paidAmount)
      ..writeByte(5)
      ..write(obj.dueAmount)
      ..writeByte(6)
      ..write(obj.paymentStatus)
      ..writeByte(7)
      ..write(obj.customerName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
