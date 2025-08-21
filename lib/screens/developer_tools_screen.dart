import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/hand_drawn_card.dart';

import '../widgets/settings/ai_analysis_settings_panel.dart';
import '../widgets/settings/analytics_settings_panel.dart';
import '../widgets/settings/reminder_settings_panel.dart';
import '../widgets/analytics_dashboard.dart';
import '../widgets/learning_dashboard.dart';
import '../widgets/system_health_panel.dart';
import '../providers/happiness_provider.dart';
import '../providers/mood_provider.dart';
import '../services/config_service.dart';
import '../services/network_service.dart';
import '../services/error_handling_service.dart';
import 'metrics_debug_screen.dart';

import 'ai_service_debug_screen.dart';

/// 开发者工具界面
class DeveloperToolsScreen extends StatefulWidget {
  static const String routeName = '/developer_tools';

  const DeveloperToolsScreen({super.key});

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // final PerformanceService _performanceService = PerformanceService(); // 已删除
  // final TestingService _testingService = TestingService(); // 已删除
  // final HealthCheckService _healthCheckService = HealthCheckService(); // 已删除

  bool _isRunningTests = false;
  bool _isRunningHealthCheck = false;
  String _lastReport = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 启动性能监控 (已禁用)
    // _performanceService.startMonitoring();
    // _healthCheckService.startHealthMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // _performanceService.stopMonitoring();
    // _healthCheckService.stopHealthMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '开发者工具',
          style: ArtisticTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: '性能'),
            Tab(icon: Icon(Icons.bug_report), text: '测试'),
            Tab(icon: Icon(Icons.health_and_safety), text: '健康'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'AI分析'),
            Tab(icon: Icon(Icons.info), text: '系统'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPerformanceTab(),
          _buildTestingTab(),
          _buildHealthTab(),
          _buildAIAnalysisTab(),
          _buildSystemTab(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 性能监控控制
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '性能监控',
                    style: ArtisticTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtisticTheme.spacingMedium),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // _performanceService.clearMetrics();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('性能数据已清除 (功能已禁用)')),
                          );
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('清除数据'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _generatePerformanceReport,
                        icon: const Icon(Icons.assessment),
                        label: const Text('生成报告'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingLarge),

          // 性能指标显示
          _buildPerformanceMetrics(),
          const SizedBox(height: ArtisticTheme.spacingLarge),

          // 性能建议
          _buildPerformanceRecommendations(),
        ],
      ),
    );
  }

  Widget _buildTestingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 测试控制
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自动化测试',
                    style: ArtisticTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtisticTheme.spacingMedium),
                  ElevatedButton.icon(
                    onPressed: _isRunningTests ? null : _runAllTests,
                    icon: _isRunningTests
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunningTests ? '测试运行中...' : '运行所有测试'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingLarge),

          // 测试结果显示
          if (_lastReport.isNotEmpty) _buildTestResults(),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 健康检查控制
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '应用健康检查',
                    style: ArtisticTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtisticTheme.spacingMedium),
                  ElevatedButton.icon(
                    onPressed: _isRunningHealthCheck ? null : _runHealthCheck,
                    icon: _isRunningHealthCheck
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.health_and_safety),
                    label: Text(_isRunningHealthCheck ? '检查中...' : '执行健康检查'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingLarge),

          // 健康状态显示
          _buildHealthStatus(),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    // AI 分析配置面板
    Widget buildAIAnalysisSettings() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('AI 分析配置', style: ArtisticTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: AIAnalysisSettingsPanel(),
            ),
          ),
        ],
      );
    }

    Widget buildAnalyticsSettings() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('用户反馈分析', style: ArtisticTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AnalyticsSettingsPanel(),
            ),
          ),
        ],
      );
    }

    Widget buildReminderSettings() {
      return Consumer<HappinessProvider>(
        builder: (context, hp, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('智能提醒设置', style: ArtisticTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ReminderSettingsPanel(
                  reminderService: hp.reminderService,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildAdvancedAnalyticsButton() {
      return Consumer2<HappinessProvider, MoodProvider>(
        builder: (context, hp, mp, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('高级AI分析', style: ArtisticTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('查看用户行为聚类、心情预测模型和深度数据分析'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalyticsDashboard(
                          moodRecords: mp.moodEntries,
                          checkins: hp.checkins,
                          userStats: {
                            'totalTasks': hp.tasks.length,
                            'totalGifts': hp.recommendations.length,
                            'currentStreak': hp.stats?.currentStreak ?? 0,
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('打开分析面板'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildLearningDashboardButton() {
      return Consumer<HappinessProvider>(
        builder: (context, hp, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('实时学习系统', style: ArtisticTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('查看在线学习模型状态、策略权重调整和性能监控'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LearningDashboard(
                          learningService: hp.learningService,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.psychology),
                  label: const Text('打开学习面板'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildSystemHealthPanel() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('系统健康检查', style: ArtisticTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('检查系统状态、数据完整性和服务连接'),
              const SizedBox(height: 12),
              const SystemHealthPanel(),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 系统信息
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '系统信息 / AI 配置',
                    style: ArtisticTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtisticTheme.spacingMedium),
                  _buildSystemInfo(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('last_gift_open_ymd');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已重置今日礼物限制')));
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('重置今日礼物限制'),
                  ),

                  const SizedBox(height: 16),
                  buildAIAnalysisSettings(),
                  const SizedBox(height: 16),
                  buildAnalyticsSettings(),
                  const SizedBox(height: 16),
                  buildReminderSettings(),
                  const SizedBox(height: 16),
                  buildAdvancedAnalyticsButton(),
                  const SizedBox(height: 16),
                  buildLearningDashboardButton(),
                  const SizedBox(height: 16),
                  buildSystemHealthPanel(),
                ],
              ),
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingLarge),

          // 调试工具
          _buildDebugTools(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    // final report = _performanceService.getPerformanceReport();
    final report = <String, dynamic>{}; // 模拟空报告

    if (report.isEmpty) {
      return HandDrawnCard(
        child: Padding(
          padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
          child: Center(
            child: Text(
              '暂无性能数据\n使用应用一段时间后再查看',
              textAlign: TextAlign.center,
              style: ArtisticTheme.bodyMedium.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '性能指标',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            ...report.entries.map((entry) {
              final metrics = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: ArtisticTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${metrics['average']}ms',
                      style: ArtisticTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getPerformanceColor(metrics['average']),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRecommendations() {
    // final recommendations = _performanceService.getPerformanceRecommendations();
    final recommendations = <String>[]; // 模拟空推荐列表

    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '优化建议',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(rec, style: ArtisticTheme.bodyMedium),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '测试报告',
                  style: ArtisticTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _lastReport));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('报告已复制到剪贴板')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: '复制报告',
                ),
              ],
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArtisticTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ArtisticTheme.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _lastReport,
                style: ArtisticTheme.bodySmall.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '健康状态',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Text(
              '定期健康检查正在后台运行\n点击上方按钮执行完整检查',
              style: ArtisticTheme.bodyMedium.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Flutter版本', '3.16.0'), // 实际项目中应该动态获取
        _buildInfoRow('Dart版本', '3.2.0'),
        _buildInfoRow('应用版本', '1.0.0'),
        _buildInfoRow('构建模式', 'Debug'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ArtisticTheme.bodyMedium),
          Text(
            value,
            style: ArtisticTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugTools() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '调试工具',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // 触发垃圾回收
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已触发垃圾回收')),
                    );
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('垃圾回收'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // 重启应用
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('重启功能需要原生支持')),
                    );
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('重启应用'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AIServiceDebugScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.psychology),
                  label: const Text('AI服务诊断'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const MetricsDebugScreen()),
                    );
                  },
                  icon: const Icon(Icons.insights),
                  label: const Text('Metrics 调试'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(int milliseconds) {
    if (milliseconds < 100) return ArtisticTheme.successColor;
    if (milliseconds < 500) return ArtisticTheme.warningColor;
    return ArtisticTheme.errorColor;
  }

  Future<void> _generatePerformanceReport() async {
    // final report = _performanceService.exportPerformanceData();
    final report = '性能监控功能已禁用'; // 模拟报告

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
              title: const Text('性能报告'),
              content: SingleChildScrollView(
                child: Text(
                  report,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: report));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('报告已复制到剪贴板')),
                    );
                  },
                  child: const Text('复制'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAllTests() async {
    setState(() { _isRunningTests = true; });
    final buf = StringBuffer();
    try {
      buf.writeln('== 自检开始 ==');
      buf.writeln('时间: ${DateTime.now().toIso8601String()}');

      // 1) SharedPreferences 读写
      buf.writeln('\n[SharedPreferences]');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('devtools_selftest_key', 'ok');
      final readback = prefs.getString('devtools_selftest_key');
      buf.writeln('写入/读取: ${readback == 'ok' ? '✅' : '❌'}');

      // 2) 配置检查
      buf.writeln('\n[Config]');
      final cfg = ConfigService.instance;
      buf.writeln('ENABLE_REMOTE_BACKEND: ${cfg.enableRemoteBackend}');
      buf.writeln('SERVER_BASE_URL: ${cfg.serverBaseUrl.isEmpty ? '(空)' : cfg.serverBaseUrl}');

      // 3) 后端健康检查
      buf.writeln('\n[Backend /health]');
      final health = await NetworkService.instance.healthCheck();
      buf.writeln('ok: ${health.ok} code: ${health.statusCode ?? '-'}');
      if (health.rawBody != null && health.rawBody!.isNotEmpty) {
        final snippet = health.rawBody!.length > 200
            ? '${health.rawBody!.substring(0, 200)}...'
            : health.rawBody!;
        buf.writeln('body: $snippet');
      }

      if (!mounted) return;
      setState(() { _lastReport = buf.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('测试完成')),
      );
    } catch (e) {
      if (mounted) {
        setState(() { _lastReport = '${buf.toString()}\n异常: $e'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试失败: $e'), backgroundColor: ArtisticTheme.errorColor),
        );
      }
    } finally {
      setState(() { _isRunningTests = false; });
    }
  }

  Future<void> _runHealthCheck() async {
    setState(() { _isRunningHealthCheck = true; });
    try {
      final cfg = ConfigService.instance;
      final health = await NetworkService.instance.healthCheck();
      final details = StringBuffer()
        ..writeln('远程启用: ${cfg.enableRemoteBackend}')
        ..writeln('Base URL: ${cfg.serverBaseUrl}')
        ..writeln('Health OK: ${health.ok}')
        ..writeln('HTTP: ${health.statusCode ?? '-'}')
        ..writeln('时间: ${DateTime.now().toIso8601String()}');
      if (health.rawBody != null && health.rawBody!.isNotEmpty) {
        final snippet = health.rawBody!.length > 600
            ? '${health.rawBody!.substring(0, 600)}...'
            : health.rawBody!;
        details..writeln('\n响应片段:')..writeln(snippet);
      }

      // 展示报告
      if (!mounted) return;
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
                title: const Text('健康检查报告'),
                content: SingleChildScrollView(
                  child: Text(details.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: details.toString()));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('报告已复制到剪贴板')));
                    },
                    child: const Text('复制'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('健康检查失败: $e'), backgroundColor: ArtisticTheme.errorColor),
      );
    } finally {
      setState(() { _isRunningHealthCheck = false; });
    }
  }

  Widget _buildAIAnalysisTab() {
    final cfg = ConfigService.instance;
    final err = ErrorHandlingService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI 服务连接', style: ArtisticTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(cfg.isRemoteConfigured
                          ? '远程已配置: ${cfg.serverBaseUrl}'
                          : '未启用远程后端或地址缺失')),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await NetworkService.instance.healthCheck();
                          if (!mounted) return;
                          final msg = result.ok
                              ? '后端健康 (HTTP ${result.statusCode ?? '-'})'
                              : '后端异常: ${result.message ?? '未知错误'}';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        },
                        icon: const Icon(Icons.health_and_safety),
                        label: const Text('Ping /health'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI 聊天测试', style: ArtisticTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('请在“API调试工具”中进行更全面的对话测试'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/api-debug');
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('打开 API 调试工具'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最近错误', style: ArtisticTheme.titleMedium),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final list = err.getErrorHistory().reversed.take(20).toList();
                      if (list.isEmpty) return const Text('暂无错误');
                      return Column(
                        children: list.map((e) => ListTile(
                          dense: true,
                          title: Text(e.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${e.timestamp} • ${e.context ?? ''}'),
                          leading: const Icon(Icons.error_outline),
                        )).toList(),
                      );
                    }
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () { err.clearErrorHistory(); setState(() {}); },
                        icon: const Icon(Icons.delete),
                        label: const Text('清除错误'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}
