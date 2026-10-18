import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/repositories/tag_repository_impl.dart';
import 'package:private_tracker_app/data/storage/data_sources/tag_data_source.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';

class MockTagDataSource extends Mock implements TagDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(CustomTag(id: 'f', name: 'f', updatedAt: DateTime.now()));
  });

  late TagRepositoryImpl repository;
  late MockTagDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockTagDataSource();
    repository = TagRepositoryImpl(mockDataSource);
  });

  group('TagRepositoryImpl Tests', () {
    test('getTags should return all tags from data source', () async {
      final tags = [CustomTag(id: '1', name: 'T1', updatedAt: DateTime.now())];
      when(() => mockDataSource.getCustomTags()).thenAnswer((_) async => tags);

      final result = await repository.getTags();

      expect(result, tags);
    });

    test('saveTag should delegate to data source', () async {
      final tag = CustomTag(id: '1', name: 'T1', updatedAt: DateTime.now());
      when(() => mockDataSource.saveTag(any())).thenAnswer((_) async {});

      await repository.saveTag(tag);

      verify(() => mockDataSource.saveTag(tag)).called(1);
    });

    test('deleteTag should delegate to data source', () async {
      final tag = CustomTag(id: '1', name: 'T1', updatedAt: DateTime.now());
      when(() => mockDataSource.deleteCustomTag(any())).thenAnswer((_) async {});

      await repository.deleteTag(tag);

      verify(() => mockDataSource.deleteCustomTag(tag)).called(1);
    });
  });
}
