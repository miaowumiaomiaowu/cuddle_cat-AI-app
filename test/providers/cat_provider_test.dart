import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/providers/cat_provider.dart';
import 'package:cuddle_cat/models/cat.dart';

void main() {
  group('Cat Provider Tests', () {
    late CatProvider catProvider;

    setUp(() {
      catProvider = CatProvider();
    });

    test('CatProvider should initialize with default state', () {
      expect(catProvider.currentCat, isNull);
      expect(catProvider.isLoading, false);
      expect(catProvider.lastInteractionTime, isNull);
    });

    test('CatProvider should load cat data', () async {
      await catProvider.loadCat();

      expect(catProvider.currentCat, isNotNull);
      expect(catProvider.currentCat!.name, isNotEmpty);
      expect(catProvider.currentCat!.breed, isNotEmpty);
      expect(catProvider.isLoading, false);
    });

    test('CatProvider should handle cat interactions', () async {
      await catProvider.loadCat();
      final initialCat = catProvider.currentCat!;
      final initialHappiness = initialCat.happiness;

      // Test petting interaction
      await catProvider.petCat();

      expect(catProvider.currentCat!.happiness,
          greaterThanOrEqualTo(initialHappiness));
      expect(catProvider.lastInteractionTime, isNotNull);
      expect(
          catProvider.currentCat!.lastInteraction
              .isAfter(initialCat.lastInteraction),
          true);
    });

    test('CatProvider should handle feeding interaction', () async {
      await catProvider.loadCat();
      final initialCat = catProvider.currentCat!;
      final initialHunger = initialCat.hunger;

      // Test feeding interaction
      await catProvider.feedCat();

      expect(catProvider.currentCat!.hunger, lessThanOrEqualTo(initialHunger));
      expect(catProvider.lastInteractionTime, isNotNull);
    });

    test('CatProvider should handle playing interaction', () async {
      await catProvider.loadCat();
      final initialCat = catProvider.currentCat!;
      final initialEnergy = initialCat.energy;

      // Test playing interaction
      await catProvider.playWithCat();

      expect(catProvider.currentCat!.energy, lessThanOrEqualTo(initialEnergy));
      expect(catProvider.lastInteractionTime, isNotNull);
    });

    test('CatProvider should save cat state', () async {
      await catProvider.loadCat();
      final originalCat = catProvider.currentCat!;

      // Modify cat state
      await catProvider.petCat();
      final modifiedCat = catProvider.currentCat!;

      // Save state
      await catProvider.saveCat();

      // Create new provider and load
      final newProvider = CatProvider();
      await newProvider.loadCat();

      expect(newProvider.currentCat!.happiness, modifiedCat.happiness);
      expect(
          newProvider.currentCat!.lastInteraction, modifiedCat.lastInteraction);
    });

    test('CatProvider should update cat stats over time', () async {
      await catProvider.loadCat();
      final initialCat = catProvider.currentCat!;

      // Simulate time passing
      final oldCat = Cat(
        id: initialCat.id,
        name: initialCat.name,
        breed: initialCat.breed,
        color: initialCat.color,
        happiness: initialCat.happiness,
        health: initialCat.health,
        energy: initialCat.energy,
        hunger: initialCat.hunger,
        lastInteraction: DateTime.now().subtract(const Duration(hours: 6)),
      );

      catProvider.updateCatFromData(oldCat);
      await catProvider.updateCatStats();

      // Stats should have changed due to time passage
      expect(catProvider.currentCat!.hunger, greaterThan(oldCat.hunger));
    });

    test('CatProvider should handle errors gracefully', () async {
      // Test loading with no saved data
      final newProvider = CatProvider();
      await newProvider.loadCat();

      // Should create a default cat
      expect(newProvider.currentCat, isNotNull);
      expect(newProvider.isLoading, false);
    });

    test('CatProvider should notify listeners on state changes', () async {
      bool notified = false;
      catProvider.addListener(() {
        notified = true;
      });

      await catProvider.loadCat();
      expect(notified, true);

      notified = false;
      await catProvider.petCat();
      expect(notified, true);
    });

    test('CatProvider should get appropriate cat emoji', () async {
      await catProvider.loadCat();

      final emoji = catProvider.getCatEmoji();
      expect(emoji, isNotEmpty);
      expect(emoji.length, greaterThan(0));
    });

    test('CatProvider should handle interaction cooldowns', () async {
      await catProvider.loadCat();

      // Perform interaction
      await catProvider.petCat();
      final firstInteractionTime = catProvider.lastInteractionTime;

      // Immediate second interaction
      await catProvider.petCat();
      final secondInteractionTime = catProvider.lastInteractionTime;

      // Should handle cooldown appropriately
      expect(secondInteractionTime, isNotNull);
      expect(firstInteractionTime, isNotNull);
    });
  });
}
