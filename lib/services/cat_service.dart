import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';

/// 猫咪互动结果类
class CatInteractionResult {
  final Cat updatedCat;
  final String message;
  final bool success;

  CatInteractionResult({
    required this.updatedCat,
    required this.message,
    required this.success,
  });
}

/// 猫咪服务类，负责猫咪数据的管理和持久化
class CatService {
  static const String _catKey = 'cat_data';

  /// 从本地存储加载猫咪数据
  Future<Cat?> loadCat() async {
    final prefs = await SharedPreferences.getInstance();
    final catJson = prefs.getString(_catKey);

    if (catJson != null) {
      try {
        return Cat.fromJson(jsonDecode(catJson));
      } catch (e) {
        // 如果解析失败，返回null
        debugPrint('Error parsing cat data: $e');
        return null;
      }
    }

    return null;
  }

  /// 保存猫咪数据到本地存储
  Future<void> saveCat(Cat cat) async {
    final prefs = await SharedPreferences.getInstance();
    final catJson = jsonEncode(cat.toJson());
    await prefs.setString(_catKey, catJson);
  }

  /// 领养新猫咪
  Future<Cat> adoptCat({required String name, required CatBreed breed, CatPersonality personality = CatPersonality.playful}) async {
    final newCat = Cat(
      name: name,
      breed: breed,
      personality: personality,
    );

    await saveCat(newCat);
    return newCat;
  }

  /// 删除猫咪数据
  Future<void> removeCat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_catKey);
  }

  // ========== 向后兼容的方法（用于测试） ==========

  /// 喂食猫咪
  Future<CatInteractionResult> feedCat(Cat cat) async {
    try {
      final updatedCat = Cat(
        name: cat.name,
        breed: cat.breed,
        personality: cat.personality,
        mood: cat.mood,
        growthStage: cat.growthStage,
        energyLevel: cat.energyLevel,
        happiness: cat.happiness,
        petCount: cat.petCount,
        feedCount: cat.feedCount + 1,
        playCount: cat.playCount,
        groomCount: cat.groomCount,
        trainingCount: cat.trainingCount,
        playSkill: cat.playSkill,
        trainingSkill: cat.trainingSkill,
        interactionCombo: cat.interactionCombo,
        lastInteractionTime: cat.lastInteractionTime,
        previousMood: cat.previousMood,
      );

      updatedCat.feed();
      await saveCat(updatedCat);

      return CatInteractionResult(
        updatedCat: updatedCat,
        message: '${cat.name}开心地吃完了食物！',
        success: true,
      );
    } catch (e) {
      return CatInteractionResult(
        updatedCat: cat,
        message: '喂食失败：$e',
        success: false,
      );
    }
  }

  /// 抚摸猫咪
  Future<CatInteractionResult> petCat(Cat cat) async {
    try {
      final updatedCat = Cat(
        name: cat.name,
        breed: cat.breed,
        personality: cat.personality,
        mood: cat.mood,
        growthStage: cat.growthStage,
        energyLevel: cat.energyLevel,
        happiness: cat.happiness,
        petCount: cat.petCount,
        feedCount: cat.feedCount,
        playCount: cat.playCount,
        groomCount: cat.groomCount,
        trainingCount: cat.trainingCount,
        playSkill: cat.playSkill,
        trainingSkill: cat.trainingSkill,
        interactionCombo: cat.interactionCombo,
        lastInteractionTime: cat.lastInteractionTime,
        previousMood: cat.previousMood,
      );

      updatedCat.pet();
      await saveCat(updatedCat);

      return CatInteractionResult(
        updatedCat: updatedCat,
        message: '${cat.name}舒服地享受着你的抚摸！',
        success: true,
      );
    } catch (e) {
      return CatInteractionResult(
        updatedCat: cat,
        message: '抚摸失败：$e',
        success: false,
      );
    }
  }

  /// 和猫咪玩耍
  Future<CatInteractionResult> playWithCat(Cat cat) async {
    try {
      final updatedCat = Cat(
        name: cat.name,
        breed: cat.breed,
        personality: cat.personality,
        mood: cat.mood,
        growthStage: cat.growthStage,
        energyLevel: cat.energyLevel,
        happiness: cat.happiness,
        petCount: cat.petCount,
        feedCount: cat.feedCount,
        playCount: cat.playCount,
        groomCount: cat.groomCount,
        trainingCount: cat.trainingCount,
        playSkill: cat.playSkill,
        trainingSkill: cat.trainingSkill,
        interactionCombo: cat.interactionCombo,
        lastInteractionTime: cat.lastInteractionTime,
        previousMood: cat.previousMood,
      );

      updatedCat.play();
      await saveCat(updatedCat);

      return CatInteractionResult(
        updatedCat: updatedCat,
        message: '${cat.name}和你玩得很开心！',
        success: true,
      );
    } catch (e) {
      return CatInteractionResult(
        updatedCat: cat,
        message: '玩耍失败：$e',
        success: false,
      );
    }
  }
}
