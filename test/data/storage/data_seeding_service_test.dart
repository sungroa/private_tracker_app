import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/data/storage/data_sources/data_seeding_service.dart';
import 'package:private_tracker_app/data/storage/hive_dtos.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class MockBox extends Mock implements Box<CustomTagDto> {}

void main() {
  late DataSeedingService service;
  late Box<CustomTagDto> tagBox;
  final tempDir = Directory.systemTemp.createTempSync('hive_test');

  setUpAll(() async {
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(12)) {
       Hive.registerAdapter(CustomTagDtoAdapter());
    }
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    service = DataSeedingService();
    // Use a real box for integration-like testing of the logic
    tagBox = await Hive.openBox<CustomTagDto>('test_tags_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDown(() async {
    await tagBox.close();
  });

  test('seedDefaultTags creates tags with deterministic IDs', () async {
    await service.seedDefaultTags(tagBox);

    expect(tagBox.length, equals(6));
    
    const uuid = Uuid();
    const namespace = 'a84d4b1a-8e2b-4b1a-9a2b-4b1a8e2b4b1a';
    
    // Verify one specific tag's ID
    final expectedId = uuid.v5(namespace, 'Cramps');
    expect(tagBox.containsKey(expectedId), isTrue);
    expect(tagBox.get(expectedId)!.name, equals('Cramps'));
  });

  test('seedDefaultTags cleans up old random-ID duplicates', () async {
    // 1. Pre-populate with a "random-ID" version of a default tag
    final randomId = const Uuid().v4();
    await tagBox.put(randomId, CustomTagDto(
      id: randomId,
      name: 'Cramps',
      isDefault: true,
      updatedAt: DateTime.now(),
    ));

    expect(tagBox.length, equals(1));
    expect(tagBox.containsKey(randomId), isTrue);

    // 2. Run seeding
    await service.seedDefaultTags(tagBox);

    // 3. Verify:
    // - Should have 6 tags total (all defaults)
    // - The random ID should be GONE
    // - The deterministic ID for 'Cramps' should be PRESENT
    expect(tagBox.length, equals(6));
    expect(tagBox.containsKey(randomId), isFalse, reason: 'Orphan default tag should be deleted');
    
    final deterministicId = const Uuid().v5('a84d4b1a-8e2b-4b1a-9a2b-4b1a8e2b4b1a', 'Cramps');
    expect(tagBox.containsKey(deterministicId), isTrue);
  });

  test('seedDefaultTags does NOT delete user-added custom tags', () async {
    const customId = 'user_custom_1';
    await tagBox.put(customId, CustomTagDto(
      id: customId,
      name: 'Migraine',
      isDefault: false,
      updatedAt: DateTime.now(),
    ));

    await service.seedDefaultTags(tagBox);

    expect(tagBox.length, equals(7)); // 6 defaults + 1 custom
    expect(tagBox.containsKey(customId), isTrue);
  });
}
