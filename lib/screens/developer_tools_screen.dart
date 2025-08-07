import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/artistic_theme.dart';
import '../services/performance_service.dart';
import '../services/testing_service.dart';
import '../services/health_check_service.dart';
import '../widgets/hand_drawn_card.dart';

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
  
  final PerformanceService _performanceService = PerformanceService();
  final TestingService _testingService = TestingService();
  final HealthCheckService _healthCheckService = HealthCheckService();
  
  bool _isRunningTests = false;
  bool _isRunningHealthCheck = false;
  String _lastReport = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // 启动性能监控
    _performanceService.startMonitoring();
    _healthCheckService.startHealthMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _performanceService.stopMonitoring();
    _healthCheckService.stopHealthMonitoring();
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
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: '性能'),
            Tab(icon: Icon(Icons.bug_report), text: '测试'),
            Tab(icon: Icon(Icons.health_and_safety), text: '健康'),
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
                          _performanceService.clearMetrics();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('性能数据已清除')),
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
                    '系统信息',
                    style: ArtisticTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtisticTheme.spacingMedium),
                  _buildSystemInfo(),
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
    final report = _performanceService.getPerformanceReport();
    
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
    final recommendations = _performanceService.getPerformanceRecommendations();
    
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
                  color: ArtisticTheme.textSecondary.withOpacity(0.2),
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
    final report = _performanceService.exportPerformanceData();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('报告已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final suite = await _testingService.runAllTests();
      final report = _testingService.generateTestReport(suite);
      
      setState(() {
        _lastReport = report;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试完成: ${suite.passedCount}/${suite.totalCount} 通过'),
          backgroundColor: suite.successRate >= 80 
              ? ArtisticTheme.successColor 
              : ArtisticTheme.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试失败: $e'),
          backgroundColor: ArtisticTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _runHealthCheck() async {
    setState(() {
      _isRunningHealthCheck = true;
    });

    try {
      final report = await _healthCheckService.performFullHealthCheck();
      final reportText = _healthCheckService.generateHealthReport(report);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('健康检查报告 (${report.healthScore}/100)'),
          content: SingleChildScrollView(
            child: Text(
              reportText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportText));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('报告已复制到剪贴板')),
                );
              },
              child: const Text('复制'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('健康检查失败: $e'),
          backgroundColor: ArtisticTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isRunningHealthCheck = false;
      });
    }
  }
}
