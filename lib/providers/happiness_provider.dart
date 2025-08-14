import '../models/happiness_task.dart';
import '../models/happiness_checkin.dart';
import '../models/happiness_stats.dart';
import '../models/mood_record.dart';
import '../services/happiness_service.dart';
import '../services/ai_psychology_service.dart';
import 'dialogue_provider.dart';
import 'mood_provider.dart';
import 'user_provider.dart';

/// AI驱动的幸福任务 Provider（第一版：骨架+核心流程）
import 'dart:async';
import 'base_provider.dart';
import '../services/ai_analysis_facade.dart';
import '../services/ai_analysis_http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/breakthrough_detector.dart';

class HappinessProvider extends BaseProvider {
  @override
  String get providerId => 'happiness_provider';

  @override
  Map<String, dynamic> get persistentData => {
    'tasks': _tasks.map((t) => t.toJson()).toList(),
    'checkins': _checkins.map((c) => c.toJson()).toList(),
    'stats': _stats?.toJson(),
    'lastGiftOpenYmd': _lastGiftOpenYmd,
  };

  @override
  Future<void> restoreFromData(Map<String, dynamic> data) async {
    try {
      if (data['tasks'] is List) {
        _tasks = (data['tasks'] as List).map((e) => HappinessTask.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data['checkins'] is List) {
        _checkins = (data['checkins'] as List).map((e) => HappinessCheckin.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data['stats'] is Map) {
        _stats = HappinessStats.fromJson(data['stats'] as Map<String, dynamic>);
      }
      if (data['lastGiftOpenYmd'] is String) {
        _lastGiftOpenYmd = data['lastGiftOpenYmd'] as String;
        markPropertyChanged('lastGiftOpenYmd');
      }
      markPropertyChanged('tasks');
      markPropertyChanged('checkins');
      markPropertyChanged('stats');
    } catch (e) {
      // 忽略恢复异常，使用服务端数据重新加载
    }
  }
  final HappinessService _service = HappinessService.instance;
  final AIPsychologyService aiService;
  final DialogueProvider dialogueProvider;
  final MoodProvider moodProvider;
  final UserProvider userProvider;

  // 状态
  List<HappinessTask> _tasks = [];
  List<HappinessCheckin> _checkins = [];
  List<HappinessTask> _todayTasks = [];
  List<HappinessTask> _recommendations = [];
  HappinessStats? _stats;
  String? _error;
  String? _lastGiftOpenYmd;
  final BreakthroughDetector _breakthroughDetector = BreakthroughDetector();

  HappinessProvider({
    required this.aiService,
    required this.dialogueProvider,
    required this.moodProvider,
    required this.userProvider,
  });

  List<HappinessTask> get tasks => List.unmodifiable(_tasks);
  List<HappinessTask> get todayTasks => List.unmodifiable(_todayTasks);
  List<HappinessTask> get recommendations => List.unmodifiable(_recommendations);
  HappinessStats? get stats => _stats;
  String? get error => _error;
  bool get canOpenGiftToday {
    final today = _ymd(DateTime.now());
    return _lastGiftOpenYmd != today;
  }
  void markGiftOpenedToday() {
    final today = _ymd(DateTime.now());
    if (_lastGiftOpenYmd != today) {
      _lastGiftOpenYmd = today;
      markPropertyChanged('lastGiftOpenYmd');
      safeNotifyListeners();
    }
  }

  @override
  Future<void> onInitialize() async {
    await _loadAll();
    await refreshAIRecommendations(force: true);
    _subscribeDialogueChanges();
  }

  Future<void> _loadAll() async {
    _tasks = await _service.getAllTasks();
    _checkins = await _service.getAllCheckins();
    _stats = await _service.getStats();
  }

  // 生成今日清单：AI优先，无数据走模板
  Future<void> refreshAIRecommendations({bool force = false}) async {
    try {
      final recentMood = moodProvider.moodEntries.isNotEmpty ? moodProvider.moodEntries.first : null;
      final recentEntries = moodProvider.moodEntries.take(30).toList();

      // 基础 insight/advice
      if (recentEntries.isNotEmpty && userProvider.currentUser != null) {
        await aiService.analyzeMoodPattern(recentEntries, userProvider.currentUser!);
      }
      final advice = recentMood != null
          ? await aiService.generatePersonalizedAdvice(recentMood, recentEntries)
          : <String>[
              '尝试深呼吸30秒',
              '做一次简单伸展',
              '写下三件感恩的事',
            ];

      // 优先尝试新的分析门面；失败再回退到旧 advice
      try {
        // 读取配置：优先用户设置，其次 .env
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('ai_analysis_enabled') ?? false;
        final cfgUrl = prefs.getString('ai_analysis_base_url');
        final envUrl = dotenv.env['AI_ANALYSIS_BASE_URL'];
        final baseUrl = (cfgUrl != null && cfgUrl.isNotEmpty) ? cfgUrl : (envUrl ?? '');
        final useHttp = enabled && baseUrl.isNotEmpty;

        final facade = useHttp ? AIAnalysisHttp(baseUrl) : AIAnalysisStub();
        final msgs = dialogueProvider.activeSession?.messages ?? const [];
        final signals = UserSignals(
          recentMessages: msgs.reversed.map((m) => m.text).take(20).toList(),
          moodRecords: moodProvider.moodEntries
              .take(30)
              .map((m) => {
                    'timestamp': m.timestamp.toIso8601String(),
                    'mood': m.mood.toString(),
                    'description': m.description ?? '',
                  })
              .toList(),
          stats: {
            'streak': _stats?.currentStreak ?? 0,
            'completionRate7d': _stats?.completionRate7d ?? 0.0,
          },
        );
        // 补充天气（Open-Meteo，失败忽略）
        Map<String, dynamic>? weather;
        try {
          final pos = await LocationService.instance.getCurrentPosition();
          if (pos != null) {
            weather = await WeatherService.getOpenMeteoCurrentWeather(
              lat: pos.latitude, lon: pos.longitude,
            );
          }
        } catch (_) {}

        final res = await facade.analyzeAndRecommend(signals.copyWith(weather: weather));
        final mapped = res.gifts.map((g) => g.toHappinessTask()).toList();
        _recommendations = mapped.take(8).toList();
      } catch (_) {
        final mapped = _mapAdviceToTasks(advice);
        _recommendations = mapped.take(8).toList();
      }

      // 组装今日清单（简单策略：取前5个尚未归档任务，若无则使用模板）
      final list = <HappinessTask>[];
      for (final t in _recommendations) {
        if (!t.isArchived && list.length < 5) list.add(t);
      }
      if (list.isEmpty) {
        list.addAll(_defaultTemplates().take(5));
      }

      // 合并入任务库（如果是新任务）
      for (final t in list) {
        if (_tasks.indexWhere((x) => x.title == t.title && x.category == t.category) < 0) {
          await _service.saveTask(t);
        }
      }

      _tasks = await _service.getAllTasks();
      _todayTasks = list;
      notifyListeners();
    } catch (e) {
      _setError('AI推荐失败: $e');
    }
  }

  List<HappinessTask> _mapAdviceToTasks(List<String> advice) {
    final result = <HappinessTask>[];
    for (final a in advice) {
      if (a.contains('呼吸') || a.toLowerCase().contains('breath')) {
        result.add(HappinessTask(title: '4-7-8 呼吸', emoji: '🫁', category: 'mind', estimatedMinutes: 3, frequency: 'daily', description: '吸气4秒，憋气7秒，呼气8秒，重复4轮'));
      } else if (a.contains('感恩')) {
        result.add(HappinessTask(title: '记录三件感恩的事', emoji: '🙏', category: 'mind', estimatedMinutes: 5, frequency: 'daily'));
      } else if (a.contains('运动') || a.contains('散步')) {
        result.add(HappinessTask(title: '10分钟散步', emoji: '🚶', category: 'body', estimatedMinutes: 10, frequency: 'daily'));
      } else if (a.contains('联系') || a.contains('朋友') || a.contains('社交')) {
        result.add(HappinessTask(title: '联系一位朋友', emoji: '📞', category: 'social', estimatedMinutes: 5, frequency: 'weekly'));
      } else if (a.contains('冥想')) {
        result.add(HappinessTask(title: '5分钟正念冥想', emoji: '🧘', category: 'mind', estimatedMinutes: 5, frequency: 'daily'));
      } else {
        result.add(HappinessTask(title: a, emoji: '🌿', category: 'selfcare', estimatedMinutes: 5, frequency: 'daily'));
      }
    }
    // 去重（按标题）
    final titles = <String>{};
    return result.where((t) => titles.add(t.title)).toList();
  }

  List<HappinessTask> _defaultTemplates() => [
        HappinessTask(title: '4-7-8 呼吸', emoji: '🫁', category: 'mind', estimatedMinutes: 3, frequency: 'daily'),
        HappinessTask(title: '记录三件感恩的事', emoji: '🙏', category: 'mind', estimatedMinutes: 5, frequency: 'daily'),
        HappinessTask(title: '10分钟散步', emoji: '🚶', category: 'body', estimatedMinutes: 10, frequency: 'daily'),
        HappinessTask(title: '颈肩拉伸', emoji: '🧎', category: 'body', estimatedMinutes: 5, frequency: 'daily'),
        HappinessTask(title: '联系一位朋友', emoji: '📞', category: 'social', estimatedMinutes: 5, frequency: 'weekly'),
      ];

  // 新增/更新任务
  Future<HappinessTask> addOrUpdateTask(HappinessTask task) async {
    await _service.saveTask(task);
    _tasks = await _service.getAllTasks();
    notifyListeners();
    return task;
  }

  // 快速“微幸福”打卡：如深呼吸30秒/伸展/感恩
  Future<void> quickMicroHappiness({
    required String title,
    String emoji = '🌿',
    String category = 'selfcare',
    int estimatedMinutes = 3,
  }) async {
    // 复用同名任务（若不存在则创建一次性任务）
    HappinessTask? task = _tasks.firstWhere(
      (t) => t.title == title,
      orElse: () => HappinessTask(
        title: title,
        emoji: emoji,
        category: category,
        estimatedMinutes: estimatedMinutes,
        frequency: 'once',
      ),
    );
    // 若是新建的一次性任务，则保存到库
    if (_tasks.indexWhere((t) => t.title == title) < 0) {
      task = await addOrUpdateTask(task);
    }
    await completeTask(task);
  }

  // 完成/撤销任务
  Future<void> completeTask(HappinessTask task, {MoodType? before, MoodType? after, int? rating, String? note}) async {
    final ymd = _ymd(DateTime.now());
    final c = HappinessCheckin(
      taskId: task.id,
      ymdDate: ymd,
      moodBefore: before?.toString(),
      moodAfter: after?.toString(),
      notes: note ?? task.title,
      rating: rating,
    );
    await _service.saveCheckin(c);
    _checkins = await _service.getAllCheckins();
    _stats = await _service.getStats();

    // 检测突破模式
    await _analyzeTaskBreakthrough(task);

    notifyListeners();
  }

  // 将推荐加入今日清单
  Future<void> addRecommendationToToday(HappinessTask task) async {
    if (_todayTasks.any((t) => t.title == task.title && t.category == task.category)) return;
    _todayTasks = [..._todayTasks, task];
    // 新任务入库
    if (_tasks.indexWhere((x) => x.title == task.title && x.category == task.category) < 0) {
      await _service.saveTask(task);
      _tasks = await _service.getAllTasks();
    }
    notifyListeners();
  }

  Future<void> uncompleteCheckin(String checkinId) async {
    await _service.deleteCheckin(checkinId);
    _checkins = await _service.getAllCheckins();
    _stats = await _service.getStats();
    notifyListeners();
  }

  String _ymd(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  void _setError(String e) { _error = e; safeNotifyListeners(); }

  void _subscribeDialogueChanges() {
    // 如果 DialogueProvider 有 ChangeNotifier 通知，直接监听其 addListener
    dialogueProvider.addListener(_onDialogueChanged);
  }

  void _onDialogueChanged() {
    // 使用 base_provider 的防抖机制：调用 refresh 会触发内部 notify
    refreshAIRecommendations();
  }

  @override
  Future<void> onClearData() async {
    dialogueProvider.removeListener(_onDialogueChanged);
  }

  Future<void> _analyzeTaskBreakthrough(HappinessTask task) async {
    try {
      // 计算连续完成天数
      final recentCheckins = _checkins
          .where((c) => c.taskId == task.id)
          .toList()
        ..sort((a, b) => b.ymdDate.compareTo(a.ymdDate));

      int consecutiveDays = 0;
      final today = _ymd(DateTime.now());
      String currentDate = today;

      for (final checkin in recentCheckins) {
        if (checkin.ymdDate == currentDate) {
          consecutiveDays++;
          // 计算前一天
          final date = DateTime.parse('${currentDate}T00:00:00');
          final prevDate = date.subtract(const Duration(days: 1));
          currentDate = _ymd(prevDate);
        } else {
          break;
        }
      }

      // 分析突破
      await _breakthroughDetector.analyzeTaskCompletion(
        taskTitle: task.title,
        consecutiveDays: consecutiveDays,
        category: task.category,
      );
    } catch (e) {
      // 忽略分析错误
    }
  }

  @override
  void dispose() {
    dialogueProvider.removeListener(_onDialogueChanged);
    super.dispose();
  }
}

