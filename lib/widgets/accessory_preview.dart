import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../models/accessory.dart';
import 'svg_cat_image.dart';

/// 装饰品预览组件
class AccessoryPreview extends StatelessWidget {
  final Cat cat;
  final Accessory accessory;
  
  const AccessoryPreview({
    Key? key,
    required this.cat,
    required this.accessory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 临时备份猫咪当前的装饰状态
    final originalAccessories = Map<String, String>.from(cat.equippedAccessories);
    
    // 创建一个模拟装备了选中装饰品的装备映射
    final previewAccessories = Map<String, String>.from(cat.equippedAccessories);
    previewAccessories[accessory.type.toString()] = accessory.id;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景装饰（如果选中的是背景类型）
        if (accessory.type == AccessoryType.background)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: accessory.color ?? Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
        // 猫咪形象（带有预览装饰）
        SvgCatImage(
          cat: cat,
          size: 150,
          customAccessories: previewAccessories,
        ),
        
        // 未解锁状态下的价格标签
        if (accessory.isLocked)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${accessory.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 