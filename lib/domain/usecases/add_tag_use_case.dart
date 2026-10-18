import 'package:uuid/uuid.dart';
import '../models/custom_tag.dart';
import '../repositories/tag_repository.dart';

/// Use case for adding a new user-defined custom tag.
///
/// 🎯 **Purpose**: New tags are initialized with a clean state (UUID and
/// current timestamp) to ensure strict domain-layer consistency.
///
/// 🧩 **Dependencies**:
/// - [TagRepository]: Repository for managing custom tags.
///
/// ⚡ **Execution**: Runs in the foreground.
class AddTagUseCase {
  AddTagUseCase(this._repository);
  final TagRepository _repository;

  /// Executes the addition of a tag with [name].
  ///
  /// Automatically generates a UUID v4 and a fresh [updatedAt] timestamp.
  /// Does not add the tag if a tag with the same name already exists.
  Future<void> execute(String name) async {
    final existingTags = await _repository.getTags();
    final normalizedNewName = name.trim().toLowerCase();

    if (existingTags.any((tag) => tag.name.trim().toLowerCase() == normalizedNewName)) {
      return;
    }

    // New tags are initialized with a modern timestamp and unique ID
    final tag = CustomTag(id: const Uuid().v4(), name: name, updatedAt: DateTime.now());
    await _repository.saveTag(tag);
  }
}
