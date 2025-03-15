import 'package:flutter/material.dart';
import '../services/dialogue_service.dart';
import '../services/ai_service.dart';
import '../models/dialogue.dart';
import '../models/cat.dart';

/// 对话状态提供者
class DialogueProvider extends ChangeNotifier {
  final DialogueService _dialogueService = DialogueService();
  final AIService _aiService = AIService();
  DialogueSession? _activeSession;
  bool _useAI = true;
  bool _isProcessing = false;
  String? _errorMessage;
  DateTime? _lastApiCall;
  int _apiCallCount = 0;
  String? _lastApiResponse;
  bool _isLoading = false;
  
  /// 构造函数
  DialogueProvider() {
    _loadActiveSession();
  }
  
  /// 获取当前活跃会话
  DialogueSession? get activeSession => _activeSession;
  
  /// 获取历史会话列表
  List<DialogueSession> get historySessions => _dialogueService.historySessions;
  
  /// 获取是否正在加载
  bool get isLoading => _isLoading;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 获取AI模式状态
  bool get useAI => _useAI;
  
  /// 获取是否正在处理消息
  bool get isProcessing => _isProcessing;
  
  /// 获取API最后一次调用时间
  DateTime? get lastApiCall => _lastApiCall;
  
  /// 获取API调用次数
  int get apiCallCount => _apiCallCount;
  
  /// 获取API最后一次响应
  String? get lastApiResponse => _lastApiResponse;
  
  /// 切换AI模式
  void toggleAIMode() {
    _useAI = !_useAI;
    print('AI模式切换: $_useAI');
    notifyListeners();
  }
  
  /// 加载活跃会话
  Future<void> _loadActiveSession() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dialogueService.loadSessions();
      _activeSession = _dialogueService.activeSession;
    } catch (e) {
      print('加载对话历史失败: $e');
      _errorMessage = '加载对话历史失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 创建新会话
  void createNewSession() {
    _activeSession = _dialogueService.createNewSession();
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 发送用户消息
  Future<void> sendUserMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // 重置错误消息
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // 确保有活跃会话
      if (_activeSession == null) {
        createNewSession();
      }
      
      // 处理消息
      await _dialogueService.processUserMessage(
        messageText: message,
        cat: _mockCat(),
      );
      
      _activeSession = _dialogueService.activeSession;
      
      // 如果使用AI，记录API调用
      if (_useAI) {
        _lastApiCall = DateTime.now();
        _apiCallCount++;
      }
    } catch (e) {
      print('发送消息出错: $e');
      _errorMessage = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // 创建一个模拟猫咪对象用于测试
  Cat _mockCat() {
    return Cat(
      name: '喵喵',
      breed: CatBreed.random,
      mood: CatMoodState.happy,
      growthStage: CatGrowthStage.kitten,
      energyLevel: 80,
      happiness: 70,
    );
  }
} 