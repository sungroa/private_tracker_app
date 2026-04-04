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
      id: fields[3] == null ? '' : fields[3] as String?,
      startDate: fields[0] as DateTime,
      endDate: fields[1] as DateTime?,
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CycleLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(3)
      ..write(obj.id)
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
      id: fields[7] == null ? '' : fields[7] as String?,
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
      ..writeByte(8)
      ..writeByte(7)
      ..write(obj.id)
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
