import 'package:flutter/material.dart';

/// 装饰品类型枚举
enum AccessoryType {
  hat,       // 帽子
  collar,    // 项圈
  glasses,   // 眼镜
  costume,   // 服装
  background // 背景
}

/// 装饰品稀有度枚举
enum AccessoryRarity {
  common,    // 普通
  uncommon,  // 少见
  rare,      // 稀有
  epic,      // 史诗
  legendary  // 传说
}

/// 装饰品模型类
class Accessory {
  final String id;           // 装饰品ID
  final String name;         // 装饰品名称
  final String description;  // 装饰品描述
  final String imagePath;    // 装饰品图片路径
  final String svgAsset;     // SVG资源路径
  final AccessoryType type;  // 装饰品类型
  final AccessoryRarity rarity; // 稀有度
  final int price;           // 价格
  final bool isLocked;       // 是否未解锁
  final Color? color;        // 颜色（可选）
  final Map<String, dynamic> attributes; // 额外属性

  /// 构造函数
  const Accessory({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.svgAsset,
    required this.type,
    required this.rarity,
    required this.price,
    this.isLocked = true,
    this.color,
    this.attributes = const {},
  });

  /// 从JSON创建装饰品
  factory Accessory.fromJson(Map<String, dynamic> json) {
    return Accessory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imagePath: json['imagePath'],
      svgAsset: json['svgAsset'],
      type: _typeFromString(json['type']),
      rarity: _rarityFromString(json['rarity']),
      price: json['price'],
      isLocked: json['isLocked'] ?? true,
      color: json['color'] != null ? Color(json['color']) : null,
      attributes: json['attributes'] ?? {},
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'svgAsset': svgAsset,
      'type': type.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'price': price,
      'isLocked': isLocked,
      'color': color?.value,
      'attributes': attributes,
    };
  }

  /// 从字符串转换为装饰品类型
  static AccessoryType _typeFromString(String typeStr) {
    return AccessoryType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => AccessoryType.hat,
    );
  }

  /// 从字符串转换为稀有度
  static AccessoryRarity _rarityFromString(String rarityStr) {
    return AccessoryRarity.values.firstWhere(
      (e) => e.toString().split('.').last == rarityStr,
      orElse: () => AccessoryRarity.common,
    );
  }

  /// 获取稀有度颜色
  Color get rarityColor {
    switch (rarity) {
      case AccessoryRarity.common:
        return Colors.grey.shade400;
      case AccessoryRarity.uncommon:
        return Colors.green.shade400;
      case AccessoryRarity.rare:
        return Colors.blue.shade400;
      case AccessoryRarity.epic:
        return Colors.purple.shade400;
      case AccessoryRarity.legendary:
        return Colors.orange.shade400;
    }
  }

  /// 获取稀有度文本
  String get rarityText {
    switch (rarity) {
      case AccessoryRarity.common:
        return '普通';
      case AccessoryRarity.uncommon:
        return '少见';
      case AccessoryRarity.rare:
        return '稀有';
      case AccessoryRarity.epic:
        return '史诗';
      case AccessoryRarity.legendary:
        return '传说';
    }
  }

  /// 获取类型文本
  String get typeText {
    switch (type) {
      case AccessoryType.hat:
        return '帽子';
      case AccessoryType.collar:
        return '项圈';
      case AccessoryType.glasses:
        return '眼镜';
      case AccessoryType.costume:
        return '服装';
      case AccessoryType.background:
        return '背景';
    }
  }
} 