import 'package:flutter/material.dart';
import '../models/accessory.dart';
import '../services/accessory_service.dart';

/// 装饰品状态管理Provider
class AccessoryProvider extends ChangeNotifier {
  final AccessoryService _accessoryService = AccessoryService();
  bool _isLoading = true;
  String? _errorMessage;
  AccessoryType _selectedType = AccessoryType.hat;
  
  // 获取装饰品服务
  AccessoryService get accessoryService => _accessoryService;
  
  // 加载状态
  bool get isLoading => _isLoading;
  
  // 错误信息
  String? get errorMessage => _errorMessage;
  
  // 当前选中的装饰品类型
  AccessoryType get selectedType => _selectedType;
  
  // 获取用户的金币数量
  int get coins => _accessoryService.coins;
  
  // 获取所有装饰品
  List<Accessory> get allAccessories => _accessoryService.allAccessories;
  
  // 获取已解锁的装饰品
  List<Accessory> get unlockedAccessories => _accessoryService.unlockedAccessories;
  
  // 根据类型获取装饰品
  List<Accessory> getAccessoriesByType(AccessoryType type) {
    return _accessoryService.getAccessoriesByType(type);
  }
  
  // 获取当前选中类型的装饰品
  List<Accessory> get currentTypeAccessories => getAccessoriesByType(_selectedType);
  
  // 构造函数
  AccessoryProvider() {
    _loadAccessories();
  }
  
  // 初始化，加载装饰品数据
  Future<void> _loadAccessories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _accessoryService.loadUserData();
    } catch (e) {
      _errorMessage = '加载装饰品数据失败: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // 切换装饰品类型
  void changeType(AccessoryType type) {
    _selectedType = type;
    notifyListeners();
  }
  
  // 购买装饰品
  Future<bool> purchaseAccessory(String accessoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    bool success = false;
    try {
      success = await _accessoryService.purchaseAccessory(accessoryId);
      if (!success) {
        _errorMessage = '购买失败，可能是金币不足或已拥有该装饰品';
      }
    } catch (e) {
      _errorMessage = '购买装饰品失败: $e';
      debugPrint(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
  
  // 添加金币（测试用）
  Future<void> addCoins(int amount) async {
    await _accessoryService.addCoins(amount);
    notifyListeners();
  }
  
  // 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 