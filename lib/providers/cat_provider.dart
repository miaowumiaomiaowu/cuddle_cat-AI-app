import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';
import 'base_provider.dart';

/// 猫咪状态管理Provider
class CatProvider extends BaseProvider {
  final CatService _catService = CatService();
  Cat? _cat;

  @override
  String get providerId => 'cat_provider';

  // 获取当前猫咪
  Cat? get cat => _cat;

  // 判断用户是否有猫咪
  bool get hasCat => _cat != null;

  // 构造函数
  CatProvider();

  @override
  Future<void> onInitialize() async {
    await _loadCat();
  }

  @override
  Map<String, dynamic> get persistentData {
    return _cat?.toJson() ?? {};
  }

  @override
  Future<void> restoreFromData(Map<String, dynamic> data) async {
    if (data.isNotEmpty) {
      try {
        _cat = Cat.fromJson(data);
        _cat?.updateStatus();
        markPropertyChanged('cat');
      } catch (e) {
        debugPrint('CatProvider: 恢复猫咪数据失败 - $e');
      }
    }
  }

  // 初始化，加载猫咪数据
  Future<void> _loadCat() async {
    try {
      final loadedCat = await _catService.loadCat();
      if (loadedCat != null) {
        _cat = loadedCat;
        _cat!.updateStatus();
        markPropertyChanged('cat');
      }
    } catch (e) {
      throw Exception('加载猫咪数据失败: $e');
    }
  }

  // 领养新猫咪
  Future<void> adoptCat({required String name, required CatBreed breed}) async {
    await executeWithErrorHandling(() async {
      _cat = await _catService.adoptCat(name: name, breed: breed);
      markPropertyChanged('cat');
      await saveData(immediate: true);
    }, errorMessage: '领养猫咪失败');
  }

  // 喂食猫咪
  void feedCat() {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.feed();
        markPropertyChanged('cat');
      });
      _saveCatAsync();
    }
  }

  // 抚摸猫咪
  void petCat() {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.pet();
        markPropertyChanged('cat');
      });
      _saveCatAsync();
    }
  }

  // 与猫咪玩耍
  void playWithCat() {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.play();
        markPropertyChanged('cat');
      });
      _saveCatAsync();
    }
  }

  // 给猫咪洗澡/梳理
  void groomCat() {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.groom();
        markPropertyChanged('cat');
      });
      _saveCatAsync();
    }
  }

  // 拥抱猫咪
  void hugCat() {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.hug();
        markPropertyChanged('cat');
      });
      _saveCatAsync();
    }
  }

  // 训练猫咪
  void trainCat() {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.train();
        markPropertyChanged('cat');
      });
      _saveCatAsync();
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



  // 更新猫咪名字
  void updateCatName(String newName) {
    if (_cat != null) {
      batchUpdate(() {
        _cat!.name = newName;
        markPropertyChanged('cat');
      });
      _saveCatAsync();
    }
  }

  // 重置猫咪数据（仅用于测试/调试）
  Future<void> resetCat() async {
    await executeWithErrorHandling(() async {
      await _catService.removeCat();
      _cat = null;
      markPropertyChanged('cat');
      await saveData(immediate: true);
    }, errorMessage: '重置猫咪数据失败');
  }

  @override
  Future<void> onClearData() async {
    _cat = null;
    await _catService.removeCat();
  }

  // 异步保存猫咪数据
  void _saveCatAsync() {
    if (_cat != null) {
      _catService.saveCat(_cat!).catchError((e) {
        debugPrint('CatProvider: 异步保存猫咪数据失败 - $e');
      });
    }
  }
}
