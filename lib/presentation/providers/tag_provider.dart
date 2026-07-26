import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/custom_tag.dart';
import '../../domain/usecases/get_tags_use_case.dart';
import '../../domain/usecases/add_tag_use_case.dart';
import '../../domain/usecases/delete_tag_use_case.dart';
import 'cloud_sync_provider.dart';

/// State management provider for user-defined health categories (tags).
/// 
/// 🎨 **Presentation Architecture**: Manages the list of available tags for 
/// the logging interface, ensuring reactive UI updates when tags are added or 
/// deleted.
class TagProvider with ChangeNotifier {
  final GetTagsUseCase _getUseCase;
  final AddTagUseCase _addUseCase;
  final DeleteTagUseCase _deleteUseCase;
  CloudSyncProvider? _cloudSync;
  
  List<CustomTag> _tags = [];
  bool _isLoading = false;

  TagProvider(this._getUseCase, this._addUseCase, this._deleteUseCase, {
    this._cloudSync,
  });

  /// Allows late binding of the sync provider to avoid circular dependency.
  void attachSyncProvider(CloudSyncProvider cloudSync) {
    _cloudSync = cloudSync;
  }

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
      final rawTags = await _getUseCase.execute();
      
      // Safety deduplication: if the data layer has duplicates (e.g. before 
      // migration finishes), we ensure the UI only shows unique names.
      final seenNames = <String>{};
      _tags = rawTags.where((tag) {
        final normalized = tag.name.trim().toLowerCase();
        if (seenNames.contains(normalized)) return false;
        seenNames.add(normalized);
        return true;
      }).toList();

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
    _triggerSync();
  }

  Future<void> deleteTag(CustomTag tag) async {
    await _deleteUseCase.execute(tag);
    await refresh();
    _triggerSync();
  }

  /// Triggers a background sync without blocking the UI.
  ///
  /// Guards prevent sync from firing when a recovery passphrase is required
  /// ([requiresRecoveryPrompt]) or the local key cannot decrypt the cloud backup
  /// ([isOrphanKey]). Without these guards every data-write would trigger a
  /// CRITICAL FAILURE loop while the user hasn't entered their passphrase yet.
  void _triggerSync() {
    final sync = _cloudSync;
    if (sync != null &&
        sync.isCloudEnabled &&
        !sync.requiresRecoveryPrompt &&
        !sync.isOrphanKey) {
      unawaited(sync.sync());
    }
  }
}
