import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoreAchievementsScreen extends StatelessWidget {
  static const routeName = '/more_achievements';
  const MoreAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的成就（更多）')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('这里将展示更完整的成就体系与徽章（占位）'),
          ],
        ),
      ),
    );
  }
}

