import '../../domain/models/custom_tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../storage/data_sources/tag_data_source.dart';

/// Implementation of [TagRepository] using Hive.
///
/// 🏛️ **Architecture**: Provides localized storage and management for
/// user-defined health categories. Interfaces with [TagDataSource] to handle
/// DTO mapping and persistence.
class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._dataSource);
  final TagDataSource _dataSource;

  @override
  Future<List<CustomTag>> getTags() async {
    return _dataSource.getCustomTags();
  }

  @override
  Future<void> saveTag(CustomTag tag) async {
    await _dataSource.saveTag(tag);
  }

  @override
  Future<void> deleteTag(CustomTag tag) async {
    await _dataSource.deleteCustomTag(tag);
  }
}
