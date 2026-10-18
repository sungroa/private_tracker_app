import '../models/custom_tag.dart';
import '../repositories/tag_repository.dart';

/// Use case for permanently removing a custom tag.
///
/// 🎯 **Purpose**: Ensures that custom category teardowns are handled through
/// the domain layer to maintain state integrity.
///
/// 🧩 **Dependencies**:
/// - [TagRepository]: Repository for managing custom tags.
///
/// ⚡ **Execution**: Runs in the foreground.
class DeleteTagUseCase {
  DeleteTagUseCase(this._repository);
  final TagRepository _repository;

  Future<void> execute(CustomTag tag) async {
    await _repository.deleteTag(tag);
  }
}
