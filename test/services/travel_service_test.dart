import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/services/travel_service.dart';
import 'package:cuddle_cat/models/travel.dart';

void main() {
  group('Travel Service Tests', () {
    late TravelService travelService;

    setUp(() {
      travelService = TravelService();
    });

    test('TravelService should save and load travel records', () async {
      final travel = Travel(
        id: 'test-travel-1',
        title: 'Test Trip',
        description: 'A wonderful test trip',
        location: 'Test City',
        latitude: 40.7128,
        longitude: -74.0060,
        date: DateTime.now(),
        photos: ['test_photo.jpg'],
        tags: ['test', 'trip'],
      );

      // Save travel record
      await travelService.saveTravelRecord(travel);

      // Load travel records
      final travels = await travelService.loadTravelRecords();

      expect(travels, isNotEmpty);
      expect(travels.any((t) => t.id == travel.id), true);

      final savedTravel = travels.firstWhere((t) => t.id == travel.id);
      expect(savedTravel.title, travel.title);
      expect(savedTravel.description, travel.description);
      expect(savedTravel.location, travel.location);
      expect(savedTravel.latitude, travel.latitude);
      expect(savedTravel.longitude, travel.longitude);
      expect(savedTravel.photos, travel.photos);
      expect(savedTravel.tags, travel.tags);
    });

    test('TravelService should delete travel records', () async {
      final travel = Travel(
        id: 'test-travel-delete',
        title: 'Delete Test',
        description: 'This will be deleted',
        location: 'Delete City',
        latitude: 35.6762,
        longitude: 139.6503,
        date: DateTime.now(),
        photos: [],
        tags: ['delete'],
      );

      // Save and then delete
      await travelService.saveTravelRecord(travel);
      await travelService.deleteTravelRecord(travel.id);

      // Verify deletion
      final travels = await travelService.loadTravelRecords();
      expect(travels.any((t) => t.id == travel.id), false);
    });

    test('TravelService should handle multiple travel records', () async {
      final travels = List.generate(
          5,
          (index) => Travel(
                id: 'test-travel-$index',
                title: 'Trip $index',
                description: 'Description $index',
                location: 'City $index',
                latitude: 40.0 + index,
                longitude: -74.0 + index,
                date: DateTime.now().subtract(Duration(days: index)),
                photos: ['photo_$index.jpg'],
                tags: ['tag$index'],
              ));

      // Save all travels
      for (final travel in travels) {
        await travelService.saveTravelRecord(travel);
      }

      // Load and verify
      final loadedTravels = await travelService.loadTravelRecords();
      expect(loadedTravels.length, greaterThanOrEqualTo(travels.length));

      for (final travel in travels) {
        expect(loadedTravels.any((t) => t.id == travel.id), true);
      }
    });

    test('TravelService should sort travels by date', () async {
      final now = DateTime.now();
      final travels = [
        Travel(
          id: 'travel-old',
          title: 'Old Trip',
          description: 'Old',
          location: 'Old City',
          latitude: 40.0,
          longitude: -74.0,
          date: now.subtract(const Duration(days: 10)),
          photos: [],
          tags: [],
        ),
        Travel(
          id: 'travel-new',
          title: 'New Trip',
          description: 'New',
          location: 'New City',
          latitude: 41.0,
          longitude: -75.0,
          date: now.subtract(const Duration(days: 1)),
          photos: [],
          tags: [],
        ),
        Travel(
          id: 'travel-newest',
          title: 'Newest Trip',
          description: 'Newest',
          location: 'Newest City',
          latitude: 42.0,
          longitude: -76.0,
          date: now,
          photos: [],
          tags: [],
        ),
      ];

      // Save travels
      for (final travel in travels) {
        await travelService.saveTravelRecord(travel);
      }

      // Load and check sorting
      final loadedTravels = await travelService.loadTravelRecords();
      final relevantTravels = loadedTravels
          .where((t) =>
              ['travel-old', 'travel-new', 'travel-newest'].contains(t.id))
          .toList();

      expect(relevantTravels.length, 3);

      // Should be sorted by date (newest first)
      for (int i = 0; i < relevantTravels.length - 1; i++) {
        expect(
          relevantTravels[i].date.isAfter(relevantTravels[i + 1].date) ||
              relevantTravels[i]
                  .date
                  .isAtSameMomentAs(relevantTravels[i + 1].date),
          true,
        );
      }
    });

    test('TravelService should handle invalid data gracefully', () async {
      // Test with minimal valid data
      final minimalTravel = Travel(
        id: 'minimal-travel',
        title: '',
        description: '',
        location: '',
        latitude: 0.0,
        longitude: 0.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      );

      expect(() async => await travelService.saveTravelRecord(minimalTravel),
          returnsNormally);

      // Test loading when no data exists
      // Clear any existing data first by creating a new service instance
      final newService = TravelService();
      final emptyTravels = await newService.loadTravelRecords();
      expect(emptyTravels, isA<List<Travel>>());
    });

    test('TravelService should generate travel statistics', () async {
      final travels = [
        Travel(
          id: 'stats-1',
          title: 'Trip 1',
          description: 'First trip',
          location: 'City A',
          latitude: 40.0,
          longitude: -74.0,
          date: DateTime.now().subtract(const Duration(days: 30)),
          photos: ['photo1.jpg', 'photo2.jpg'],
          tags: ['adventure', 'city'],
        ),
        Travel(
          id: 'stats-2',
          title: 'Trip 2',
          description: 'Second trip',
          location: 'City B',
          latitude: 41.0,
          longitude: -75.0,
          date: DateTime.now().subtract(const Duration(days: 15)),
          photos: ['photo3.jpg'],
          tags: ['nature', 'hiking'],
        ),
      ];

      // Save travels
      for (final travel in travels) {
        await travelService.saveTravelRecord(travel);
      }

      final stats = await travelService.getTravelStatistics();

      expect(stats['totalTrips'], greaterThanOrEqualTo(2));
      expect(stats['totalPhotos'], greaterThanOrEqualTo(3));
      expect(stats['uniqueLocations'], greaterThanOrEqualTo(2));
      expect(stats, containsPair('totalTrips', isA<int>()));
      expect(stats, containsPair('totalPhotos', isA<int>()));
      expect(stats, containsPair('uniqueLocations', isA<int>()));
    });
  });
}
