// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatHiveModelAdapter extends TypeAdapter<ChatHiveModel> {
  @override
  final int typeId = 0;

  @override
  ChatHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatHiveModel(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
