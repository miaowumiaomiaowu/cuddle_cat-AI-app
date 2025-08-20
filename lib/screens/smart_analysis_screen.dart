import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../widgets/enhanced_chart_widget.dart';
import '../providers/mood_provider.dart';
import '../providers/happiness_provider.dart';
import '../providers/dialogue_provider.dart';
import '../providers/user_provider.dart';
import '../services/ai_psychology_service.dart';
import '../services/ai_analysis_facade.dart';
import '../services/ai_analysis_http.dart';
import '../services/config_service.dart';
import '../services/memory_service.dart';
import '../services/smart_reminder_service.dart';
import '../services/feedback_service.dart';
import '../services/network_service.dart';
import '../widgets/gradient_button.dart';

import '../services/ai_trace_service.dart';
import '../widgets/settings/reminder_settings_panel.dart';
import 'happiness_task_edit_screen.dart';

class SmartAnalysisScreen extends StatefulWidget {
  const SmartAnalysisScreen({super.key});

  @override
  State<SmartAnalysisScreen> createState() => _SmartAnalysisScreenState();
}

class _SmartAnalysisScreenState extends State<SmartAnalysisScreen> {
  // 心情分析
  PsychologyInsight? _insight;
  bool _loadingInsight = true;
  String? _insightError;

  // 综合分析（HTTP/Stub）
  AnalysisResult? _analysis;
  bool _loadingAnalysis = true;
  String? _analysisError;

