import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuddle_cat/models/cat.dart';

class CustomizeScreen extends StatelessWidget {
  const CustomizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义小猫'),
        backgroundColor: Colors.pink[100],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 预览区域
              const CatPreview(),
              
              const SizedBox(height: 20),
              
              // 毛色选择器
              const Text('毛色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const ColorPicker(type: 'fur'),
              
              const SizedBox(height: 20),
              
              // 眼睛颜色选择器
              const Text('眼睛颜色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const ColorPicker(type: 'eye'),
              
              const SizedBox(height: 20),
              
              // 装饰品选择器
              const Text('装饰品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const AccessoryPicker(),
              
              const SizedBox(height: 20),
              
              // 服装选择器
              const Text('服装', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const OutfitPicker(),
            ],
          ),
        ),
      ),
    );
  }
}

// 预览组件
class CatPreview extends StatelessWidget {
  const CatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatModel>(
      builder: (context, catModel, child) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 这里放置猫咪的各个部分的图层
              // 基础形态
              CustomPaint(
                painter: CatBasePainter(
                  furColor: Color(int.parse(catModel.appearance.furColor.replaceAll('#', '0xff'))),
                  eyeColor: Color(int.parse(catModel.appearance.eyeColor.replaceAll('#', '0xff'))),
                ),
                size: const Size(200, 200),
              ),
              // 装饰品
              if (catModel.appearance.accessory != 'none')
                Image.asset('assets/accessories/${catModel.appearance.accessory}.png'),
              // 服装
              if (catModel.appearance.outfit != 'none')
                Image.asset('assets/outfits/${catModel.appearance.outfit}.png'),
            ],
          ),
        );
      },
    );
  }
}