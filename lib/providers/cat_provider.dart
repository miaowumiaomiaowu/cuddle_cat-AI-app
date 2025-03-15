import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';

/// 猫咪状态管理Provider
class CatProvider extends ChangeNotifier {
  final CatService _catService = CatService();
  Cat? _cat;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 获取当前猫咪
  Cat? get cat => _cat;
  
  // 判断用户是否有猫咪
  bool get hasCat => _cat != null;
  
  // 加载状态
  bool get isLoading => _isLoading;
  
  // 错误信息
  String? get errorMessage => _errorMessage;
  
  // 构造函数
  CatProvider() {
    _loadCat();
  }
  
  // 初始化，加载猫咪数据
  Future<void> _loadCat() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final loadedCat = await _catService.loadCat();
      if (loadedCat != null) {
        _cat = loadedCat;
        _cat!.updateStatus();
      }
    } catch (e) {
      _errorMessage = '加载猫咪数据失败: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // 领养新猫咪
  Future<void> adoptCat({required String name, required CatBreed breed}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _cat = await _catService.adoptCat(name: name, breed: breed);
    } catch (e) {
      _errorMessage = '领养猫咪失败: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // 喂食猫咪
  void feedCat() {
    if (_cat != null) {
      _cat!.feed();
      _saveCat();
      notifyListeners();
    }
  }
  
  // 抚摸猫咪
  void petCat() {
    if (_cat != null) {
      _cat!.pet();
      _saveCat();
      notifyListeners();
    }
  }
  
  // 与猫咪玩耍
  void playWithCat() {
    if (_cat != null) {
      _cat!.play();
      _saveCat();
      notifyListeners();
    }
  }

  // 给猫咪洗澡/梳理
  void groomCat() {
    if (_cat != null) {
      _cat!.groom();
      _saveCat();
      notifyListeners();
    }
  }
  
  // 训练猫咪
  void trainCat() {
    if (_cat != null) {
      _cat!.train();
      _saveCat();
      notifyListeners();
    }
  }
  
  // 检查互动冷却状态
  bool canFeedCat() => _cat?.canFeed ?? false;
  bool canPlayWithCat() => _cat?.canPlay ?? false;
  bool canGroomCat() => _cat?.canGroom ?? false;
  bool canTrainCat() => _cat?.canTrain ?? false;
  
  // 获取互动冷却剩余时间
  int getFeedCooldown() => _cat?.feedCooldownRemaining ?? 0;
  int getPlayCooldown() => _cat?.playCooldownRemaining ?? 0;
  int getGroomCooldown() => _cat?.groomCooldownRemaining ?? 0;
  int getTrainCooldown() => _cat?.trainingCooldownRemaining ?? 0;
  
  // 为猫咪装扮
  void equipAccessory(String type, String accessoryId) {
    if (_cat != null) {
      _cat!.equippedAccessories[type] = accessoryId;
      _saveCat();
      notifyListeners();
    }
  }
  
  void removeAccessory(String type) {
    if (_cat != null && _cat!.equippedAccessories.containsKey(type)) {
      _cat!.equippedAccessories.remove(type);
      _saveCat();
      notifyListeners();
    }
  }
  
  // 更新猫咪名字
  void updateCatName(String newName) {
    if (_cat != null) {
      _cat!.name = newName;
      _saveCat();
      notifyListeners();
    }
  }
  
  // 重置猫咪数据（仅用于测试/调试）
  Future<void> resetCat() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _catService.removeCat();
      _cat = null;
    } catch (e) {
      _errorMessage = '重置猫咪数据失败: $e';
      debugPrint(_errorMessage);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> _saveCat() async {
    if (_cat != null) {
      try {
        await _catService.saveCat(_cat!);
      } catch (e) {
        _errorMessage = '保存猫咪数据失败: $e';
        debugPrint(_errorMessage);
      }
    }
  }
} 