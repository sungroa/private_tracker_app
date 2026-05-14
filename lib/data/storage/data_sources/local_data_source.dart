import 'package:hive_flutter/hive_flutter.dart';
import '../local_database_manager.dart';

/// Base class for local data sources to standardize Hive box interactions.
/// 
/// Refactored to [Future]-based API to ensure "Technical Excellence":
/// 1. Adheres to asynchronous repository patterns.
/// 2. Decouples implementation from the specific in-memory nature of Hive.
abstract class LocalDataSource<T> {
  final LocalDatabaseManager _dbManager;
  final String _boxName;

  LocalDataSource(this._dbManager, this._boxName);

  /// Standard typed access to the underlying Hive box.
  Box<T> get box => _dbManager.getBox<T>(_boxName);

  /// Retrieves an item by its unique ID.
  Future<T?> get(String id) async => box.get(id);

  /// Retrieves all items in the store.
  Future<List<T>> getAll() async => box.values.toList();

  /// Persists a single item and updates the global modification metadata.
  Future<void> put(String id, T item) async {
    await box.put(id, item);
    await _dbManager.updateLastModified();
  }

  /// Batch puts items to minimize metadata update overhead.
  Future<void> putAll(Map<String, T> entries) async {
    await box.putAll(entries);
    await _dbManager.updateLastModified();
  }

  /// Deletes a single item and updates the global modification metadata.
  Future<void> delete(String id) async {
    await box.delete(id);
    await _dbManager.updateLastModified();
  }

  /// Batch deletes items.
  Future<void> deleteAll(Iterable<String> ids) async {
    await box.deleteAll(ids);
    await _dbManager.updateLastModified();
  }

  /// Wipes all data in this source.
  Future<void> clear() async {
    await box.clear();
    await _dbManager.updateLastModified();
  }

  /// Quick check for empty state.
  bool get isEmpty => box.isEmpty;
  
  /// Provides direct access to values (prefer getAll for async consistency).
  Iterable<T> get values => box.values;
}
