import '../models/custom_tag.dart';

/// Repository interface for managing [CustomTag] domain objects.
abstract class TagRepository {
  /// Retrieves all customer-defined or default health tags.
  Future<List<CustomTag>> getTags();

  /// Adds a new custom tag with the given name.
  Future<void> addTag(String name);

  /// Removes a custom tag.
  Future<void> deleteTag(CustomTag tag);
}
