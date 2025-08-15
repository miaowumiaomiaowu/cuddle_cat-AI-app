import 'package:flutter/foundation.dart';
import '../services/dialogue_service.dart';
import '../models/dialogue.dart';
import '../models/cat.dart';
import 'base_provider.dart';

/// 对话状态提供者
class DialogueProvider extends BaseProvider {
  final DialogueService _dialogueService = DialogueService();
  DialogueSession? _activeSession;
  bool _useAI = true;
  bool _isProcessing = false;

  // API调用相关字段 - 用于调试和监控
  DateTime? _lastApiCall;
  int _apiCallCount = 0;

  @override
  String get providerId => 'dialogue_provider';

  /// 构造函数
  DialogueProvider();

  /// 获取当前活跃会话
  DialogueSession? get activeSession => _activeSession;

  /// 获取历史会话列表
  List<DialogueSession> get historySessions => _dialogueService.historySessions;

  /// 获取AI模式状态
  bool get useAI => _useAI;

  /// 获取是否正在处理消息
  bool get isProcessing => _isProcessing;

  /// 获取API最后一次调用时间
  DateTime? get lastApiCall => _lastApiCall;

  /// 获取API调用次数
  int get apiCallCount => _apiCallCount;

  @override
  Map<String, dynamic> get persistentData {
    return {
      'activeSession': _activeSession?.toJson(),
      'historySessions': _dialogueService.historySessions.map((s) => s.toJson()).toList(),
      'useAI': _useAI,
      'apiCallCount': _apiCallCount,
      'lastApiCall': _lastApiCall?.toIso8601String(),
    };
  }

  @override
  Future<void> restoreFromData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('useAI')) {
        _useAI = data['useAI'] as bool;
        markPropertyChanged('useAI');
      }
      
      if (data.containsKey('apiCallCount')) {
        _apiCallCount = data['apiCallCount'] as int;
        markPropertyChanged('apiCallCount');
      }
      
      if (data.containsKey('lastApiCall') && data['lastApiCall'] != null) {
        _lastApiCall = DateTime.parse(data['lastApiCall'] as String);
        markPropertyChanged('lastApiCall');
      }
      
      // 恢复会话数据通过DialogueService处理
      await _dialogueService.loadSessions();
      _activeSession = _dialogueService.activeSession;
      markPropertyChanged('activeSession');
    } catch (e) {
      debugPrint('DialogueProvider: 恢复对话数据失败 - $e');
    }
  }

  @override
  Future<void> onInitialize() async {
    await _loadActiveSession();
  }

  /// 切换AI模式（统一使用AI，此方法保留但不再切换状态）
  void toggleAIMode() {
    // 强制保持 AI 模式
    if (!_useAI) {
      batchUpdate(() {
        _useAI = true;
        markPropertyChanged('useAI');
      });
      saveData();
    }
  }

  /// 加载活跃会话
  Future<void> _loadActiveSession() async {
    try {
      await _dialogueService.loadSessions();
      _activeSession = _dialogueService.activeSession;
      markPropertyChanged('activeSession');
    } catch (e) {
      throw Exception('加载对话历史失败: $e');
    }
  }

  /// 创建新会话
  void createNewSession() {
    batchUpdate(() {
      _activeSession = _dialogueService.createNewSession();
      markPropertyChanged('activeSession');
    });
    saveData(); // 异步保存
  }

  /// 发送用户消息
  Future<void> sendUserMessage(String message, Cat cat) async {
    if (message.trim().isEmpty) return;

    await executeWithErrorHandling(() async {
      batchUpdate(() {
        _isProcessing = true;
        markPropertyChanged('isProcessing');
      });

      try {
        // 确保有活跃会话
        if (_activeSession == null) {
          createNewSession();
        }

        // 设置AI模式
        _dialogueService.useAI = _useAI;

        // 处理消息
        await _dialogueService.processUserMessage(
          messageText: message,
          cat: cat,
        );

        batchUpdate(() {
          _activeSession = _dialogueService.activeSession;
          markPropertyChanged('activeSession');

          // 如果使用AI，记录API调用
          if (_useAI) {
            _lastApiCall = DateTime.now();
            _apiCallCount++;
            markPropertyChanged('lastApiCall');
            markPropertyChanged('apiCallCount');
          }
        });

        await saveData(); // 保存会话数据
      } finally {
        batchUpdate(() {
          _isProcessing = false;
          markPropertyChanged('isProcessing');
        });
      }
    }, errorMessage: '发送消息失败', showLoading: false);
  }

  @override
  Future<void> onClearData() async {
    _activeSession = null;
    _apiCallCount = 0;
    _lastApiCall = null;
    _isProcessing = false;
  }
}