import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuddle_cat/models/cat.dart';
import 'package:cuddle_cat/widgets/cat_display.dart';
import 'package:cuddle_cat/widgets/interaction_panel.dart';
import 'package:cuddle_cat/widgets/status_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 状态面板
            const StatusPanel(),
            
            // 猫咪显示区域
            const Expanded(
              flex: 2,
              child: CatDisplay(),
            ),
            
            // 互动面板
            const InteractionPanel(),
          ],
        ),
      ),
    );
  }
}