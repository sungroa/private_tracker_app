// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleEventAdapter extends TypeAdapter<CycleEvent> {
  @override
  final int typeId = 0;

  @override
  CycleEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleEvent(
      id: fields[3] == null ? '' : fields[3] as String?,
      startDate: fields[0] as DateTime,
      endDate: fields[1] as DateTime?,
      notes: fields[2] as String?,
      flowIntensity: fields[4] == null ? 3 : fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CycleEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.flowIntensity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
