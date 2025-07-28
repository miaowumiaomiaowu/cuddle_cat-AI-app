import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/providers/travel_provider.dart';
import 'package:cuddle_cat/models/travel.dart';

void main() {
  group('Travel Provider Tests', () {
    late TravelProvider travelProvider;

    setUp(() {
      travelProvider = TravelProvider();
    });

    test('TravelProvider should initialize with empty state', () {
      expect(travelProvider.travels, isEmpty);
      expect(travelProvider.isLoading, false);
      expect(travelProvider.selectedTravel, isNull);
    });

    test('TravelProvider should load travel records', () async {
      await travelProvider.loadTravels();

      expect(travelProvider.travels, isA<List<Travel>>());
      expect(travelProvider.isLoading, false);
    });

    test('TravelProvider should add new travel record', () async {
      final travel = Travel(
        id: 'test-travel-add',
        title: 'New Trip',
        description: 'A new travel record',
        location: 'New City',
        latitude: 40.7128,
        longitude: -74.0060,
        date: DateTime.now(),
        photos: ['new_photo.jpg'],
        tags: ['new', 'test'],
      );

      await travelProvider.addTravel(travel);

      expect(travelProvider.travels, contains(travel));
      expect(travelProvider.travels.any((t) => t.id == travel.id), true);
    });

    test('TravelProvider should update existing travel record', () async {
      final originalTravel = Travel(
        id: 'test-travel-update',
        title: 'Original Title',
        description: 'Original description',
        location: 'Original City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      );

      await travelProvider.addTravel(originalTravel);

      final updatedTravel = Travel(
        id: 'test-travel-update',
        title: 'Updated Title',
        description: 'Updated description',
        location: 'Updated City',
        latitude: 41.0,
        longitude: -75.0,
        date: originalTravel.date,
        photos: ['updated_photo.jpg'],
        tags: ['updated'],
      );

      await travelProvider.updateTravel(updatedTravel);

      final found =
          travelProvider.travels.firstWhere((t) => t.id == updatedTravel.id);
      expect(found.title, 'Updated Title');
      expect(found.description, 'Updated description');
      expect(found.location, 'Updated City');
      expect(found.photos, ['updated_photo.jpg']);
      expect(found.tags, ['updated']);
    });

    test('TravelProvider should delete travel record', () async {
      final travel = Travel(
        id: 'test-travel-delete',
        title: 'Delete Me',
        description: 'This will be deleted',
        location: 'Delete City',
        latitude: 35.0,
        longitude: 139.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      );

      await travelProvider.addTravel(travel);
      expect(travelProvider.travels.any((t) => t.id == travel.id), true);

      await travelProvider.deleteTravel(travel.id);
      expect(travelProvider.travels.any((t) => t.id == travel.id), false);
    });

    test('TravelProvider should select and deselect travel', () {
      final travel = Travel(
        id: 'test-travel-select',
        title: 'Select Me',
        description: 'Test selection',
        location: 'Select City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      );

      travelProvider.selectTravel(travel);
      expect(travelProvider.selectedTravel, travel);

      travelProvider.clearSelection();
      expect(travelProvider.selectedTravel, isNull);
    });

    test('TravelProvider should get travel statistics', () async {
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
        Travel(
          id: 'stats-3',
          title: 'Trip 3',
          description: 'Third trip',
          location: 'City A', // Same location as first
          latitude: 40.0,
          longitude: -74.0,
          date: DateTime.now().subtract(const Duration(days: 5)),
          photos: [],
          tags: ['city', 'return'],
        ),
      ];

      for (final travel in travels) {
        await travelProvider.addTravel(travel);
      }

      final stats = travelProvider.getTravelStatistics();

      expect(stats['totalTrips'], greaterThanOrEqualTo(3));
      expect(stats['totalPhotos'], greaterThanOrEqualTo(3));
      expect(stats['uniqueLocations'], greaterThanOrEqualTo(2));
      expect(stats['totalTags'], greaterThanOrEqualTo(5));
    });

    test('TravelProvider should filter travels by location', () async {
      final travels = [
        Travel(
          id: 'filter-1',
          title: 'Tokyo Trip',
          description: 'Trip to Tokyo',
          location: 'Tokyo',
          latitude: 35.6762,
          longitude: 139.6503,
          date: DateTime.now(),
          photos: [],
          tags: [],
        ),
        Travel(
          id: 'filter-2',
          title: 'New York Trip',
          description: 'Trip to New York',
          location: 'New York',
          latitude: 40.7128,
          longitude: -74.0060,
          date: DateTime.now(),
          photos: [],
          tags: [],
        ),
        Travel(
          id: 'filter-3',
          title: 'Another Tokyo Trip',
          description: 'Another trip to Tokyo',
          location: 'Tokyo',
          latitude: 35.6762,
          longitude: 139.6503,
          date: DateTime.now(),
          photos: [],
          tags: [],
        ),
      ];

      for (final travel in travels) {
        await travelProvider.addTravel(travel);
      }

      final tokyoTravels = travelProvider.getTravelsByLocation('Tokyo');
      expect(tokyoTravels.length, 2);
      expect(tokyoTravels.every((t) => t.location == 'Tokyo'), true);

      final newYorkTravels = travelProvider.getTravelsByLocation('New York');
      expect(newYorkTravels.length, 1);
      expect(newYorkTravels.first.location, 'New York');
    });

    test('TravelProvider should sort travels by date', () async {
      final now = DateTime.now();
      final travels = [
        Travel(
          id: 'sort-old',
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
          id: 'sort-new',
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
          id: 'sort-newest',
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

      for (final travel in travels) {
        await travelProvider.addTravel(travel);
      }

      final sortedTravels = travelProvider.getTravelsSortedByDate();

      // Should be sorted by date (newest first)
      for (int i = 0; i < sortedTravels.length - 1; i++) {
        expect(
          sortedTravels[i].date.isAfter(sortedTravels[i + 1].date) ||
              sortedTravels[i].date.isAtSameMomentAs(sortedTravels[i + 1].date),
          true,
        );
      }
    });

    test('TravelProvider should notify listeners on changes', () async {
      bool notified = false;
      travelProvider.addListener(() {
        notified = true;
      });

      await travelProvider.loadTravels();
      expect(notified, true);

      notified = false;
      final travel = Travel(
        id: 'notify-test',
        title: 'Notification Test',
        description: 'Test',
        location: 'Test City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      );

      await travelProvider.addTravel(travel);
      expect(notified, true);
    });

    test('TravelProvider should handle errors gracefully', () async {
      // Test with invalid travel data
      expect(() async {
        await travelProvider.addTravel(Travel(
          id: '',
          title: '',
          description: '',
          location: '',
          latitude: 0.0,
          longitude: 0.0,
          date: DateTime.now(),
          photos: [],
          tags: [],
        ));
      }, returnsNormally);

      // Test deleting non-existent travel
      expect(() async {
        await travelProvider.deleteTravel('non-existent-id');
      }, returnsNormally);
    });
  });
}
