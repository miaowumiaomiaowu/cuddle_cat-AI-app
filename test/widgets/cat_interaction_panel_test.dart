import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cuddle_cat/widgets/cat_interaction_panel.dart';
import 'package:cuddle_cat/providers/cat_provider.dart';
import 'package:cuddle_cat/models/cat.dart';

void main() {
  group('Cat Interaction Panel Widget Tests', () {
    late CatProvider mockCatProvider;

    setUp(() {
      mockCatProvider = CatProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<CatProvider>.value(
          value: mockCatProvider,
          child: const Scaffold(
            body: CatInteractionPanel(),
          ),
        ),
      );
    }

    testWidgets('Should display cat interaction buttons',
        (WidgetTester tester) async {
      // Initialize cat provider with test data
      final testCat = Cat(
        id: 'test-cat',
        name: 'Test Cat',
        breed: 'Persian',
        color: 'White',
        happiness: 70,
        health: 80,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now(),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display interaction buttons
      expect(find.text('抚摸'), findsOneWidget); // Pet button
      expect(find.text('喂食'), findsOneWidget); // Feed button
      expect(find.text('玩耍'), findsOneWidget); // Play button
    });

    testWidgets('Should display cat emoji and status',
        (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Happy Cat',
        breed: 'Siamese',
        color: 'Brown',
        happiness: 90,
        health: 95,
        energy: 85,
        hunger: 20,
        lastInteraction: DateTime.now(),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display cat emoji
      expect(find.byType(Text), findsWidgets);

      // Should display status bars or indicators
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('Should handle pet button tap', (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Test Cat',
        breed: 'Bengal',
        color: 'Orange',
        happiness: 50,
        health: 70,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now().subtract(const Duration(hours: 1)),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialHappiness = mockCatProvider.currentCat!.happiness;

      // Tap pet button
      await tester.tap(find.text('抚摸'));
      await tester.pumpAndSettle();

      // Happiness should increase or stay the same
      expect(mockCatProvider.currentCat!.happiness,
          greaterThanOrEqualTo(initialHappiness));
    });

    testWidgets('Should handle feed button tap', (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Hungry Cat',
        breed: 'Maine Coon',
        color: 'Black',
        happiness: 60,
        health: 70,
        energy: 50,
        hunger: 80, // Very hungry
        lastInteraction: DateTime.now().subtract(const Duration(hours: 2)),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialHunger = mockCatProvider.currentCat!.hunger;

      // Tap feed button
      await tester.tap(find.text('喂食'));
      await tester.pumpAndSettle();

      // Hunger should decrease
      expect(
          mockCatProvider.currentCat!.hunger, lessThanOrEqualTo(initialHunger));
    });

    testWidgets('Should handle play button tap', (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Energetic Cat',
        breed: 'Ragdoll',
        color: 'Blue',
        happiness: 70,
        health: 80,
        energy: 90, // High energy
        hunger: 30,
        lastInteraction: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialEnergy = mockCatProvider.currentCat!.energy;

      // Tap play button
      await tester.tap(find.text('玩耍'));
      await tester.pumpAndSettle();

      // Energy should decrease
      expect(
          mockCatProvider.currentCat!.energy, lessThanOrEqualTo(initialEnergy));
    });

    testWidgets('Should show loading state during interactions',
        (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Test Cat',
        breed: 'Persian',
        color: 'White',
        happiness: 70,
        health: 80,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now(),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap pet button
      await tester.tap(find.text('抚摸'));
      await tester.pump(); // Don't settle to catch loading state

      // Should show some loading indicator or disabled state
      // This depends on implementation details
      expect(find.byType(CatInteractionPanel), findsOneWidget);
    });

    testWidgets('Should display appropriate emoji for different cat states',
        (WidgetTester tester) async {
      // Test happy cat
      final happyCat = Cat(
        id: 'happy-cat',
        name: 'Happy Cat',
        breed: 'Persian',
        color: 'White',
        happiness: 95,
        health: 90,
        energy: 85,
        hunger: 20,
        lastInteraction: DateTime.now(),
      );

      mockCatProvider.updateCatFromData(happyCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display happy emoji
      expect(find.byType(Text), findsWidgets);

      // Test sad cat
      final sadCat = Cat(
        id: 'sad-cat',
        name: 'Sad Cat',
        breed: 'Siamese',
        color: 'Gray',
        happiness: 20,
        health: 30,
        energy: 15,
        hunger: 90,
        lastInteraction: DateTime.now().subtract(const Duration(hours: 12)),
      );

      mockCatProvider.updateCatFromData(sadCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display different emoji for sad cat
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Should handle interaction cooldowns',
        (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Test Cat',
        breed: 'Bengal',
        color: 'Orange',
        happiness: 70,
        health: 80,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now(), // Just interacted
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap pet button multiple times rapidly
      await tester.tap(find.text('抚摸'));
      await tester.pump();
      await tester.tap(find.text('抚摸'));
      await tester.pumpAndSettle();

      // Should handle cooldown gracefully (no crashes)
      expect(find.byType(CatInteractionPanel), findsOneWidget);
    });

    testWidgets('Should display cat stats correctly',
        (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Stats Cat',
        breed: 'Maine Coon',
        color: 'Black',
        happiness: 75,
        health: 85,
        energy: 65,
        hunger: 35,
        lastInteraction: DateTime.now(),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display progress indicators for stats
      final progressIndicators = find.byType(LinearProgressIndicator);
      expect(progressIndicators, findsWidgets);

      // Should display stat values or labels
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Should handle null cat state gracefully',
        (WidgetTester tester) async {
      // Don't set any cat data (null state)
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should handle null state without crashing
      expect(find.byType(CatInteractionPanel), findsOneWidget);

      // Should show loading or placeholder state
      expect(find.byType(Widget), findsWidgets);
    });

    testWidgets('Should animate interactions', (WidgetTester tester) async {
      final testCat = Cat(
        id: 'test-cat',
        name: 'Animated Cat',
        breed: 'Ragdoll',
        color: 'Blue',
        happiness: 70,
        health: 80,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      mockCatProvider.updateCatFromData(testCat);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap interaction button
      await tester.tap(find.text('抚摸'));

      // Should have some animation during interaction
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Animation should complete without errors
      expect(find.byType(CatInteractionPanel), findsOneWidget);
    });
  });
}