  // 记忆
  final MemoryService _memoryService = MemoryService();
  List<MemoryEvent> _memories = [];
  bool _loadingMemories = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadInsight(),
      _loadAnalysis(),
      _loadMemories(),
    ]);
  }

  Future<void> _loadInsight() async {
    setState(() { _loadingInsight = true; _insightError = null; });
    try {
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) {
        setState(() { _insightError = '未登录用户'; _loadingInsight = false; });
        return;
      }
      final svc = AIPsychologyService();
      final insight = await svc.analyzeMoodPattern(moodProvider.moodEntries, userProvider.currentUser!);
      if (!mounted) return;
      setState(() { _insight = insight; _loadingInsight = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _insightError = '心情分析失败: $e'; _loadingInsight = false; });
    }
  }

  Future<void> _loadAnalysis() async {
    setState(() { _loadingAnalysis = true; _analysisError = null; });
    try {
      final dialogue = Provider.of<DialogueProvider>(context, listen: false);
      final moods = Provider.of<MoodProvider>(context, listen: false);
      final hp = Provider.of<HappinessProvider>(context, listen: false);
      final cfg = ConfigService.instance;
      final facade = cfg.isRemoteConfigured ? AIAnalysisHttp(cfg.serverBaseUrl) : AIAnalysisStub();

      final msgs = dialogue.activeSession?.messages ?? const [];
      final signals = UserSignals(
        recentMessages: msgs.reversed.map((m) => m.text).take(20).toList(),
        moodRecords: moods.moodEntries.take(30).map((m) => {
          'timestamp': m.timestamp.toIso8601String(),
          'mood': m.mood.toString(),
          'description': m.description ?? '',
        }).toList(),
        stats: {
          'streak': hp.stats?.currentStreak ?? 0,
          'completionRate7d': hp.stats?.completionRate7d ?? 0.0,
        },
      );
      final res = await facade.analyzeAndRecommend(signals);
      if (!mounted) return;
      setState(() { _analysis = res; _loadingAnalysis = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _analysisError = '综合分析失败: $e'; _loadingAnalysis = false; });
    }
  }

  Future<void> _loadMemories() async {
    setState(() { _loadingMemories = true; });
    final data = await _memoryService.getMemories();
    if (!mounted) return;
    setState(() { _memories = data..sort((a,b)=>b.timestamp.compareTo(a.timestamp)); _loadingMemories = false; });
  }

  Future<void> _deleteMemory(String id) async {
    await _memoryService.deleteMemory(id);
    await _loadMemories();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('记忆已删除')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HappinessProvider>(context);
    final reminder = hp.reminderService; // 暴露的 getter

    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('智能分析'),
        backgroundColor: Colors.transparent,
        foregroundColor: ArtisticTheme.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async { await _bootstrap(); },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBackendInfoSection(),
            const SizedBox(height: 16),
            _buildMoodAnalysisSection(),
            const SizedBox(height: 16),
            _buildComprehensiveAnalysisSection(),
            const SizedBox(height: 16),
            _buildAnalysisTracerSection(),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            _buildPrimaryCTA(),
            const SizedBox(height: 16),

            _buildPersonalizedGiftsSection(hp),
            const SizedBox(height: 16),
            _buildMemorySection(),
            const SizedBox(height: 16),
            _buildSmartReminderSection(reminder),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: ArtisticTheme.artisticCard,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildBackendInfoSection() {
    return _card(
      child: FutureBuilder<BackendHealth>(
        future: NetworkService.instance.healthCheck(),
        builder: (context, snap) {
          if (!snap.hasData) return const LinearProgressIndicator(minHeight: 2);
          final h = snap.data!;
          final provider = h.provider ?? '未知';
          final model = h.model ?? '-';
          final version = h.version ?? '-';
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [Icon(Icons.plumbing, color: Colors.black87), SizedBox(width: 8), Text('后端与模型信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 8),
            Text('Base URL: ${ConfigService.instance.serverBaseUrl}', style: ArtisticTheme.caption),
            Text('Remote Enabled: ${ConfigService.instance.enableRemoteBackend}', style: ArtisticTheme.caption),
            const SizedBox(height: 6),
            Text('Provider: $provider', style: ArtisticTheme.bodySmall),
            Text('Model: $model', style: ArtisticTheme.bodySmall),
            Text('Version: $version', style: ArtisticTheme.bodySmall),
            if (!h.ok) ...[
              const SizedBox(height: 8),
              Text('健康检查失败 (HTTP ${h.statusCode ?? '-'})', style: TextStyle(color: ArtisticTheme.errorColor)),
              if (h.rawBody != null) Text(h.rawBody!.substring(0, h.rawBody!.length > 200 ? 200 : h.rawBody!.length), style: ArtisticTheme.caption),
            ],
          ]);
        },
      ),
    );
  }

  // A. 心情分析模块
  Widget _buildMoodAnalysisSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.mood, color: Colors.pink),
              SizedBox(width: 8),
              Text('心情分析', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMoodTrendChart(),
          const SizedBox(height: 12),
          if (_loadingInsight) const LinearProgressIndicator(minHeight: 2),
          if (_insightError != null) Text(_insightError!, style: TextStyle(color: ArtisticTheme.errorColor)),
          if (!_loadingInsight && _insight != null) ...[
            Text(_insight!.mainInsight, style: ArtisticTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('健康度评分：${(_insight!.wellnessScore * 100).toStringAsFixed(0)}', style: ArtisticTheme.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _insight!.recommendations.map((r) => Chip(label: Text(r))).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodTrendChart() {
    final moods = Provider.of<MoodProvider>(context).moodEntries.take(14).toList().reversed.toList();
    String fmt(DateTime dt) => '${dt.month}/${dt.day}';
    final data = <String,double>{};
    for (final m in moods) {
      data[fmt(m.timestamp)] = m.intensity.toDouble();
    }
    return EnhancedChartWidget(
      chartType: ChartType.line,
      data: data,
      title: '近况心情强度',
      subtitle: '越高表示情感更强烈',
      primaryColor: Colors.pink,
      height: 200,
      showLegend: false,
    );
  }

  // 综合分析探查器
  Widget _buildAnalysisTracerSection() {
    final traces = AiTraceService.instance.entries;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.search, color: Colors.indigo), SizedBox(width: 8), Text('分析探查器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        if (traces.isEmpty) Text('暂无请求记录，触发一次综合分析即可看到日志', style: ArtisticTheme.caption),
        ...traces.take(5).map((t) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(t.success ? Icons.check_circle : Icons.error_outline, color: t.success ? Colors.green : ArtisticTheme.errorColor),
          title: Text('${t.path}  ·  ${t.statusCode ?? '-'}  ·  ${(t.duration?.inMilliseconds ?? 0)}ms'),
          subtitle: Text('req: ${t.requestSummary}  resp: ${t.responseSummary ?? t.error ?? ''}'),
          onTap: () {},
        )),
      ]),
    );
  }

  // B. 综合分析模块
  Widget _buildComprehensiveAnalysisSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.analytics, color: Colors.blue), SizedBox(width: 8), Text('综合分析', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 12),
          if (_loadingAnalysis) const LinearProgressIndicator(minHeight: 2),
          if (_analysisError != null) Text(_analysisError!, style: TextStyle(color: ArtisticTheme.errorColor)),
          if (!_loadingAnalysis && _analysis != null) ...[
            if (_analysis!.scores.isNotEmpty)
              EnhancedChartWidget(
                chartType: ChartType.bar,
                data: _analysis!.scores.map((k,v)=>MapEntry(k, v)),
                title: '情绪得分',
                subtitle: '来自后端或本地分析',
                primaryColor: Colors.blue,
                height: 180,
                showLegend: false,
              ),
            const SizedBox(height: 8),
            if (_analysis!.emotions.isNotEmpty)
              Wrap(spacing: 8, children: _analysis!.emotions.map((e)=>Chip(label: Text(e))).toList()),
          ],
        ],
      ),
    );
  }

  // C. 定制幸福清单（使用 Provider 的 recommendations）
  Widget _buildPersonalizedGiftsSection(HappinessProvider hp) {
    final gifts = hp.recommendations;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.favorite, color: Colors.red),
            const SizedBox(width: 8),
            const Text('个性化幸福清单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(HappinessTaskEditScreen.routeName),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('自定义'),
            ),
          ]),
          const SizedBox(height: 8),
          if (gifts.isEmpty) Text('暂无推荐，稍后下拉刷新试试~', style: ArtisticTheme.caption),
          ...gifts.map((t) => _giftTile(t.title, t.emoji, t.description, t.reason, t.estimatedMinutes)),
        ],
      ),
    );
  }

  Widget _giftTile(String title, String emoji, String desc, String? reason, int? minutes) {
    final fb = FeedbackService();
    final giftId = '$title|$emoji';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ArtisticTheme.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children:[Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Expanded(child: Text(title, style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600))) , if (minutes!=null) Text('${minutes}min', style: ArtisticTheme.caption)]),
        if (desc.isNotEmpty) ...[const SizedBox(height: 6), Text(desc, style: ArtisticTheme.caption)],
        if (reason!=null && reason.isNotEmpty) ...[const SizedBox(height: 6), Text('推荐理由：$reason', style: ArtisticTheme.caption.copyWith(color: ArtisticTheme.textSecondary))],
        const SizedBox(height: 6),
        Row(children:[
          IconButton(
            tooltip: '喜欢',
            icon: const Icon(Icons.thumb_up_alt_outlined, size: 20),
            onPressed: () async {
              await fb.recordFeedback(GiftFeedback(
                giftId: giftId,
                giftTitle: title,
                type: FeedbackType.like,
                timestamp: DateTime.now(),
              ));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已记录喜欢反馈')));
            },
          ),
          IconButton(
            tooltip: '不喜欢',
            icon: const Icon(Icons.thumb_down_alt_outlined, size: 20),
            onPressed: () async {
              await fb.recordFeedback(GiftFeedback(
                giftId: giftId,
                giftTitle: title,
                type: FeedbackType.dislike,
                timestamp: DateTime.now(),
              ));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已记录不喜欢反馈')));
            },
          ),
        ])
      ]),
    );
  }

  // D. 记忆功能模块
  Widget _buildMemorySection() {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.memory, color: Colors.deepPurple), SizedBox(width: 8), Text('AI 记忆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        if (_loadingMemories) const LinearProgressIndicator(minHeight: 2),
        if (!_loadingMemories && _memories.isEmpty) Text('暂无记忆，后续将自动提取重要信息', style: ArtisticTheme.caption),
        ..._memories.take(6).map((m) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bookmark_border),
          title: Text(m.summary),
          subtitle: Text('${m.type} · ${m.timestamp.toLocal()}'),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteMemory(m.id)),
          onTap: () => _showMemoryDetail(m),
        )),
      ]),
    );
  }

  void _showMemoryDetail(MemoryEvent m) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: AlertDialog(
        title: Text('记忆详情'),
        content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('类型：${m.type}'),
          const SizedBox(height: 8),
          Text('摘要：${m.summary}'),
          if (m.evidence!=null && m.evidence!.isNotEmpty) ...[const SizedBox(height: 8), Text('依据：${m.evidence!}')],
          const SizedBox(height: 8),
          Text('重要性：${m.significance.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: m.tags.map((t)=>Chip(label: Text(t))).toList()),
        ])),
        actions: [
          TextButton(onPressed: ()=>Navigator.of(ctx).pop(), child: const Text('关闭')),
        ],
            ),
          ),
        );
      },
    );
  }

  // E. 智能提醒模块（嵌入完整设置面板 + 幸福清单自定义入口）
  Widget _buildSmartReminderSection(SmartReminderService service) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children: const [Icon(Icons.alarm, color: Colors.teal), SizedBox(width: 8), Text('智能提醒与自定义', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        // 提醒设置面板
        ReminderSettingsPanel(reminderService: service),
        const SizedBox(height: 12),
        // 自定义幸福清单入口
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(HappinessTaskEditScreen.routeName),
            icon: const Icon(Icons.tune),
            label: const Text('自定义幸福清单'),
          ),
        ),
      ]),
    );
  }

  Widget _buildPrimaryCTA() {
    return Center(
      child: GradientButton(
        onPressed: _bootstrap,
        child: const Text('开始综合分析'),
      ),
    );
  }

}

