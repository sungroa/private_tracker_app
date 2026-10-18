import 'package:private_tracker_app/core/registry/hive_registry.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';

import '../hive_dtos.dart';
import '../local_database_manager.dart';
import '../model_mapper.dart';
import 'local_data_source.dart';

class TagDataSource extends LocalDataSource<CustomTagDto> {
  TagDataSource(LocalDatabaseManager dbManager) : super(dbManager, HiveRegistry.customTagBox);

  Future<List<CustomTag>> getCustomTags() async {
    final dtos = await getAll();
    return dtos.map((dto) => ModelMapper.customTagFromDto(dto)).toList();
  }

  Future<void> saveTag(CustomTag tag) async {
    await put(tag.id, ModelMapper.customTagToDto(tag));
  }

  Future<void> deleteCustomTag(CustomTag tag) {
    return delete(tag.id);
  }
}
