import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../models/dialogue.dart';
import '../models/cat.dart';

class AIServiceDebugScreen extends StatefulWidget {
  static const routeName = '/ai-service-debug';
  
  const AIServiceDebugScreen({super.key});

  @override
  State<AIServiceDebugScreen> createState() => _AIServiceDebugScreenState();
}

class _AIServiceDebugScreenState extends State<AIServiceDebugScreen> {
  final AIService _aiService = AIService();
  Map<String, dynamic>? _circuitBreakerStatus;
  String? _testResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() {
    setState(() {
      _circuitBreakerStatus = _aiService.getCircuitBreakerStatus();
    });
  }

  Future<void> _testAIService() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final testMessage = DialogueMessage.fromUser(text: 'Hello, this is a test message');
      final cat = Cat(name: '测试猫', breed: CatBreed.random);
      
      final response = await _aiService.generateCatReply(
        userMessage: testMessage,
        cat: cat,
        conversationHistory: [],
      );
      
      setState(() {
        _testResult = '✅ 测试成功！\n回复: ${response.text}';
        _isLoading = false;
      });
      _refreshStatus();
    } catch (e) {
      setState(() {
        _testResult = '❌ 测试失败！\n错误: $e';
        _isLoading = false;
      });
      _refreshStatus();
    }
  }

  void _resetCircuitBreaker() {
    _aiService.resetCircuitBreaker();
    _refreshStatus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('熔断器已重置')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI服务诊断'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '熔断器状态',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_circuitBreakerStatus != null) ...[
                      _buildStatusRow('状态', _circuitBreakerStatus!['isOpen'] ? '🔴 打开' : '🟢 关闭'),
                      _buildStatusRow('连续失败次数', '${_circuitBreakerStatus!['consecutiveFailures']}'),
                      if (_circuitBreakerStatus!['openedUntil'] != null)
                        _buildStatusRow('打开至', _circuitBreakerStatus!['openedUntil']),
                      if (_circuitBreakerStatus!['remainingSeconds'] > 0)
                        _buildStatusRow('剩余时间', '${_circuitBreakerStatus!['remainingSeconds']}秒'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testAIService,
                  child: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('测试AI服务'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _resetCircuitBreaker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('重置熔断器'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_testResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '测试结果',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(_testResult!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
