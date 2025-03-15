import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/cat.dart';
import '../utils/cat_icons.dart';

class SvgCatImage extends StatelessWidget {
  final Cat cat;
  final double size;
  final String? action;
  final CatMoodState? overrideMood;
  final Map<String, String>? customAccessories;

  const SvgCatImage({
    super.key,
    required this.cat,
    this.size = 200,
    this.action,
    this.overrideMood,
    this.customAccessories,
  });

  @override
  Widget build(BuildContext context) {
    // 获取SVG字符串
    final svgString = CatIcons.getCatSvgString(
      cat.breed, 
      mood: overrideMood ?? cat.mood,
      accessories: customAccessories ?? cat.equippedAccessories,
    );

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svgString,
        width: size,
        height: size,
      ),
    );
  }
} 