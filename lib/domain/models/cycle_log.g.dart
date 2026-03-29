// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleLogAdapter extends TypeAdapter<CycleLog> {
  @override
  final int typeId = 0;

  @override
  CycleLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleLog(
      startDate: fields[0] as DateTime,
      endDate: fields[1] as DateTime?,
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CycleLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SymptomLogAdapter extends TypeAdapter<SymptomLog> {
  @override
  final int typeId = 1;

  @override
  SymptomLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SymptomLog(
      date: fields[0] as DateTime,
      symptoms: (fields[1] as List).cast<String>(),
      moodRating: fields[2] as int,
      notes: fields[3] as String?,
      basalBodyTemperature: fields[4] as double?,
      cervicalFluidType: fields[5] as String?,
      lhTestPositive: fields[6] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, SymptomLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.symptoms)
      ..writeByte(2)
      ..write(obj.moodRating)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.basalBodyTemperature)
      ..writeByte(5)
      ..write(obj.cervicalFluidType)
      ..writeByte(6)
      ..write(obj.lhTestPositive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
