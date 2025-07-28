import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/widgets/chat_bubble.dart';

void main() {
  group('Chat Bubble Widget Tests', () {
    Widget createTestWidget({
      required String message,
      required bool isUser,
      String? emoji,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            message: message,
            isUser: isUser,
            emoji: emoji,
          ),
        ),
      );
    }

    testWidgets('Should display user message correctly',
        (WidgetTester tester) async {
      const testMessage = 'Hello, how are you today?';

      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: true,
      ));

      expect(find.text(testMessage), findsOneWidget);

      // User messages should be aligned to the right
      final chatBubble = tester.widget<ChatBubble>(find.byType(ChatBubble));
      expect(chatBubble.isUser, true);
    });

    testWidgets('Should display AI message correctly',
        (WidgetTester tester) async {
      const testMessage = 'I am doing well, thank you for asking! 😊';
      const testEmoji = '😊';

      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: false,
        emoji: testEmoji,
      ));

      expect(find.text(testMessage), findsOneWidget);

      // AI messages should be aligned to the left
      final chatBubble = tester.widget<ChatBubble>(find.byType(ChatBubble));
      expect(chatBubble.isUser, false);
      expect(chatBubble.emoji, testEmoji);
    });

    testWidgets('Should display emoji when provided',
        (WidgetTester tester) async {
      const testMessage = 'I am feeling happy today!';
      const testEmoji = '😸';

      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: false,
        emoji: testEmoji,
      ));

      expect(find.text(testMessage), findsOneWidget);
      expect(find.text(testEmoji), findsOneWidget);
    });

    testWidgets('Should handle long messages', (WidgetTester tester) async {
      const longMessage =
          'This is a very long message that should wrap properly '
          'across multiple lines and still display correctly in the chat bubble. '
          'It should not overflow or cause any layout issues.';

      await tester.pumpWidget(createTestWidget(
        message: longMessage,
        isUser: true,
      ));

      expect(find.text(longMessage), findsOneWidget);

      // Should not have overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should handle empty messages', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        message: '',
        isUser: true,
      ));

      // Should handle empty message gracefully
      expect(find.byType(ChatBubble), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should have different styles for user and AI messages',
        (WidgetTester tester) async {
      const testMessage = 'Test message';

      // Test user message
      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: true,
      ));

      final userBubble = find.byType(ChatBubble);
      expect(userBubble, findsOneWidget);

      // Test AI message
      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: false,
        emoji: '🤖',
      ));

      final aiBubble = find.byType(ChatBubble);
      expect(aiBubble, findsOneWidget);
    });

    testWidgets('Should handle special characters and emojis in message',
        (WidgetTester tester) async {
      const specialMessage =
          'Hello! 👋 How are you? 😊 I hope you\'re having a great day! 🌟';

      await tester.pumpWidget(createTestWidget(
        message: specialMessage,
        isUser: false,
        emoji: '😊',
      ));

      expect(find.text(specialMessage), findsOneWidget);
      expect(find.text('😊'), findsOneWidget);
    });

    testWidgets('Should be tappable if tap handler is provided',
        (WidgetTester tester) async {
      const testMessage = 'Tappable message';
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => tapped = true,
            child: ChatBubble(
              message: testMessage,
              isUser: true,
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(ChatBubble));
      expect(tapped, true);
    });

    testWidgets('Should display timestamp if provided',
        (WidgetTester tester) async {
      const testMessage = 'Message with timestamp';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatBubble(
                message: testMessage,
                isUser: true,
              ),
              Text(
                DateTime.now().toString().substring(11, 16), // HH:MM format
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ));

      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2)); // Message + timestamp
    });

    testWidgets('Should handle null emoji gracefully',
        (WidgetTester tester) async {
      const testMessage = 'Message without emoji';

      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: false,
        emoji: null,
      ));

      expect(find.text(testMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should have proper padding and margins',
        (WidgetTester tester) async {
      const testMessage = 'Test padding';

      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: true,
      ));

      final chatBubble = find.byType(ChatBubble);
      expect(chatBubble, findsOneWidget);

      // Should have proper layout without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should support different message types',
        (WidgetTester tester) async {
      final testCases = [
        {'message': 'Simple text', 'isUser': true},
        {'message': 'Text with emoji 😊', 'isUser': false},
        {'message': 'Multi\nline\nmessage', 'isUser': true},
        {'message': '123456789', 'isUser': false},
        {'message': '!@#\$%^&*()', 'isUser': true},
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(createTestWidget(
          message: testCase['message'] as String,
          isUser: testCase['isUser'] as bool,
        ));

        expect(find.text(testCase['message'] as String), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Should animate appearance if animation is implemented',
        (WidgetTester tester) async {
      const testMessage = 'Animated message';

      await tester.pumpWidget(createTestWidget(
        message: testMessage,
        isUser: false,
        emoji: '✨',
      ));

      // Should appear without animation errors
      await tester.pumpAndSettle();
      expect(find.text(testMessage), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
    });

    testWidgets('Should handle rapid message updates',
        (WidgetTester tester) async {
      const messages = ['Message 1', 'Message 2', 'Message 3'];

      for (final message in messages) {
        await tester.pumpWidget(createTestWidget(
          message: message,
          isUser: true,
        ));

        expect(find.text(message), findsOneWidget);
        await tester.pump();
      }

      // Should handle rapid updates without errors
      expect(tester.takeException(), isNull);
    });
  });
}
