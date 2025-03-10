import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';

/// 猫咪状态管理Provider
class CatProvider extends ChangeNotifier {
  final CatService _catService = CatService();
  bool _isLoading = true;
  String? _errorMessage;
  
  // 获取当前猫咪
  Cat? get cat => _catService.currentCat;
  
  // 判断用户是否有猫咪
  bool get hasCat => _catService.hasCat;
  
  // 加载状态
  bool get isLoading => _isLoading;
  
  // 错误信息
  String? get errorMessage => _errorMessage;
  
  // 构造函数
  CatProvider() {
    _initialize();
  }
  
  // 初始化，加载猫咪数据
  Future<void> _initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _catService.loadCat();
    } catch (e) {
      _errorMessage = '加载猫咪数据失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 领养新猫咪
  Future<void> adoptCat({CatBreed? breed, String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _catService.adoptCat(breed: breed, name: name);
    } catch (e) {
      _errorMessage = '领养猫咪失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 更新猫咪名字
  Future<void> updateCatName(String newName) async {
    if (newName.isEmpty) return;
    
    try {
      await _catService.updateCatName(newName);
      notifyListeners();
    } catch (e) {
      _errorMessage = '更新猫咪名字失败: $e';
      notifyListeners();
    }
  }
  
  // 喂食猫咪
  Future<void> feedCat() async {
    try {
      await _catService.feedCat();
      notifyListeners();
    } catch (e) {
      _errorMessage = '喂食猫咪失败: $e';
      notifyListeners();
    }
  }
  
  // 抚摸猫咪
  Future<void> petCat() async {
    try {
      await _catService.petCat();
      notifyListeners();
    } catch (e) {
      _errorMessage = '抚摸猫咪失败: $e';
      notifyListeners();
    }
  }
  
  // 与猫咪玩耍
  Future<void> playWithCat() async {
    try {
      await _catService.playWithCat();
      notifyListeners();
    } catch (e) {
      _errorMessage = '与猫咪玩耍失败: $e';
      notifyListeners();
    }
  }
  
  // 解锁猫咪装饰品
  Future<void> unlockAccessory(String accessoryId) async {
    try {
      await _catService.unlockAccessory(accessoryId);
      notifyListeners();
    } catch (e) {
      _errorMessage = '解锁装饰品失败: $e';
      notifyListeners();
    }
  }
  
  // 为猫咪装扮
  Future<void> equipAccessory(String accessoryType, String accessoryId) async {
    try {
      await _catService.equipAccessory(accessoryType, accessoryId);
      notifyListeners();
    } catch (e) {
      _errorMessage = '装扮猫咪失败: $e';
      notifyListeners();
    }
  }
  
  // 增加猫咪经验值
  Future<void> addExperience(int amount) async {
    try {
      await _catService.addExperience(amount);
      notifyListeners();
    } catch (e) {
      _errorMessage = '增加经验值失败: $e';
      notifyListeners();
    }
  }
  
  // 重置猫咪数据（仅用于测试/调试）
  Future<void> resetCat() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _catService.resetCat();
    } catch (e) {
      _errorMessage = '重置猫咪数据失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 