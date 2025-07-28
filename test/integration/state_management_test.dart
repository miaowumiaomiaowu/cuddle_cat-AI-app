import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/providers/cat_provider.dart';
import 'package:cuddle_cat/providers/travel_provider.dart';
import 'package:cuddle_cat/providers/dialogue_provider.dart';
import 'package:cuddle_cat/services/app_state_manager.dart';
import 'package:cuddle_cat/models/cat.dart';
import 'package:cuddle_cat/models/travel.dart';

void main() {
  group('State Management Integration Tests', () {
    late AppStateManager stateManager;
    late CatProvider catProvider;
    late TravelProvider travelProvider;
    late DialogueProvider dialogueProvider;

    setUp(() {
      stateManager = AppStateManager();
      catProvider = CatProvider();
      travelProvider = TravelProvider();
      dialogueProvider = DialogueProvider();
    });

    test('Should coordinate state between providers', () async {
      // Initialize all providers
      await catProvider.loadCat();
      await travelProvider.loadTravels();
      await dialogueProvider.loadConversation();

      // Verify initial states
      expect(catProvider.currentCat, isNotNull);
      expect(travelProvider.travels, isA<List<Travel>>());
      expect(dialogueProvider.messages, isA<List>());

      // Test state coordination
      final cat = catProvider.currentCat!;
      dialogueProvider.setCatContext(cat);

      expect(dialogueProvider.catContext?.id, cat.id);
    });

    test('Should handle cross-provider state updates', () async {
      await catProvider.loadCat();
      await travelProvider.loadTravels();

      final initialCat = catProvider.currentCat!;
      final initialHappiness = initialCat.happiness;

      // Add a travel record (should potentially affect cat happiness)
      final travel = Travel(
        id: 'state-test-travel',
        title: 'Happy Trip',
        description: 'A trip that makes the cat happy',
        location: 'Happy City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: ['happy_photo.jpg'],
        tags: ['happy', 'adventure'],
      );

      await travelProvider.addTravel(travel);

      // Simulate state update that considers travel activity
      await catProvider.updateCatStats();

      // Cat state might be affected by travel activity
      expect(catProvider.currentCat, isNotNull);
      expect(catProvider.currentCat!.id, initialCat.id);
    });

    test('Should maintain state consistency during concurrent operations',
        () async {
      await catProvider.loadCat();

      // Perform multiple concurrent operations
      final futures = [
        catProvider.petCat(),
        catProvider.feedCat(),
        catProvider.playWithCat(),
      ];

      await Future.wait(futures);

      // State should remain consistent
      expect(catProvider.currentCat, isNotNull);
      expect(catProvider.currentCat!.happiness, greaterThanOrEqualTo(0));
      expect(catProvider.currentCat!.happiness, lessThanOrEqualTo(100));
      expect(catProvider.currentCat!.health, greaterThanOrEqualTo(0));
      expect(catProvider.currentCat!.health, lessThanOrEqualTo(100));
    });

    test('Should handle state persistence across app lifecycle', () async {
      // Initialize state
      await catProvider.loadCat();
      await travelProvider.loadTravels();

      final originalCat = catProvider.currentCat!;
      final originalTravelCount = travelProvider.travels.length;

      // Modify state
      await catProvider.petCat();
      await travelProvider.addTravel(Travel(
        id: 'lifecycle-test-travel',
        title: 'Lifecycle Test',
        description: 'Testing app lifecycle',
        location: 'Test City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      ));

      // Simulate app state save
      await stateManager.saveAppState();

      // Create new providers (simulating app restart)
      final newCatProvider = CatProvider();
      final newTravelProvider = TravelProvider();

      await newCatProvider.loadCat();
      await newTravelProvider.loadTravels();

      // State should be restored
      expect(newCatProvider.currentCat, isNotNull);
      expect(newCatProvider.currentCat!.id, originalCat.id);
      expect(newTravelProvider.travels.length, originalTravelCount + 1);
      expect(
          newTravelProvider.travels.any((t) => t.id == 'lifecycle-test-travel'),
          true);
    });

    test('Should handle state rollback on errors', () async {
      await catProvider.loadCat();

      final originalCat = catProvider.currentCat!;
      final originalHappiness = originalCat.happiness;

      try {
        // Simulate an operation that might fail
        await catProvider.petCat();

        // Force an error scenario
        throw Exception('Simulated error');
      } catch (e) {
        // State should be consistent even after error
        expect(catProvider.currentCat, isNotNull);
        expect(catProvider.currentCat!.id, originalCat.id);

        // Happiness might have changed before error, but should be valid
        expect(catProvider.currentCat!.happiness, greaterThanOrEqualTo(0));
        expect(catProvider.currentCat!.happiness, lessThanOrEqualTo(100));
      }
    });

    test('Should handle memory management efficiently', () async {
      // Load initial state
      await catProvider.loadCat();
      await travelProvider.loadTravels();
      await dialogueProvider.loadConversation();

      // Perform many operations to test memory usage
      for (int i = 0; i < 100; i++) {
        await catProvider.petCat();

        if (i % 10 == 0) {
          await travelProvider.addTravel(Travel(
            id: 'memory-test-$i',
            title: 'Memory Test $i',
            description: 'Testing memory usage',
            location: 'Memory City',
            latitude: 40.0,
            longitude: -74.0,
            date: DateTime.now(),
            photos: [],
            tags: [],
          ));
        }

        if (i % 5 == 0) {
          await dialogueProvider.sendMessage('Memory test message $i');
        }
      }

      // State should still be valid and responsive
      expect(catProvider.currentCat, isNotNull);
      expect(travelProvider.travels.length, greaterThan(10));
      expect(dialogueProvider.messages.length, greaterThan(20));
    });

    test('Should handle state validation and correction', () async {
      await catProvider.loadCat();

      // Manually corrupt state to test validation
      final corruptedCat = Cat(
        id: catProvider.currentCat!.id,
        name: catProvider.currentCat!.name,
        breed: catProvider.currentCat!.breed,
        color: catProvider.currentCat!.color,
        happiness: 150, // Invalid value
        health: -50, // Invalid value
        energy: 200, // Invalid value
        hunger: -100, // Invalid value
        lastInteraction: DateTime.now(),
      );

      catProvider.updateCatFromData(corruptedCat);

      // State should be automatically corrected
      expect(catProvider.currentCat!.happiness, lessThanOrEqualTo(100));
      expect(catProvider.currentCat!.health, greaterThanOrEqualTo(0));
      expect(catProvider.currentCat!.energy, lessThanOrEqualTo(100));
      expect(catProvider.currentCat!.hunger, greaterThanOrEqualTo(0));
    });

    test('Should handle provider disposal and cleanup', () async {
      await catProvider.loadCat();
      await travelProvider.loadTravels();
      await dialogueProvider.loadConversation();

      // Add listeners to test cleanup
      bool catNotified = false;
      bool travelNotified = false;
      bool dialogueNotified = false;

      catProvider.addListener(() => catNotified = true);
      travelProvider.addListener(() => travelNotified = true);
      dialogueProvider.addListener(() => dialogueNotified = true);

      // Trigger notifications
      await catProvider.petCat();
      await travelProvider.addTravel(Travel(
        id: 'cleanup-test',
        title: 'Cleanup Test',
        description: 'Testing cleanup',
        location: 'Cleanup City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      ));
      await dialogueProvider.sendMessage('Cleanup test');

      expect(catNotified, true);
      expect(travelNotified, true);
      expect(dialogueNotified, true);

      // Dispose providers
      catProvider.dispose();
      travelProvider.dispose();
      dialogueProvider.dispose();

      // Should handle disposal gracefully
      expect(() => catProvider.dispose(), returnsNormally);
    });

    test('Should handle state synchronization between multiple instances',
        () async {
      // Create multiple provider instances
      final catProvider1 = CatProvider();
      final catProvider2 = CatProvider();

      await catProvider1.loadCat();
      await catProvider2.loadCat();

      // Both should load the same cat
      expect(catProvider1.currentCat?.id, catProvider2.currentCat?.id);

      // Modify state in first provider
      await catProvider1.petCat();
      await catProvider1.saveCat();

      // Load state in second provider
      await catProvider2.loadCat();

      // States should be synchronized
      expect(catProvider2.currentCat?.happiness,
          catProvider1.currentCat?.happiness);
      expect(catProvider2.currentCat?.lastInteraction,
          catProvider1.currentCat?.lastInteraction);
    });

    test('Should handle complex state transitions', () async {
      await catProvider.loadCat();
      await travelProvider.loadTravels();
      await dialogueProvider.loadConversation();

      final initialCat = catProvider.currentCat!;
      dialogueProvider.setCatContext(initialCat);

      // Perform complex state transition
      await catProvider.feedCat(); // Changes cat state
      await dialogueProvider.sendMessage(
          'How do you feel after eating?'); // Uses updated cat context

      final travel = Travel(
        id: 'complex-transition-travel',
        title: 'Post-meal Walk',
        description: 'A walk after feeding the cat',
        location: 'Park',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: ['walk', 'post-meal'],
      );

      await travelProvider.addTravel(travel); // Adds travel record
      await catProvider.playWithCat(); // Further changes cat state

      // All states should be consistent
      expect(catProvider.currentCat, isNotNull);
      expect(
          travelProvider.travels
              .any((t) => t.id == 'complex-transition-travel'),
          true);
      expect(dialogueProvider.messages, isNotEmpty);
      expect(dialogueProvider.catContext?.id, catProvider.currentCat!.id);
    });
  });
}
