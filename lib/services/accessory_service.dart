import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accessory.dart';

/// 装饰品服务类
class AccessoryService {
  static const String _accessoriesKey = 'user_accessories';
  static const String _coinsKey = 'user_coins';
  
  // 用户的金币数量
  int _coins = 500; // 初始金币数量
  
  // 所有装饰品列表
  final List<Accessory> _allAccessories = [];
  
  // 用户解锁的装饰品ID列表
  final List<String> _unlockedAccessoryIds = [];
  
  /// 获取用户金币数量
  int get coins => _coins;
  
  /// 获取所有装饰品
  List<Accessory> get allAccessories => _allAccessories;
  
  /// 获取已解锁的装饰品
  List<Accessory> get unlockedAccessories {
    return _allAccessories
        .where((accessory) => _unlockedAccessoryIds.contains(accessory.id))
        .map((accessory) => Accessory(
              id: accessory.id,
              name: accessory.name,
              description: accessory.description,
              imagePath: accessory.imagePath,
              svgAsset: accessory.svgAsset,
              type: accessory.type,
              rarity: accessory.rarity,
              price: accessory.price,
              isLocked: false,
              color: accessory.color,
              attributes: accessory.attributes,
            ))
        .toList();
  }

  /// 按类型获取装饰品
  List<Accessory> getAccessoriesByType(AccessoryType type) {
    return _allAccessories
        .where((accessory) => accessory.type == type)
        .map((accessory) => Accessory(
              id: accessory.id,
              name: accessory.name,
              description: accessory.description,
              imagePath: accessory.imagePath,
              svgAsset: accessory.svgAsset,
              type: accessory.type,
              rarity: accessory.rarity,
              price: accessory.price,
              isLocked: !_unlockedAccessoryIds.contains(accessory.id),
              color: accessory.color,
              attributes: accessory.attributes,
            ))
        .toList();
  }

  /// 加载用户数据
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载金币
    _coins = prefs.getInt(_coinsKey) ?? 500;
    
    // 加载已解锁的装饰品ID
    final unlockedJson = prefs.getStringList(_accessoriesKey) ?? [];
    _unlockedAccessoryIds.clear();
    _unlockedAccessoryIds.addAll(unlockedJson);
    
