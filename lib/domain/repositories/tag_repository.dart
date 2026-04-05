import '../models/custom_tag.dart';

abstract class TagRepository {
  Future<List<CustomTag>> getTags();
  Future<void> addTag(String name);
  Future<void> deleteTag(CustomTag tag);
}
