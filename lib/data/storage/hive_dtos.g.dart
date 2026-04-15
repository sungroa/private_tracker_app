// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_dtos.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleLogDtoAdapter extends TypeAdapter<CycleLogDto> {
  @override
  final int typeId = 10;

  @override
  CycleLogDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleLogDto(
      id: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime?,
      notes: fields[3] as String?,
      flowIntensity: fields[4] as int,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CycleLogDto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.flowIntensity)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleLogDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SymptomLogDtoAdapter extends TypeAdapter<SymptomLogDto> {
  @override
  final int typeId = 11;

  @override
  SymptomLogDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SymptomLogDto(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      symptoms: (fields[2] as List).cast<String>(),
      moodRating: fields[3] as int,
      notes: fields[4] as String?,
      basalBodyTemperature: fields[5] as double?,
      cervicalFluidType: fields[6] as String?,
      lhTestPositive: fields[7] as bool?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SymptomLogDto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.symptoms)
      ..writeByte(3)
      ..write(obj.moodRating)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.basalBodyTemperature)
      ..writeByte(6)
      ..write(obj.cervicalFluidType)
      ..writeByte(7)
      ..write(obj.lhTestPositive)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomLogDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomTagDtoAdapter extends TypeAdapter<CustomTagDto> {
  @override
  final int typeId = 12;

  @override
  CustomTagDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomTagDto(
      id: fields[0] as String,
      name: fields[1] as String,
      isDefault: fields[2] as bool,
      updatedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomTagDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isDefault)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTagDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
