import 'package:hive_flutter/hive_flutter.dart';
import '../local_database_manager.dart';

abstract class LocalDataSource<T> {
  final LocalDatabaseManager _dbManager;
  final String _boxName;

  LocalDataSource(this._dbManager, this._boxName);

  Box<T> get _box => _dbManager.getBox<T>(_boxName);

  T? get(String id) => _box.get(id);

  List<T> getAll() => _box.values.toList();

  Future<void> put(String id, T item) => _box.put(id, item);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  bool get isEmpty => _box.isEmpty;
  
  Iterable<T> get values => _box.values;
}
