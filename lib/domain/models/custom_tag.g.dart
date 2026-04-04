// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_tag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomTagAdapter extends TypeAdapter<CustomTag> {
  @override
  final int typeId = 2;

  @override
  CustomTag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomTag(
      id: fields[2] == null ? '' : fields[2] as String?,
      name: fields[0] as String,
      isDefault: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CustomTag obj) {
    writer
      ..writeByte(3)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
