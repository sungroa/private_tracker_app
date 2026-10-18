import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/domain/models/custom_tag.dart';
import 'package:private_tracker_app/domain/repositories/tag_repository.dart';
import 'package:private_tracker_app/domain/usecases/add_tag_use_case.dart';
import 'package:private_tracker_app/domain/usecases/delete_tag_use_case.dart';

class MockTagRepository extends Mock implements TagRepository {}

void main() {
  late MockTagRepository mockRepository;
  late AddTagUseCase addTagUseCase;
  late DeleteTagUseCase deleteTagUseCase;

  setUpAll(() {
    registerFallbackValue(CustomTag(id: 'id', name: 'name', updatedAt: DateTime.now()));
  });

  setUp(() {
    mockRepository = MockTagRepository();
    addTagUseCase = AddTagUseCase(mockRepository);
    deleteTagUseCase = DeleteTagUseCase(mockRepository);
  });

  group('AddTagUseCase Tests', () {
    test('execute should save a new tag if name is unique', () async {
      when(() => mockRepository.getTags()).thenAnswer((_) async => []);
      when(() => mockRepository.saveTag(any())).thenAnswer((_) async {});

      await addTagUseCase.execute('New Tag');

      verify(
        () => mockRepository.saveTag(
          any(that: isA<CustomTag>().having((t) => t.name, 'name', 'New Tag')),
        ),
      ).called(1);
    });

    test('execute should not save if tag name already exists (case-insensitive)', () async {
      final existingTags = [CustomTag(id: '1', name: 'Exercise', updatedAt: DateTime.now())];
      when(() => mockRepository.getTags()).thenAnswer((_) async => existingTags);

      await addTagUseCase.execute('exercise'); // Lowercase version of existing

      verifyNever(() => mockRepository.saveTag(any()));
    });

    test('execute should trim whitespace when checking for duplicates', () async {
      final existingTags = [CustomTag(id: '1', name: 'Exercise', updatedAt: DateTime.now())];
      when(() => mockRepository.getTags()).thenAnswer((_) async => existingTags);

      await addTagUseCase.execute('  Exercise  ');

      verifyNever(() => mockRepository.saveTag(any()));
    });
  });

  group('DeleteTagUseCase Tests', () {
    test('execute should call repository delete', () async {
      final tag = CustomTag(id: 't1', name: 'Test', updatedAt: DateTime.now());
      when(() => mockRepository.deleteTag(any())).thenAnswer((_) async {});

      await deleteTagUseCase.execute(tag);

      verify(() => mockRepository.deleteTag(tag)).called(1);
    });
  });
}
