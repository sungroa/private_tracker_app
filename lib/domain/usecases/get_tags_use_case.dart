import '../models/custom_tag.dart';
import '../repositories/tag_repository.dart';

/// Use case for retrieving all user-defined custom categories/tags.
/// 
/// 🎯 **Purpose**: Provides a clean, async stream of custom tags for UI-layer 
/// filtering and categorization.
/// 
/// 🧩 **Dependencies**:
/// - [TagRepository]: Repository for managing custom tags.
/// 
/// ⚡ **Execution**: Runs in the foreground.
class GetTagsUseCase {
  final TagRepository _repository;

  GetTagsUseCase(this._repository);

  Future<List<CustomTag>> execute() async {
    return await _repository.getTags();
  }
}
