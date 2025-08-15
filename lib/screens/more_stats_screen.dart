import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoreStatsScreen extends StatelessWidget {
  static const routeName = '/more_stats';
  const MoreStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的统计（更多）')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('这里将展示更多与AI相关的统计和趋势图表（占位）'),
          ],
        ),
      ),
    );
  }
}

