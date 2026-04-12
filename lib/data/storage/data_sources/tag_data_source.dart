import '../../../domain/models/custom_tag.dart';
import '../local_database_manager.dart';
import '../hive_dtos.dart';
import 'local_data_source.dart';

class TagDataSource extends LocalDataSource<CustomTagDto> {
  TagDataSource(LocalDatabaseManager dbManager) : super(dbManager, LocalDatabaseManager.customTagBox);

  List<CustomTag> getCustomTags() {
    return values.map((dto) => dto.toDomain()).toList();
  }

  Future<void> addCustomTag(String name) async {
    if (values.any((dto) => dto.name.toLowerCase() == name.toLowerCase())) {
      return;
    }
    final newTag = CustomTag(name: name);
    await put(newTag.id, CustomTagDto.fromDomain(newTag));
  }

  Future<void> deleteCustomTag(CustomTag tag) {
    return delete(tag.id);
  }
}
