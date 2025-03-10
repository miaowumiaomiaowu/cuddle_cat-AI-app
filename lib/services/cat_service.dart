import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';

/// 猫咪服务类，负责猫咪数据的管理和持久化
class CatService {
  static const String _catKey = 'user_cat';
  Cat? _currentCat;
  
  // 单例模式
  static final CatService _instance = CatService._internal();
  
  factory CatService() {
    return _instance;
  }
  
  CatService._internal();
  
  // 获取当前猫咪，如果没有则返回null
  Cat? get currentCat => _currentCat;
  
  // 判断用户是否已经有猫咪
  bool get hasCat => _currentCat != null;
  
  // 从本地存储加载猫咪数据
  Future<void> loadCat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catJson = prefs.getString(_catKey);
      
      if (catJson != null) {
        final Map<String, dynamic> catMap = jsonDecode(catJson);
        _currentCat = Cat.fromJson(catMap);
        
        // 更新猫咪状态（考虑时间流逝）
        final lastUpdate = DateTime.parse(catMap['lastUpdate'] ?? DateTime.now().toIso8601String());
        final now = DateTime.now();
        final elapsed = now.difference(lastUpdate);
        _currentCat?.simulateTimePassage(elapsed);
        
        // 保存更新后的状态
        await saveCat();
      }
    } catch (e) {
      print('加载猫咪数据失败: $e');
    }
  }
  
  // 保存猫咪数据到本地存储
  Future<void> saveCat() async {
    if (_currentCat == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final catMap = _currentCat!.toJson();
      
      // 添加最后更新时间
      catMap['lastUpdate'] = DateTime.now().toIso8601String();
      
      final catJson = jsonEncode(catMap);
      await prefs.setString(_catKey, catJson);
    } catch (e) {
      print('保存猫咪数据失败: $e');
    }
  }
  
  // 创建新猫咪
  Future<Cat> adoptCat({CatBreed? breed, String? name}) async {
    Cat newCat;
    
    if (breed != null) {
      // 创建指定品种的猫咪
      final now = DateTime.now();
      final id = 'cat_${now.millisecondsSinceEpoch}';
      newCat = Cat(
        id: id,
        name: name ?? '未命名猫咪',
        breed: breed,
        adoptionDate: now,
      );
    } else {
      // 创建随机品种的猫咪
      newCat = Cat.random();
      if (name != null) {
        newCat.name = name;
      }
    }
    
    _currentCat = newCat;
    await saveCat();
    return newCat;
  }
  
  // 更新猫咪名字
  Future<void> updateCatName(String newName) async {
    if (_currentCat != null) {
      _currentCat!.name = newName;
      await saveCat();
    }
  }
  
  // 喂食猫咪
  Future<void> feedCat() async {
    if (_currentCat != null) {
      _currentCat!.feed();
      await saveCat();
    }
  }
  
  // 抚摸猫咪
  Future<void> petCat() async {
    if (_currentCat != null) {
      _currentCat!.pet();
      await saveCat();
    }
  }
  
  // 与猫咪玩耍
  Future<void> playWithCat() async {
    if (_currentCat != null) {
      _currentCat!.play();
      await saveCat();
    }
  }
  
  // 解锁猫咪装饰品
  Future<void> unlockAccessory(String accessoryId) async {
    if (_currentCat != null) {
      _currentCat!.unlockAccessory(accessoryId);
      await saveCat();
    }
  }
  
  // 为猫咪装扮
  Future<void> equipAccessory(String accessoryType, String accessoryId) async {
    if (_currentCat != null) {
      _currentCat!.equip(accessoryType, accessoryId);
      await saveCat();
    }
  }
  
  // 增加猫咪经验值
  Future<void> addExperience(int amount) async {
    if (_currentCat != null) {
      _currentCat!.addExperience(amount);
      await saveCat();
    }
  }
  
  // 重置猫咪数据（仅用于测试/调试）
  Future<void> resetCat() async {
    _currentCat = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_catKey);
  }
} 