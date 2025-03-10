import 'package:flutter/material.dart';

class CatHomeScreen extends StatefulWidget {
  const CatHomeScreen({super.key});

  @override
  State<CatHomeScreen> createState() => _CatHomeScreenState();
}

class _CatHomeScreenState extends State<CatHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHappy = false;
  int _petCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPetCat() {
    setState(() {
      _petCount++;
      _isHappy = true;
    });
    
    // 猫咪高兴状态持续1.5秒
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isHappy = false;
        });
      }
    });
    
    // 添加一个小动画
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '猫咪家园',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
            onPressed: () {
              // 打开装扮商店
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('装扮商店即将开放！'))
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 猫咪状态面板
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusItem(Icons.favorite, '心情', _isHappy ? '开心' : '平静'),
                  _buildStatusItem(Icons.battery_charging_full, '能量', '80%'),
                  _buildStatusItem(Icons.child_care, '成长', '幼猫期'),
                ],
              ),
            ),
            
            // 猫咪显示区域
            Expanded(
              child: GestureDetector(
                onTap: _onPetCat,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 猫咪形象
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_controller.value * 0.1),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 这里将来会替换为真实的猫咪图像
                                Icon(
                                  Icons.pets,
                                  size: 120,
                                  color: _isHappy ? Colors.pink : Colors.grey.shade700,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _isHappy ? '喵~ 好舒服！' : '摸摸我吧~',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isHappy ? Colors.pink : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // 当被抚摸时显示的效果
                      if (_isHappy)
                        ...List.generate(
                          5,
                          (index) => Positioned(
                            left: 140 + (index - 2) * 30,
                            top: 80 + (index % 3) * 20,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.pink.withOpacity(0.7),
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 互动按钮栏
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInteractionButton(Icons.dining, '喂食', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('喂食功能即将开放！'))
                    );
                  }),
                  _buildInteractionButton(Icons.pets, '抚摸', _onPetCat),
                  _buildInteractionButton(Icons.toys, '玩耍', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('玩耍功能即将开放！'))
                    );
                  }),
                  _buildInteractionButton(Icons.chat_bubble_outline, '对话', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('对话功能即将开放！'))
                    );
                  }),
                ],
              ),
            ),
            
            // 抚摸计数器
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '今日已抚摸: $_petCount 次',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isHappy && label == '心情' 
                ? Theme.of(context).primaryColor 
                : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
} 