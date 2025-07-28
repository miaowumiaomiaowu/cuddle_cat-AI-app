import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/models/accessory.dart';
import 'package:cuddle_cat/services/accessory_service.dart';
import 'package:cuddle_cat/providers/accessory_provider.dart';

void main() {
  group('Simplified Accessory System Tests', () {
    late AccessoryService accessoryService;
    late AccessoryProvider accessoryProvider;

    setUp(() {
      accessoryService = AccessoryService();
      accessoryProvider = AccessoryProvider();
    });

    test('AccessoryService should load all accessories without locks',
        () async {
      await accessoryService.loadAccessories();

      final allAccessories = accessoryService.allAccessories;
      expect(allAccessories.isNotEmpty, true);

      // Check that all accessories are unlocked (simplified system)
      for (final accessory in allAccessories) {
        expect(accessory.isLocked, false);
        expect(accessory.price, 0); // All accessories should be free
      }
    });

    test('AccessoryService should provide accessories by type', () async {
      await accessoryService.loadAccessories();

      final hatAccessories =
          accessoryService.getAccessoriesByType(AccessoryType.hat);
      expect(hatAccessories.isNotEmpty, true);

      // Check that all hat accessories are of hat type
      for (final accessory in hatAccessories) {
        expect(accessory.type, AccessoryType.hat);
        expect(accessory.isLocked, false);
      }
    });

    test('AccessoryService should include "none" options for each type',
        () async {
      await accessoryService.loadAccessories();

      // Check that each accessory type has a "none" option
      final hatAccessories =
          accessoryService.getAccessoriesByType(AccessoryType.hat);
      expect(hatAccessories.any((a) => a.id == 'hat_none'), true);

      final collarAccessories =
          accessoryService.getAccessoriesByType(AccessoryType.collar);
      expect(collarAccessories.any((a) => a.id == 'collar_none'), true);

      final glassesAccessories =
          accessoryService.getAccessoriesByType(AccessoryType.glasses);
      expect(glassesAccessories.any((a) => a.id == 'glasses_none'), true);

      final costumeAccessories =
          accessoryService.getAccessoriesByType(AccessoryType.costume);
      expect(costumeAccessories.any((a) => a.id == 'costume_none'), true);

      final backgroundAccessories =
          accessoryService.getAccessoriesByType(AccessoryType.background);
      expect(backgroundAccessories.any((a) => a.id == 'background_none'), true);
    });

    test('AccessoryProvider should change types correctly', () async {
      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      expect(accessoryProvider.selectedType, AccessoryType.hat);

      accessoryProvider.changeType(AccessoryType.collar);
      expect(accessoryProvider.selectedType, AccessoryType.collar);

      final currentAccessories = accessoryProvider.currentTypeAccessories;
      for (final accessory in currentAccessories) {
        expect(accessory.type, AccessoryType.collar);
      }
    });
  });
}
