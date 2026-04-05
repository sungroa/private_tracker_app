import 'package:flutter/foundation.dart';
import '../../domain/models/custom_tag.dart';
import '../../domain/repositories/tag_repository.dart';

class TagProvider with ChangeNotifier {
  final TagRepository _repository;
  List<CustomTag> _tags = [];

  TagProvider(this._repository);

  List<CustomTag> get tags => List.unmodifiable(_tags);

  Future<void> refresh() async {
    _tags = await _repository.getTags();
    notifyListeners();
  }

  Future<void> addTag(String name) async {
    await _repository.addTag(name);
    await refresh();
  }

  Future<void> deleteTag(CustomTag tag) async {
    await _repository.deleteTag(tag);
    await refresh();
  }
}
