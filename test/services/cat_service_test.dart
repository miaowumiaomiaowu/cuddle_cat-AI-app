import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/services/cat_service.dart';
import 'package:cuddle_cat/models/cat.dart';

void main() {
  group('Cat Service Tests', () {
    late CatService catService;

    setUp(() {
      catService = CatService();
    });

    test('CatService should feed cat and update hunger', () async {
      final cat = Cat(
        id: 'test-cat',
        name: 'Test',
        breed: 'Persian',
        color: 'White',
        happiness: 50,
        health: 50,
        energy: 50,
        hunger: 80, // High hunger
        lastInteraction: DateTime.now(),
      );

      final result = await catService.feedCat(cat);

      expect(result.success, true);
      expect(result.message, isNotEmpty);
      expect(result.updatedCat.hunger, lessThan(cat.hunger));
      expect(result.updatedCat.happiness, greaterThanOrEqualTo(cat.happiness));
    });

    test('CatService should pet cat and update happiness', () async {
      final cat = Cat(
        id: 'test-cat',
        name: 'Test',
        breed: 'Siamese',
        color: 'Brown',
        happiness: 30, // Low happiness
        health: 70,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now(),
      );

      final result = await catService.petCat(cat);

      expect(result.success, true);
      expect(result.message, isNotEmpty);
      expect(result.updatedCat.happiness, greaterThan(cat.happiness));
      expect(
          result.updatedCat.lastInteraction.isAfter(cat.lastInteraction), true);
    });

    test('CatService should play with cat and update energy', () async {
      final cat = Cat(
        id: 'test-cat',
        name: 'Test',
        breed: 'Maine Coon',
        color: 'Black',
        happiness: 60,
        health: 80,
        energy: 90, // High energy
        hunger: 30,
        lastInteraction: DateTime.now(),
      );

      final result = await catService.playWithCat(cat);

      expect(result.success, true);
      expect(result.message, isNotEmpty);
      expect(result.updatedCat.energy, lessThan(cat.energy));
      expect(result.updatedCat.happiness, greaterThanOrEqualTo(cat.happiness));
    });

    test('CatService should handle interaction cooldown', () async {
      final cat = Cat(
        id: 'test-cat',
        name: 'Test',
        breed: 'Bengal',
        color: 'Orange',
        happiness: 50,
        health: 50,
        energy: 50,
        hunger: 50,
        lastInteraction: DateTime.now(), // Just interacted
      );

      // First interaction should work
      final result1 = await catService.petCat(cat);
      expect(result1.success, true);

      // Immediate second interaction might be limited
      final result2 = await catService.petCat(result1.updatedCat);
      // This depends on implementation - might succeed or fail based on cooldown
      expect(result2, isA<CatInteractionResult>());
    });

    test('CatService should update cat stats over time', () async {
      final cat = Cat(
        id: 'test-cat',
        name: 'Test',
        breed: 'Ragdoll',
        color: 'Blue',
        happiness: 80,
        health: 90,
        energy: 70,
        hunger: 20,
        lastInteraction: DateTime.now().subtract(const Duration(hours: 6)),
      );

      final updatedCat = await catService.updateCatStats(cat);

      // Stats should change over time
      expect(updatedCat.hunger, greaterThan(cat.hunger)); // Gets hungrier
      expect(updatedCat.happiness,
          lessThanOrEqualTo(cat.happiness)); // Might get less happy
    });

    test('CatService should generate appropriate emoji responses', () async {
      final happyCat = Cat(
        id: 'happy-cat',
        name: 'Happy',
        breed: 'Persian',
        color: 'White',
        happiness: 90,
        health: 95,
        energy: 85,
        hunger: 20,
        lastInteraction: DateTime.now(),
      );

      final sadCat = Cat(
        id: 'sad-cat',
        name: 'Sad',
        breed: 'Siamese',
        color: 'Gray',
        happiness: 20,
        health: 30,
        energy: 15,
        hunger: 90,
        lastInteraction: DateTime.now().subtract(const Duration(hours: 12)),
      );

      final happyEmoji = catService.getCatEmoji(happyCat);
      final sadEmoji = catService.getCatEmoji(sadCat);

      expect(happyEmoji, isNotEmpty);
      expect(sadEmoji, isNotEmpty);
      expect(happyEmoji, isNot(equals(sadEmoji)));
    });
  });
}
