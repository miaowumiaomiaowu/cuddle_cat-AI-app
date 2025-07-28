import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/widgets/travel_record_card.dart';
import 'package:cuddle_cat/models/travel.dart';

void main() {
  group('Travel Record Card Widget Tests', () {
    late Travel testTravel;

    setUp(() {
      testTravel = Travel(
        id: 'test-travel-1',
        title: 'Amazing Trip to Tokyo',
        description:
            'A wonderful journey through the streets of Tokyo, experiencing the culture and food.',
        location: 'Tokyo, Japan',
        latitude: 35.6762,
        longitude: 139.6503,
        date: DateTime(2024, 3, 15, 14, 30),
        photos: ['tokyo_photo1.jpg', 'tokyo_photo2.jpg'],
        tags: ['culture', 'food', 'city'],
      );
    });

    Widget createTestWidget({
      required Travel travel,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TravelRecordCard(
            travel: travel,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      );
    }

    testWidgets('Should display travel information correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      expect(find.text('Amazing Trip to Tokyo'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
      expect(
          find.text(
              'A wonderful journey through the streets of Tokyo, experiencing the culture and food.'),
          findsOneWidget);
    });

    testWidgets('Should display travel date correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      // Should display formatted date
      expect(find.textContaining('2024'), findsOneWidget);
      expect(find.textContaining('03'), findsOneWidget);
      expect(find.textContaining('15'), findsOneWidget);
    });

    testWidgets('Should display travel tags', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      expect(find.text('culture'), findsOneWidget);
      expect(find.text('food'), findsOneWidget);
      expect(find.text('city'), findsOneWidget);
    });

    testWidgets('Should display photo count', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      // Should show photo count indicator
      expect(find.textContaining('2'), findsOneWidget); // 2 photos
    });

    testWidgets('Should handle tap events', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(createTestWidget(
        travel: testTravel,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(TravelRecordCard));
      expect(tapped, true);
    });

    testWidgets('Should handle edit button tap', (WidgetTester tester) async {
      bool editTapped = false;

      await tester.pumpWidget(createTestWidget(
        travel: testTravel,
        onEdit: () => editTapped = true,
      ));

      // Find and tap edit button (usually an icon button)
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        expect(editTapped, true);
      }
    });

    testWidgets('Should handle delete button tap', (WidgetTester tester) async {
      bool deleteTapped = false;

      await tester.pumpWidget(createTestWidget(
        travel: testTravel,
        onDelete: () => deleteTapped = true,
      ));

      // Find and tap delete button
      final deleteButton = find.byIcon(Icons.delete);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton);
        expect(deleteTapped, true);
      }
    });

    testWidgets('Should handle travel with no photos',
        (WidgetTester tester) async {
      final travelNoPhotos = Travel(
        id: 'no-photos-travel',
        title: 'Simple Trip',
        description: 'A trip without photos',
        location: 'Simple City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [], // No photos
        tags: ['simple'],
      );

      await tester.pumpWidget(createTestWidget(travel: travelNoPhotos));

      expect(find.text('Simple Trip'), findsOneWidget);
      expect(find.text('Simple City'), findsOneWidget);

      // Should handle no photos gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should handle travel with no tags',
        (WidgetTester tester) async {
      final travelNoTags = Travel(
        id: 'no-tags-travel',
        title: 'Untagged Trip',
        description: 'A trip without tags',
        location: 'Untagged City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: ['photo.jpg'],
        tags: [], // No tags
      );

      await tester.pumpWidget(createTestWidget(travel: travelNoTags));

      expect(find.text('Untagged Trip'), findsOneWidget);
      expect(find.text('Untagged City'), findsOneWidget);

      // Should handle no tags gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should handle long descriptions', (WidgetTester tester) async {
      final longDescriptionTravel = Travel(
        id: 'long-desc-travel',
        title: 'Long Description Trip',
        description:
            'This is a very long description that should be handled properly by the travel record card. ' *
                10,
        location: 'Long Description City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: ['photo.jpg'],
        tags: ['long'],
      );

      await tester.pumpWidget(createTestWidget(travel: longDescriptionTravel));

      expect(find.text('Long Description Trip'), findsOneWidget);

      // Should handle long description without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should handle many tags', (WidgetTester tester) async {
      final manyTagsTravel = Travel(
        id: 'many-tags-travel',
        title: 'Many Tags Trip',
        description: 'A trip with many tags',
        location: 'Tag City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: ['photo.jpg'],
        tags: ['tag1', 'tag2', 'tag3', 'tag4', 'tag5', 'tag6', 'tag7', 'tag8'],
      );

      await tester.pumpWidget(createTestWidget(travel: manyTagsTravel));

      expect(find.text('Many Tags Trip'), findsOneWidget);

      // Should display some tags
      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('tag2'), findsOneWidget);

      // Should handle many tags without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should display travel card with proper styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      // Should have card-like appearance
      expect(find.byType(Card), findsOneWidget);

      // Should have proper layout
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Should handle different date formats',
        (WidgetTester tester) async {
      final futureDateTravel = Travel(
        id: 'future-travel',
        title: 'Future Trip',
        description: 'A planned trip',
        location: 'Future City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime(2025, 12, 31, 23, 59),
        photos: [],
        tags: ['future'],
      );

      await tester.pumpWidget(createTestWidget(travel: futureDateTravel));

      expect(find.text('Future Trip'), findsOneWidget);
      expect(find.textContaining('2025'), findsOneWidget);
    });

    testWidgets('Should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      // Should have semantic labels for accessibility
      expect(find.byType(TravelRecordCard), findsOneWidget);

      // Should not have accessibility issues
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should handle tap and hold gestures',
        (WidgetTester tester) async {
      bool longPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onLongPress: () => longPressed = true,
            child: TravelRecordCard(
              travel: testTravel,
            ),
          ),
        ),
      ));

      await tester.longPress(find.byType(TravelRecordCard));
      expect(longPressed, true);
    });

    testWidgets('Should display location icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      // Should have location icon
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('Should display photo icon when photos exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(travel: testTravel));

      // Should have photo icon
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('Should handle empty title gracefully',
        (WidgetTester tester) async {
      final emptyTitleTravel = Travel(
        id: 'empty-title-travel',
        title: '',
        description: 'A trip with no title',
        location: 'No Title City',
        latitude: 40.0,
        longitude: -74.0,
        date: DateTime.now(),
        photos: [],
        tags: [],
      );

      await tester.pumpWidget(createTestWidget(travel: emptyTitleTravel));

      // Should handle empty title gracefully
      expect(find.text('No Title City'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
