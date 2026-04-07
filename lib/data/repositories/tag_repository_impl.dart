import '../../domain/models/custom_tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../storage/data_sources/tag_data_source.dart';

class TagRepositoryImpl implements TagRepository {
  final TagDataSource _dataSource;

  TagRepositoryImpl(this._dataSource);

  @override
  Future<List<CustomTag>> getTags() async {
    return _dataSource.getCustomTags();
  }

  @override
  Future<void> addTag(String name) async {
    await _dataSource.addCustomTag(name);
  }

  @override
  Future<void> deleteTag(CustomTag tag) async {
    await _dataSource.deleteCustomTag(tag);
  }
}
