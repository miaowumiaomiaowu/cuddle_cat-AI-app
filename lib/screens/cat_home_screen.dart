import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/cat_animation.dart';
import '../widgets/cat_interaction_panel.dart';
import 'adopt_cat_screen.dart';
import 'accessory_shop_screen.dart';
import 'dialogue_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CatHomeScreen extends StatefulWidget {
  const CatHomeScreen({super.key});

  @override
  State<CatHomeScreen> createState() => _CatHomeScreenState();
}

class _CatHomeScreenState extends State<CatHomeScreen> {
  int _petCount = 0;

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
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pushNamed(
                DialogueScreen.routeName,
              );
            },
            tooltip: '与猫咪对话',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccessoryShopScreen(),
                ),
              );
            },
            tooltip: '配饰商店',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('应用状态'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('API配置状态:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('API密钥: ${_isApiKeyConfigured() ? "已配置" : "未配置"}'),
                        const SizedBox(height: 8),
                        const Text('环境变量:'),
                        Text('DEEPSEEK_API_KEY: ${_maskApiKey()}'),
                        Text('DEEPSEEK_API_ENDPOINT: ${_getApiEndpoint()}'),
                        const SizedBox(height: 16),
                        const Text('调试说明:'),
                        const Text('1. 请确保.env文件已正确配置'),
                        const Text('2. API密钥格式应为: sk-xxx...'),
                        const Text('3. 如无法连接，请检查网络设置'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'API状态',
          ),
        ],
      ),
      body: Consumer<CatProvider>(
        builder: (context, catProvider, child) {
          if (catProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!catProvider.hasCat) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    '还没有猫咪哦~',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdoptCatScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('领养一只猫咪'),
                  ),
                ],
              ),
            );
          }

          final cat = catProvider.cat!;
          
          return SafeArea(
            child: Column(
              children: [
                // 猫咪状态面板
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusItem(Icons.favorite, '心情', cat.moodText),
                      _buildStatusItem(Icons.battery_charging_full, '能量', '${cat.energyLevel}%'),
                      _buildStatusItem(Icons.child_care, '成长', cat.growthStageText),
                    ],
                  ),
                ),
                
                // 猫咪显示区域
                Expanded(
                  child: Center(
                    child: CatAnimation(
                      cat: cat,
                      size: 280,
                      onTap: () {
                        setState(() {
                          _petCount++;
                        });
                        catProvider.petCat();
                      },
                    ),
                  ),
                ),
                
                // 猫咪互动面板
                CatInteractionPanel(
                  onPetCat: () {
                    setState(() {
                      _petCount++;
                    });
                  },
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
          );
        },
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
              color: value == '开心' ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 检查API密钥是否已配置
  bool _isApiKeyConfigured() {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty && apiKey.startsWith('sk-');
  }
  
  // 获取并遮盖API密钥
  String _maskApiKey() {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '未配置';
    if (apiKey.length > 10) {
      return '${apiKey.substring(0, 5)}...${apiKey.substring(apiKey.length - 5)}';
    }
    return apiKey;
  }
  
  // 获取API端点
  String _getApiEndpoint() {
    return dotenv.env['DEEPSEEK_API_ENDPOINT'] ?? '未配置';
  }
} 