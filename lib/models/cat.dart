import 'package:flutter/foundation.dart';

enum CatMood { happy, normal, sleepy, hungry }
enum CatAction { idle, eating, playing, sleeping }

class CatModel extends ChangeNotifier {
  String name = "小咪";
  int happiness = 50;  // 0-100
  int energy = 100;    // 0-100
  int hunger = 50;     // 0-100
  CatMood mood = CatMood.normal;
  CatAction currentAction = CatAction.idle;
  CatAppearance appearance = CatAppearance();
  
  void updateFurColor(String color) {
    appearance.furColor = color;
    notifyListeners();
  }
  
  void updateEyeColor(String color) {
    appearance.eyeColor = color;
    notifyListeners();
  }
  
  void updateAccessory(String accessory) {
    appearance.accessory = accessory;
    notifyListeners();
  }
  
  void updateOutfit(String outfit) {
    appearance.outfit = outfit;
    notifyListeners();
  }
  
  // 保存自定义设置
  Future<void> saveAppearance() async {
    // 这里可以添加持久化存储逻辑
    notifyListeners();
  }


  // 互动方法
  void pet() {
    if (happiness < 100) {
      happiness += 5;
      if (happiness > 100) happiness = 100;
    }
    _updateMood();
    notifyListeners();
  }

  void feed() {
    if (hunger < 100) {
      hunger += 30;
      if (hunger > 100) hunger = 100;
      happiness += 5;
      if (happiness > 100) happiness = 100;
    }
    _updateMood();
    notifyListeners();
  }

  void play() {
    if (energy > 20) {
      energy -= 20;
      happiness += 10;
      if (happiness > 100) happiness = 100;
      hunger -= 10;
      if (hunger < 0) hunger = 0;
    }
    _updateMood();
    notifyListeners();
  }

  // 更新心情
  void _updateMood() {
    if (happiness >= 80 && hunger >= 50) {
      mood = CatMood.happy;
    } else if (energy <= 30) {
      mood = CatMood.sleepy;
    } else if (hunger <= 30) {
      mood = CatMood.hungry;
    } else {
      mood = CatMood.normal;
    }
  }

  // 自动状态更新(可以在定时器中调用)
  void updateStatus() {
    if (hunger > 0) hunger -= 1;
    if (energy < 100) energy += 1;
    if (happiness > 0) happiness -= 1;
    _updateMood();
    notifyListeners();
  }
}

class CatAppearance {
  String furColor;      // 毛色
  String eyeColor;      // 眼睛颜色
  String accessory;     // 装饰品
  String outfit;        // 服装
  
  CatAppearance({
    this.furColor = '#FFE0B2',  // 默认浅橘色
    this.eyeColor = '#4CAF50',  // 默认绿色
    this.accessory = 'none',
    this.outfit = 'none',
  });
  
  Map<String, dynamic> toJson() => {
    'furColor': furColor,
    'eyeColor': eyeColor,
    'accessory': accessory,
    'outfit': outfit,
  };
  
  factory CatAppearance.fromJson(Map<String, dynamic> json) => CatAppearance(
    furColor: json['furColor'] ?? '#FFE0B2',
    eyeColor: json['eyeColor'] ?? '#4CAF50',
    accessory: json['accessory'] ?? 'none',
    outfit: json['outfit'] ?? 'none',
  );
}
