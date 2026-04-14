import 'package:flutter/foundation.dart';
import '../../domain/models/custom_tag.dart';
import '../../domain/usecases/get_tags_use_case.dart';
import '../../domain/usecases/add_tag_use_case.dart';
import '../../domain/usecases/delete_tag_use_case.dart';

/// State management provider for user-defined health categories (tags).
/// 
/// 🎨 **Presentation Architecture**: Manages the list of available tags for 
/// the logging interface, ensuring reactive UI updates when tags are added or 
/// deleted.
class TagProvider with ChangeNotifier {
  final GetTagsUseCase _getUseCase;
  final AddTagUseCase _addUseCase;
  final DeleteTagUseCase _deleteUseCase;
  
  List<CustomTag> _tags = [];
  bool _isLoading = false;

  TagProvider(this._getUseCase, this._addUseCase, this._deleteUseCase);

  Future<void> initialize() async {
    if (_tags.isNotEmpty || _isLoading) return;
    await refresh();
  }

  List<CustomTag> get tags => List.unmodifiable(_tags);
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _tags = await _getUseCase.execute();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("TagProvider: Failed to load tags: $e");
      _tags = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTag(String name) async {
    await _addUseCase.execute(name);
    await refresh();
  }

  Future<void> deleteTag(CustomTag tag) async {
    await _deleteUseCase.execute(tag);
    await refresh();
  }
}
