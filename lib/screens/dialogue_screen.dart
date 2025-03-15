import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dialogue_provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/dialogue_history.dart';
import '../widgets/dialogue_input.dart';
import '../widgets/cat_animation.dart';

/// 对话聊天屏幕
class DialogueScreen extends StatefulWidget {
  /// 路由名称
  static const routeName = '/dialogue';
  
  /// 构造函数
  const DialogueScreen({Key? key}) : super(key: key);
  
  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogueProvider = Provider.of<DialogueProvider>(context, listen: false);
      if (dialogueProvider.activeSession == null) {
        dialogueProvider.createNewSession();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// 发送消息
  void _handleSendMessage(String message) {
    final dialogueProvider = Provider.of<DialogueProvider>(context, listen: false);
    dialogueProvider.sendUserMessage(message);
    
    // 播放猫咪动画
    _animationController.reset();
    _animationController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('与猫咪对话'),
        actions: [
          Consumer<DialogueProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.useAI ? Icons.smart_toy : Icons.chat_bubble,
                  color: provider.useAI ? Colors.blue : null,
                ),
                onPressed: () {
                  provider.toggleAIMode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.useAI ? 'AI模式已开启' : 'AI模式已关闭',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: provider.useAI ? '使用AI聊天(已开启)' : '使用模板聊天(AI已关闭)',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('API状态信息'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('API状态:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Consumer<DialogueProvider>(
                          builder: (ctx, provider, _) {
                            return Text('AI模式: ${provider.useAI ? "开启" : "关闭"}');
                          }
                        ),
                        const SizedBox(height: 10),
                        const Text('调试提示：'),
                        const Text('1. 确保.env文件已正确配置'),
                        const Text('2. 确保API密钥有效'),
                        const Text('3. 检查网络连接'),
                        const Text('4. 如果仍有问题，查看控制台日志'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/api-debug');
                      },
                      child: const Text('打开调试工具'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'API调试信息',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DialogueProvider>(context, listen: false).createNewSession();
            },
            tooltip: '开始新对话',
          ),
        ],
      ),
      body: Consumer2<DialogueProvider, CatProvider>(
        builder: (context, dialogueProvider, catProvider, child) {
          if (!catProvider.hasCat) {
            return _buildNoCatState();
          }
          
          return Column(
            children: [
              // 猫咪动画
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                height: 150,
                child: CatAnimation(
                  cat: catProvider.cat!,
                  size: 150,
                  showMood: true,
                  onTap: () {
                    // 点击猫咪时触发抚摸动作
                    catProvider.petCat();
                  },
                ),
              ),
              
              // AI模式状态指示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      dialogueProvider.useAI ? Icons.smart_toy : Icons.chat_bubble,
                      size: 16,
                      color: dialogueProvider.useAI ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dialogueProvider.useAI ? 'AI智能对话模式' : '模板对话模式',
                      style: TextStyle(
                        fontSize: 12,
                        color: dialogueProvider.useAI ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 错误提示
              if (dialogueProvider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[800]),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          dialogueProvider.errorMessage!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red[800]),
                        onPressed: () {
                          // 清除错误信息
                          setState(() {});
                        },
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                      ),
                    ],
                  ),
                ),
              
              // 对话历史
              Expanded(
                child: dialogueProvider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('猫咪正在思考...', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : DialogueHistory(
                        session: dialogueProvider.activeSession,
                        scrollController: _scrollController,
                      ),
              ),
              
              // 输入框
              DialogueInput(
                onSendMessage: _handleSendMessage,
                isLoading: dialogueProvider.isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 构建无猫状态
  Widget _buildNoCatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '你还没有猫咪',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先领养一只猫咪再开始对话',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回首页'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
} 