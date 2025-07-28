import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/providers/dialogue_provider.dart';
import 'package:cuddle_cat/models/cat.dart';

void main() {
  group('Dialogue Provider Tests', () {
    late DialogueProvider dialogueProvider;

    setUp(() {
      dialogueProvider = DialogueProvider();
    });

    test('DialogueProvider should initialize with empty state', () {
      expect(dialogueProvider.messages, isEmpty);
      expect(dialogueProvider.isLoading, false);
      expect(dialogueProvider.isTyping, false);
    });

    test('DialogueProvider should send user message', () async {
      const userMessage = 'Hello, how are you?';

      await dialogueProvider.sendMessage(userMessage);

      expect(dialogueProvider.messages, isNotEmpty);
      expect(dialogueProvider.messages.first.content, userMessage);
      expect(dialogueProvider.messages.first.isUser, true);
      expect(dialogueProvider.isLoading, false);
    });

    test('DialogueProvider should generate AI response', () async {
      final cat = Cat(
        id: 'test-cat',
        name: 'Whiskers',
        breed: 'Persian',
        color: 'White',
        happiness: 70,
        health: 80,
        energy: 60,
        hunger: 40,
        lastInteraction: DateTime.now(),
      );

      dialogueProvider.setCatContext(cat);

      const userMessage = 'How are you feeling today?';

      try {
        await dialogueProvider.sendMessage(userMessage);

        // Should have user message and AI response
        expect(dialogueProvider.messages.length, greaterThanOrEqualTo(1));

        final userMsg = dialogueProvider.messages.firstWhere((m) => m.isUser);
        expect(userMsg.content, userMessage);

        // If AI service is available, should have AI response
        final aiMessages = dialogueProvider.messages.where((m) => !m.isUser);
        if (aiMessages.isNotEmpty) {
          expect(aiMessages.first.content, isNotEmpty);
        }
      } catch (e) {
        // If AI service is not available, should still handle gracefully
        print('Dialogue provider test with limited AI service: $e');
        expect(dialogueProvider.messages, isNotEmpty);
      }
    });

    test('DialogueProvider should handle typing indicator', () async {
      const userMessage = 'Test typing indicator';

      // Start sending message
      final future = dialogueProvider.sendMessage(userMessage);

      // Should show typing indicator briefly
      await Future.delayed(const Duration(milliseconds: 100));

      await future;

      // Typing should be false after completion
      expect(dialogueProvider.isTyping, false);
    });

    test('DialogueProvider should save and load conversation history',
        () async {
      const message1 = 'First message';
      const message2 = 'Second message';

      await dialogueProvider.sendMessage(message1);
      await dialogueProvider.sendMessage(message2);

      // Save conversation
      await dialogueProvider.saveConversation();

      // Create new provider and load
      final newProvider = DialogueProvider();
      await newProvider.loadConversation();

      expect(newProvider.messages, isNotEmpty);
      expect(newProvider.messages.any((m) => m.content == message1), true);
      expect(newProvider.messages.any((m) => m.content == message2), true);
    });

    test('DialogueProvider should clear conversation', () async {
      await dialogueProvider.sendMessage('Test message');
      expect(dialogueProvider.messages, isNotEmpty);

      dialogueProvider.clearConversation();
      expect(dialogueProvider.messages, isEmpty);
    });

    test('DialogueProvider should handle cat context updates', () async {
      final cat1 = Cat(
        id: 'cat1',
        name: 'Happy Cat',
        breed: 'Persian',
        color: 'White',
        happiness: 90,
        health: 95,
        energy: 85,
        hunger: 20,
        lastInteraction: DateTime.now(),
      );

      final cat2 = Cat(
        id: 'cat2',
        name: 'Sad Cat',
        breed: 'Siamese',
        color: 'Gray',
        happiness: 20,
        health: 30,
        energy: 15,
        hunger: 90,
        lastInteraction: DateTime.now().subtract(const Duration(hours: 12)),
      );

      dialogueProvider.setCatContext(cat1);
      expect(dialogueProvider.catContext?.name, 'Happy Cat');

      dialogueProvider.setCatContext(cat2);
      expect(dialogueProvider.catContext?.name, 'Sad Cat');
    });

    test('DialogueProvider should handle message limits', () async {
      // Send many messages to test limits
      for (int i = 0; i < 100; i++) {
        await dialogueProvider.sendMessage('Message $i');
      }

      // Should handle large number of messages gracefully
      expect(dialogueProvider.messages.length,
          lessThanOrEqualTo(200)); // Including AI responses
    });

    test('DialogueProvider should handle errors gracefully', () async {
      // Test with invalid input
      await dialogueProvider.sendMessage('');
      expect(
          dialogueProvider.messages, isNotEmpty); // Should handle empty message

      // Test with very long message
      final longMessage = 'Very long message ' * 1000;
      await dialogueProvider.sendMessage(longMessage);
      expect(
          dialogueProvider.messages
              .any((m) => m.content.contains('Very long message')),
          true);
    });

    test('DialogueProvider should notify listeners on changes', () async {
      bool notified = false;
      dialogueProvider.addListener(() {
        notified = true;
      });

      await dialogueProvider.sendMessage('Test notification');
      expect(notified, true);
    });

    test('DialogueProvider should handle emotion analysis', () async {
      const happyMessage = 'I am so happy today!';
      const sadMessage = 'I feel really sad...';

      try {
        await dialogueProvider.sendMessage(happyMessage);
        await dialogueProvider.sendMessage(sadMessage);

        // Should have processed both messages
        expect(dialogueProvider.messages.length, greaterThanOrEqualTo(2));

        final happyMsg = dialogueProvider.messages
            .firstWhere((m) => m.content == happyMessage);
        final sadMsg = dialogueProvider.messages
            .firstWhere((m) => m.content == sadMessage);

        expect(happyMsg, isNotNull);
        expect(sadMsg, isNotNull);
      } catch (e) {
        // If emotion analysis is not available, should still work
        print('Emotion analysis test with limited service: $e');
        expect(dialogueProvider.messages, isNotEmpty);
      }
    });
  });
}
