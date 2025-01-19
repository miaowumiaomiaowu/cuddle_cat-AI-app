import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuddle_cat/models/cat.dart';

class ColorPicker extends StatelessWidget {
  final String type; // 'fur' or 'eye'
  
  const ColorPicker({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = type == 'fur' 
        ? [
            const Color(0xFFFFE0B2), // 浅橘色
            const Color(0xFFBCAAA4), // 灰色
            const Color(0xFF795548), // 棕色
            const Color(0xFF000000), // 黑色
            const Color(0xFFFFFFFF), // 白色
          ]
        : [
            const Color(0xFF4CAF50), // 绿色
            const Color(0xFF2196F3), // 蓝色
            const Color(0xFFFFC107), // 黄色
            const Color(0xFF9C27B0), // 紫色
          ];

    return Consumer<CatModel>(
      builder: (context, catModel, child) {
        return Wrap(
          spacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                final hexColor = '#${color.value.toRadixString(16).substring(2)}';
                if (type == 'fur') {
                  catModel.updateFurColor(hexColor);
                } else {
                  catModel.updateEyeColor(hexColor);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}