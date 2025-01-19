import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:cuddle_cat/models/cat.dart';

class CatDisplay extends StatelessWidget {
  const CatDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatModel>(
      builder: (context, catModel, child) {
        return GestureDetector(
          onTapDown: (details) => _handleInteraction(details, context, catModel),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // 背景装饰
                Positioned.fill(
                  child: _buildBackground(catModel.mood),
                ),
                
                // 猫咪动画
                Center(
                  child: _buildCatAnimation(catModel.currentAction),
                ),
                
                // 心情指示器
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildMoodIndicator(catModel.mood),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(CatMood mood) {
    Color backgroundColor;
    switch (mood) {
      case CatMood.happy:
        backgroundColor = Colors.yellow[100]!;
        break;
      case CatMood.sleepy:
        backgroundColor = Colors.blue[50]!;
        break;
      case CatMood.hungry:
        backgroundColor = Colors.orange[50]!;
        break;
      default:
        backgroundColor = Colors.pink[50]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildCatAnimation(CatAction action) {
    String animationPath;
    switch (action) {
      case CatAction.eating:
        animationPath = 'assets/animations/cat_eating.json';
        break;
      case CatAction.playing:
        animationPath = 'assets/animations/cat_playing.json';
        break;
      default:
        animationPath = 'assets/animations/cat_idle.json';
    }

    return Lottie.asset(
      animationPath,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMoodIndicator(CatMood mood) {
    IconData iconData;
    Color iconColor;
    
    switch (mood) {
      case CatMood.happy:
        iconData = Icons.sentiment_very_satisfied;
        iconColor = Colors.yellow[700]!;
        break;
      case CatMood.sleepy:
        iconData = Icons.bedtime;
        iconColor = Colors.blue[700]!;
        break;
      case CatMood.hungry:
        iconData = Icons.restaurant;
        iconColor = Colors.orange[700]!;
        break;
      default:
        iconData = Icons.sentiment_satisfied;
        iconColor = Colors.pink[700]!;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _handleInteraction(TapDownDetails details, BuildContext context, CatModel catModel) {
    // 根据点击位置计算互动类型
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final center = box.size.center(Offset.zero);
    
    // 根据点击位置与中心点的距离决定互动类型
    final distance = (localPosition - center).distance;
    
    if (distance < 50) {
      // 点击中心区域，抚摸猫咪
      catModel.pet();
    }
  }
}