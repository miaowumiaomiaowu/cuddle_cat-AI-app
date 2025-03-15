import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/dialogue_provider.dart';
import '../services/ai_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API调试专用页面
class ApiDebugScreen extends StatefulWidget {
  static const routeName = '/api-debug';
  
  const ApiDebugScreen({Key? key}) : super(key: key);

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  String _apiStatus = '未检测';
  bool _isLoading = false;
  String _rawResponse = '';
  String _testInput = '你好，我是测试消息';
  final TextEditingController _inputController = TextEditingController();
  final AIService _aiService = AIService();
  
  @override
  void initState() {
    super.initState();
    _inputController.text = _testInput;
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _checkApiConnection() async {
    setState(() {
      _isLoading = true;
      _apiStatus = '检测中...';
      _rawResponse = '';
    });
    
    try {
      // 获取API密钥和端点
      final String? apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      final String apiEndpoint = dotenv.env['DEEPSEEK_API_ENDPOINT'] ?? 'https://api.deepseek.com/v1/chat/completions';
      
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _apiStatus = '错误: API密钥未配置';
          _isLoading = false;
        });
        return;
      }
      
      // 构建一个简单的请求来测试API连接
      final Map<String, dynamic> requestBody = {
        "model": "deepseek-chat",
        "messages": [
          {"role": "system", "content": "你是一个测试助手"},
          {"role": "user", "content": "API测试请回复'连接成功'"},
        ],
        "temperature": 0.7,
        "max_tokens": 100,
      };
      
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('请求超时');
        },
      );
      
      setState(() {
        _rawResponse = 'HTTP ${response.statusCode}\n\n${response.body}';
      });
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _apiStatus = '连接成功 (${response.statusCode})';
        });
      } else {
        setState(() {
          _apiStatus = '错误: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _apiStatus = '错误: $e';
        _rawResponse = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendTestMessage() async {
    setState(() {
      _isLoading = true;
      _rawResponse = '';
    });
    
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _apiStatus = '错误: 请输入测试消息';
        _isLoading = false;
      });
      return;
    }
    
    try {
      // 记录对话状态提供者的AI模式
      final dialogueProvider = Provider.of<DialogueProvider>(context, listen: false);
      final wasAIEnabled = dialogueProvider.useAI;
      
      // 临时启用AI模式
      if (!wasAIEnabled) {
        dialogueProvider.toggleAIMode();
      }
      
      // 创建一个新的会话
      dialogueProvider.createNewSession();
      
      // 发送测试消息
      await dialogueProvider.sendUserMessage(input);
      
      // 恢复原来的AI模式
      if (!wasAIEnabled && dialogueProvider.useAI) {
        dialogueProvider.toggleAIMode();
      }
      
      setState(() {
        _apiStatus = dialogueProvider.errorMessage ?? '消息发送成功';
        _rawResponse = '最后API响应：\n${dialogueProvider.lastApiResponse ?? "无响应"}';
      });
    } catch (e) {
      setState(() {
        _apiStatus = '错误: $e';
        _rawResponse = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API调试工具'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API配置信息
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API配置信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('API密钥', _maskApiKey()),
                    _buildInfoRow('API端点', _getApiEndpoint()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // API连接测试
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API连接测试', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('状态: $_apiStatus'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _checkApiConnection,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('测试连接'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 消息测试
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('发送测试消息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        labelText: '测试消息',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendTestMessage,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('发送测试消息'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 原始响应
            if (_rawResponse.isNotEmpty)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('原始响应', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _rawResponse,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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
    return dotenv.env['DEEPSEEK_API_ENDPOINT'] ?? 'https://api.deepseek.com/v1/chat/completions';
  }
} 