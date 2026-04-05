import '../../domain/models/custom_tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../storage/encrypted_storage_service.dart';

class TagRepositoryImpl implements TagRepository {
  final EncryptedStorageService _storage;

  TagRepositoryImpl(this._storage);

  @override
  Future<List<CustomTag>> getTags() async {
    return _storage.getCustomTags();
  }

  @override
  Future<void> addTag(String name) async {
    await _storage.addCustomTag(name);
  }

  @override
  Future<void> deleteTag(CustomTag tag) async {
    await _storage.deleteCustomTag(tag);
  }
}
