import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/models/cat.dart';

void main() {
  group('Cat Model Tests', () {
    test('Cat should be created with default values', () {
      final cat = Cat(
        id: 'test-cat-1',
        name: 'Fluffy',
        breed: 'Persian',
        color: 'White',
        happiness: 80,
        health: 90,
        energy: 70,
        hunger: 60,
        lastInteraction: DateTime.now(),
      );

      expect(cat.id, 'test-cat-1');
      expect(cat.name, 'Fluffy');
      expect(cat.breed, 'Persian');
      expect(cat.color, 'White');
      expect(cat.happiness, 80);
      expect(cat.health, 90);
      expect(cat.energy, 70);
      expect(cat.hunger, 60);
      expect(cat.lastInteraction, isA<DateTime>());
    });

    test('Cat should serialize to and from JSON correctly', () {
      final originalCat = Cat(
        id: 'test-cat-2',
        name: 'Whiskers',
        breed: 'Siamese',
        color: 'Brown',
        happiness: 75,
        health: 85,
        energy: 65,
        hunger: 55,
        lastInteraction: DateTime(2024, 1, 15, 10, 30),
      );

      final json = originalCat.toJson();
      final deserializedCat = Cat.fromJson(json);

      expect(deserializedCat.id, originalCat.id);
      expect(deserializedCat.name, originalCat.name);
      expect(deserializedCat.breed, originalCat.breed);
      expect(deserializedCat.color, originalCat.color);
      expect(deserializedCat.happiness, originalCat.happiness);
      expect(deserializedCat.health, originalCat.health);
      expect(deserializedCat.energy, originalCat.energy);
      expect(deserializedCat.hunger, originalCat.hunger);
      expect(deserializedCat.lastInteraction, originalCat.lastInteraction);
    });

    test('Cat should handle stat boundaries correctly', () {
      final cat = Cat(
        id: 'test-cat-3',
        name: 'Boundary',
        breed: 'Maine Coon',
        color: 'Black',
        happiness: 150, // Over 100
        health: -10, // Below 0
        energy: 50,
        hunger: 200, // Over 100
        lastInteraction: DateTime.now(),
      );

      // Values should be clamped to valid ranges
      expect(cat.happiness, lessThanOrEqualTo(100));
      expect(cat.health, greaterThanOrEqualTo(0));
      expect(cat.hunger, lessThanOrEqualTo(100));
    });

    test('Cat should calculate overall mood correctly', () {
      final happyCat = Cat(
        id: 'happy-cat',
        name: 'Happy',
        breed: 'Bengal',
        color: 'Orange',
        happiness: 90,
        health: 95,
        energy: 85,
        hunger: 20, // Low hunger is good
        lastInteraction: DateTime.now(),
      );

      final sadCat = Cat(
        id: 'sad-cat',
        name: 'Sad',
        breed: 'Persian',
        color: 'Gray',
        happiness: 20,
        health: 30,
        energy: 15,
        hunger: 90, // High hunger is bad
        lastInteraction: DateTime.now().subtract(const Duration(hours: 12)),
      );

      // Happy cat should have higher overall mood
      expect(happyCat.happiness > sadCat.happiness, true);
      expect(happyCat.health > sadCat.health, true);
      expect(happyCat.energy > sadCat.energy, true);
      expect(happyCat.hunger < sadCat.hunger, true);
    });
  });
}