    // 初始化所有装饰品
    _initializeAccessories();
  }

  /// 保存用户数据
  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存金币
    await prefs.setInt(_coinsKey, _coins);
    
    // 保存已解锁的装饰品ID
    await prefs.setStringList(_accessoriesKey, _unlockedAccessoryIds);
  }

  /// 购买装饰品
  Future<bool> purchaseAccessory(String accessoryId) async {
    final accessory = _allAccessories.firstWhere(
      (item) => item.id == accessoryId,
      orElse: () => throw Exception('未找到指定的装饰品'),
    );
    
    // 检查是否已解锁
    if (_unlockedAccessoryIds.contains(accessoryId)) {
      return false;
    }
    
    // 检查金币是否足够
    if (_coins < accessory.price) {
      return false;
    }
    
    // 扣除金币，解锁装饰品
    _coins -= accessory.price;
    _unlockedAccessoryIds.add(accessoryId);
    
    // 保存用户数据
    await saveUserData();
    return true;
  }

  /// 添加金币
  Future<void> addCoins(int amount) async {
    _coins += amount;
    await saveUserData();
  }

  /// 初始化所有装饰品
  void _initializeAccessories() {
    _allAccessories.clear();
    
    // 帽子类装饰品
    _allAccessories.addAll([
      const Accessory(
        id: 'hat_crown',
        name: '皇冠',
        description: '闪亮的皇冠，让你的猫咪成为真正的王者',
        imagePath: 'assets/accessories/hat_crown.png',
        svgAsset: 'assets/svgs/accessories/hat_crown.svg',
        type: AccessoryType.hat,
        rarity: AccessoryRarity.epic,
        price: 1000,
      ),
      const Accessory(
        id: 'hat_wizard',
        name: '魔法帽',
        description: '神秘的魔法帽，蕴含着强大的魔力',
        imagePath: 'assets/accessories/hat_wizard.png',
        svgAsset: 'assets/svgs/accessories/hat_wizard.svg',
        type: AccessoryType.hat,
        rarity: AccessoryRarity.rare,
        price: 800,
      ),
      const Accessory(
        id: 'hat_cap',
        name: '棒球帽',
        description: '时尚的棒球帽，适合日常出街',
        imagePath: 'assets/accessories/hat_cap.png',
        svgAsset: 'assets/svgs/accessories/hat_cap.svg',
        type: AccessoryType.hat,
        rarity: AccessoryRarity.common,
        price: 300,
      ),
    ]);
    
    // 项圈类装饰品
    _allAccessories.addAll([
      const Accessory(
        id: 'collar_bow',
        name: '蝴蝶结项圈',
        description: '可爱的蝴蝶结项圈，让猫咪更加优雅',
        imagePath: 'assets/accessories/collar_bow.png',
        svgAsset: 'assets/svgs/accessories/collar_bow.svg',
        type: AccessoryType.collar,
        rarity: AccessoryRarity.uncommon,
        price: 500,
      ),
      const Accessory(
        id: 'collar_bell',
        name: '铃铛项圈',
        description: '带铃铛的项圈，走路时会发出清脆的声音',
        imagePath: 'assets/accessories/collar_bell.png',
        svgAsset: 'assets/svgs/accessories/collar_bell.svg',
        type: AccessoryType.collar,
        rarity: AccessoryRarity.common,
        price: 300,
      ),
    ]);
    
    // 眼镜类装饰品
    _allAccessories.addAll([
      const Accessory(
        id: 'glasses_sunglasses',
        name: '墨镜',
        description: '酷炫的墨镜，让猫咪看起来更有范',
        imagePath: 'assets/accessories/glasses_sunglasses.png',
        svgAsset: 'assets/svgs/accessories/glasses_sunglasses.svg',
        type: AccessoryType.glasses,
        rarity: AccessoryRarity.uncommon,
        price: 600,
      ),
      const Accessory(
        id: 'glasses_reading',
        name: '阅读眼镜',
        description: '学术气息浓厚的眼镜，适合学霸猫咪',
        imagePath: 'assets/accessories/glasses_reading.png',
        svgAsset: 'assets/svgs/accessories/glasses_reading.svg',
        type: AccessoryType.glasses,
        rarity: AccessoryRarity.common,
        price: 400,
      ),
    ]);
    
    // 服装类装饰品
    _allAccessories.addAll([
      const Accessory(
        id: 'costume_cape',
        name: '超级英雄披风',
        description: '让你的猫咪成为守护城市的超级英雄',
        imagePath: 'assets/accessories/costume_cape.png',
        svgAsset: 'assets/svgs/accessories/costume_cape.svg',
        type: AccessoryType.costume,
        rarity: AccessoryRarity.rare,
        price: 900,
      ),
      const Accessory(
        id: 'costume_sweater',
        name: '毛线衫',
        description: '温暖的毛线衫，适合在寒冷的冬天穿着',
        imagePath: 'assets/accessories/costume_sweater.png',
        svgAsset: 'assets/svgs/accessories/costume_sweater.svg',
        type: AccessoryType.costume,
        rarity: AccessoryRarity.common,
        price: 350,
      ),
    ]);
    
    // 背景类装饰品
    _allAccessories.addAll([
      const Accessory(
        id: 'background_space',
        name: '宇宙背景',
        description: '浩瀚的宇宙背景，让猫咪看起来像是在太空中漫游',
        imagePath: 'assets/accessories/background_space.png',
        svgAsset: 'assets/svgs/accessories/background_space.svg',
        type: AccessoryType.background,
        rarity: AccessoryRarity.legendary,
        price: 1500,
      ),
      const Accessory(
        id: 'background_beach',
        name: '海滩背景',
        description: '阳光明媚的海滩背景，适合夏日度假',
        imagePath: 'assets/accessories/background_beach.png',
        svgAsset: 'assets/svgs/accessories/background_beach.svg',
        type: AccessoryType.background,
        rarity: AccessoryRarity.rare,
        price: 800,
      ),
    ]);
  }
} 