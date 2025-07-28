import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/services/data_persistence_service.dart';
import 'package:cuddle_cat/models/cat.dart';
import 'package:cuddle_cat/models/travel.dart';

void main() {
  group('Data Persistence Integration Tests', () {
    late DataPersistenceService persistenceService;

    setUp(() {
      persistenceService = DataPersistenceService.getInstance();
    });

    test('Should persist and restore cat data', () async {
      final originalCat = Cat(
        id: 'persistence-test-cat',
        name: 'Persistent Whiskers',
        breed: 'Persian',
        color: 'White',
        happiness: 85,
        health: 90,
        energy: 75,
        hunger: 35,
        lastInteraction: DateTime.now(),
      );

      // Save cat data
      await persistenceService.saveCatData(originalCat);

      // Load cat data
      final loadedCat = await persistenceService.loadCatData();

      expect(loadedCat, isNotNull);
      expect(loadedCat!.id, originalCat.id);
      expect(loadedCat.name, originalCat.name);
      expect(loadedCat.breed, originalCat.breed);
      expect(loadedCat.color, originalCat.color);
      expect(loadedCat.happiness, originalCat.happiness);
      expect(loadedCat.health, originalCat.health);
      expect(loadedCat.energy, originalCat.energy);
      expect(loadedCat.hunger, originalCat.hunger);
      expect(loadedCat.lastInteraction, originalCat.lastInteraction);
    });

    test('Should persist and restore travel data', () async {
      final travels = [
        Travel(
          id: 'persist-travel-1',
          title: 'Persistent Trip 1',
          description: 'First persistent trip',
          location: 'Persistent City 1',
          latitude: 40.7128,
          longitude: -74.0060,
          date: DateTime.now().subtract(const Duration(days: 5)),
          photos: ['persistent_photo1.jpg'],
          tags: ['persistent', 'test'],
        ),
        Travel(
          id: 'persist-travel-2',
          title: 'Persistent Trip 2',
          description: 'Second persistent trip',
          location: 'Persistent City 2',
          latitude: 35.6762,
          longitude: 139.6503,
          date: DateTime.now().subtract(const Duration(days: 2)),
          photos: ['persistent_photo2.jpg', 'persistent_photo3.jpg'],
          tags: ['persistent', 'multi-photo'],
        ),
      ];

      // Save travel data
      await persistenceService.saveTravelData(travels);

      // Load travel data
      final loadedTravels = await persistenceService.loadTravelData();

      expect(loadedTravels.length, travels.length);

      for (int i = 0; i < travels.length; i++) {
        final original = travels[i];
        final loaded = loadedTravels.firstWhere((t) => t.id == original.id);

        expect(loaded.title, original.title);
        expect(loaded.description, original.description);
        expect(loaded.location, original.location);
        expect(loaded.latitude, original.latitude);
        expect(loaded.longitude, original.longitude);
        expect(loaded.photos, original.photos);
        expect(loaded.tags, original.tags);
      }
    });

    test('Should persist and restore dialogue history', () async {
      final dialogueHistory = [
        {
          'content': 'Hello, how are you?',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 10))
              .toIso8601String(),
        },
        {
          'content': 'I am doing well, thank you for asking! 😊',
          'isUser': false,
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 9))
              .toIso8601String(),
        },
        {
          'content': 'That\'s great to hear!',
          'isUser': true,
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 8))
              .toIso8601String(),
        },
      ];

      // Save dialogue history
      await persistenceService.saveDialogueHistory(dialogueHistory);

      // Load dialogue history
      final loadedHistory = await persistenceService.loadDialogueHistory();

      expect(loadedHistory.length, dialogueHistory.length);

      for (int i = 0; i < dialogueHistory.length; i++) {
        expect(loadedHistory[i]['content'], dialogueHistory[i]['content']);
        expect(loadedHistory[i]['isUser'], dialogueHistory[i]['isUser']);
        expect(loadedHistory[i]['timestamp'], dialogueHistory[i]['timestamp']);
      }
    });

    test('Should handle app state backup and restore', () async {
      final appState = {
        'version': '1.0.0',
        'lastLaunch': DateTime.now().toIso8601String(),
        'settings': {
          'theme': 'light',
          'notifications': true,
          'soundEnabled': false,
        },
        'statistics': {
          'totalInteractions': 150,
          'totalTravels': 25,
          'totalDialogues': 75,
        },
      };

      // Save app state
      await persistenceService.saveAppState(appState);

      // Load app state
      final loadedState = await persistenceService.loadAppState();

      expect(loadedState['version'], appState['version']);
      expect(loadedState['lastLaunch'], appState['lastLaunch']);
      expect(loadedState['settings'], appState['settings']);
      expect(loadedState['statistics'], appState['statistics']);
    });

    test('Should handle data migration between versions', () async {
      // Simulate old version data
      final oldVersionData = {
        'cat': {
          'name': 'Old Cat',
          'happiness': 50,
          'health': 60,
          // Missing new fields
        },
        'version': '0.9.0',
      };

      // Save old version data
      await persistenceService.saveAppState(oldVersionData);

      // Perform migration
      final migrated = await persistenceService.migrateDataIfNeeded();

      expect(migrated, true);

      // Load migrated data
      final migratedData = await persistenceService.loadAppState();
      expect(migratedData['version'], isNot('0.9.0')); // Should be updated
    });

    test('Should handle concurrent data access', () async {
      final cat = Cat(
        id: 'concurrent-test-cat',
        name: 'Concurrent Cat',
        breed: 'Siamese',
        color: 'Brown',
        happiness: 70,
        health: 80,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now(),
      );

      // Simulate concurrent save operations
      final futures = List.generate(
          10,
          (index) => persistenceService
              .saveCatData(cat.copyWith(happiness: 70 + index)));

      await Future.wait(futures);

      // Load final state
      final loadedCat = await persistenceService.loadCatData();
      expect(loadedCat, isNotNull);
      expect(loadedCat!.name, cat.name);
    });

    test('Should handle data corruption gracefully', () async {
      // Simulate corrupted data by saving invalid JSON
      await persistenceService.saveRawData('cat_data', 'invalid json {');

      // Should handle gracefully and return null or default
      final loadedCat = await persistenceService.loadCatData();
      // Should either be null or a default cat, not throw an exception
      expect(() => loadedCat, returnsNormally);
    });

    test('Should clear all data when requested', () async {
      // Save some data
      final cat = Cat(
        id: 'clear-test-cat',
        name: 'Clear Test Cat',
        breed: 'Bengal',
        color: 'Orange',
        happiness: 80,
        health: 90,
        energy: 70,
        hunger: 30,
        lastInteraction: DateTime.now(),
      );

      await persistenceService.saveCatData(cat);
      await persistenceService.saveTravelData([]);
      await persistenceService.saveDialogueHistory([]);

      // Clear all data
      await persistenceService.clearAllData();

      // Verify data is cleared
      final loadedCat = await persistenceService.loadCatData();
      final loadedTravels = await persistenceService.loadTravelData();
      final loadedHistory = await persistenceService.loadDialogueHistory();

      expect(loadedCat, isNull);
      expect(loadedTravels, isEmpty);
      expect(loadedHistory, isEmpty);
    });

    test('Should handle large data sets efficiently', () async {
      // Create large travel dataset
      final largeTravelSet = List.generate(
          1000,
          (index) => Travel(
                id: 'large-travel-$index',
                title: 'Trip $index',
                description: 'Description for trip $index',
                location: 'City $index',
                latitude: 40.0 + (index % 180),
                longitude: -74.0 + (index % 360),
                date: DateTime.now().subtract(Duration(days: index)),
                photos:
                    List.generate(index % 5, (i) => 'photo_${index}_$i.jpg'),
                tags: List.generate(index % 3, (i) => 'tag${index}_$i'),
              ));

      final stopwatch = Stopwatch()..start();

      // Save large dataset
      await persistenceService.saveTravelData(largeTravelSet);

      final saveTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      // Load large dataset
      final loadedTravels = await persistenceService.loadTravelData();

      final loadTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      expect(loadedTravels.length, largeTravelSet.length);
      expect(saveTime, lessThan(5000)); // Should save within 5 seconds
      expect(loadTime, lessThan(3000)); // Should load within 3 seconds

      print(
          'Large dataset performance: Save ${saveTime}ms, Load ${loadTime}ms');
    });
  });
}
