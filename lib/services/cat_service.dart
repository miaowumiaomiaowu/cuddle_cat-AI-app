import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';

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
        print('Error parsing cat data: $e');
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
  Future<Cat> adoptCat({required String name, required CatBreed breed}) async {
    final newCat = Cat(
      name: name,
      breed: breed,
    );
    
    await saveCat(newCat);
    return newCat;
  }
  
  /// 删除猫咪数据
  Future<void> removeCat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_catKey);
  }
} 