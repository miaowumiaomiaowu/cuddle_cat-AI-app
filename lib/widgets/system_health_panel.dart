import 'package:flutter/material.dart';
import '../services/system_health_service.dart';
import '../theme/artistic_theme.dart';

class SystemHealthPanel extends StatefulWidget {
  const SystemHealthPanel({super.key});

  @override
  State<SystemHealthPanel> createState() => _SystemHealthPanelState();
}

class _SystemHealthPanelState extends State<SystemHealthPanel> {
  final SystemHealthService _healthService = SystemHealthService();
  SystemHealthReport? _currentReport;
  DateTime? _lastCheckTime;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLastReport();
  }

  Future<void> _loadLastReport() async {
    final lastReport = await _healthService.getLastHealthReport();
    final lastTime = await _healthService.getLastHealthCheckTime();
    
    setState(() {
      _currentReport = lastReport;
      _lastCheckTime = lastTime;
    });
  }

  Future<void> _performHealthCheck() async {
    setState(() => _loading = true);
    
    try {
      final report = await _healthService.performHealthCheck();
      setState(() {
        _currentReport = report;
        _lastCheckTime = DateTime.now();
        _loading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('健康检查完成: ${report.overallStatus}'),
          backgroundColor: report.isHealthy ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('健康检查失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (_currentReport != null) ...[
          _buildOverallStatus(),
          const SizedBox(height: 16),
          _buildHealthChecks(),
          if (_currentReport!.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildWarnings(),
          ],
          if (_currentReport!.errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrors(),
          ],
        ] else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无健康检查数据，请点击上方按钮进行检查'),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('系统健康检查', style: ArtisticTheme.titleMedium),
        const Spacer(),
        if (_lastCheckTime != null)
          Text(
            '上次检查: ${_formatTime(_lastCheckTime!)}',
            style: ArtisticTheme.caption,
          ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _loading ? null : _performHealthCheck,
          icon: _loading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.health_and_safety),
          label: Text(_loading ? '检查中...' : '开始检查'),
        ),
      ],
    );
  }

  Widget _buildOverallStatus() {
    final report = _currentReport!;
    final isHealthy = report.isHealthy;
    
    return Card(
      color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.warning,
              color: isHealthy ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '系统状态: ${report.overallStatus}',
                    style: ArtisticTheme.titleMedium.copyWith(
                      color: isHealthy ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '检查项目: ${report.checks.length} | '
                    '警告: ${report.warnings.length} | '
                    '错误: ${report.errors.length}',
                    style: ArtisticTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthChecks() {
    final checks = _currentReport!.checks;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('检查结果', style: ArtisticTheme.titleSmall),
            const SizedBox(height: 12),
            ...checks.map((check) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(check.name)),
                  Text(
                    check.status,
                    style: ArtisticTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWarnings() {
    final warnings = _currentReport!.warnings;
    
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text('警告', style: ArtisticTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warning.category,
                          style: ArtisticTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(warning.message, style: ArtisticTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrors() {
    final errors = _currentReport!.errors;
    
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text('错误', style: ArtisticTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error.category,
                          style: ArtisticTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(error.message, style: ArtisticTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}
