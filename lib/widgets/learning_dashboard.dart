import 'package:flutter/material.dart';
import '../services/real_time_learning_service.dart';
import '../theme/artistic_theme.dart';

class LearningDashboard extends StatefulWidget {
  final RealTimeLearningService learningService;

  const LearningDashboard({
    super.key,
    required this.learningService,
  });

  @override
  State<LearningDashboard> createState() => _LearningDashboardState();
}

class _LearningDashboardState extends State<LearningDashboard> {
  Map<String, dynamic>? _systemStats;
  bool _loading = false;
  
  // 策略权重控制
  final Map<String, double> _strategyWeights = {
    'mood_based': 0.3,
    'engagement_based': 0.25,
    'satisfaction_based': 0.25,
    'diversity': 0.2,
  };

  @override
  void initState() {
    super.initState();
    _loadSystemStats();
  }

  Future<void> _loadSystemStats() async {
    setState(() => _loading = true);
    
    try {
      final stats = await widget.learningService.getLearningSystemStats();
      setState(() {
        _systemStats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载统计数据失败: $e')),
      );
    }
  }

  Future<void> _updateStrategyWeights() async {
    setState(() => _loading = true);
    
    try {
      final success = await widget.learningService.updateStrategyWeights(_strategyWeights);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('策略权重更新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('策略权重更新失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实时学习系统'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadSystemStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemOverview(),
                  const SizedBox(height: 16),
                  _buildModelStats(),
                  const SizedBox(height: 16),
                  _buildStrategyWeights(),
                  const SizedBox(height: 16),
                  _buildPerformanceMetrics(),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue),
                const SizedBox(width: 8),
                Text('系统概览', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_systemStats != null) ...[
              _buildStatItem('总用户数', _systemStats!['total_users']?.toString() ?? '0'),
              _buildStatItem('系统状态', '在线学习中'),
              _buildStatItem('最后更新', '实时'),
            ] else
              const Text('暂无系统数据'),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStats() {
    if (_systemStats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('暂无模型数据'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.model_training, color: Colors.green),
                const SizedBox(width: 8),
                Text('模型统计', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildModelSection('心情预测模型', _systemStats!['mood_predictor']),
            const Divider(),
            _buildModelSection('参与度预测模型', _systemStats!['engagement_predictor']),
            const Divider(),
            _buildModelSection('满意度预测模型', _systemStats!['satisfaction_predictor']),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSection(String title, Map<String, dynamic>? modelData) {
    if (modelData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ArtisticTheme.titleSmall),
          const Text('模型未初始化'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ArtisticTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatItem('训练样本', modelData['sample_count']?.toString() ?? '0')),
            Expanded(child: _buildStatItem('版本', modelData['model_version']?.toString() ?? '1.0.0')),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildStatItem('状态', modelData['is_initialized'] == true ? '已训练' : '未训练')),
            Expanded(child: _buildStatItem('缓冲区', modelData['buffer_size']?.toString() ?? '0')),
          ],
        ),
      ],
    );
  }

  Widget _buildStrategyWeights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.orange),
                const SizedBox(width: 8),
                Text('推荐策略权重', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            ..._strategyWeights.entries.map((entry) => _buildWeightSlider(
              _getStrategyDisplayName(entry.key),
              entry.key,
              entry.value,
            )),
            
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _updateStrategyWeights,
                  icon: const Icon(Icons.save),
                  label: const Text('保存权重'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _resetWeights,
                  child: const Text('重置默认'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSlider(String label, String key, double value) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (newValue) {
            setState(() {
              _strategyWeights[key] = newValue;
              _normalizeWeights();
            });
          },
        ),
      ],
    );
  }

  void _normalizeWeights() {
    final total = _strategyWeights.values.reduce((a, b) => a + b);
    if (total > 0) {
      _strategyWeights.updateAll((key, value) => value / total);
    }
  }

  void _resetWeights() {
    setState(() {
      _strategyWeights['mood_based'] = 0.3;
      _strategyWeights['engagement_based'] = 0.25;
      _strategyWeights['satisfaction_based'] = 0.25;
      _strategyWeights['diversity'] = 0.2;
    });
  }

  String _getStrategyDisplayName(String key) {
    switch (key) {
      case 'mood_based':
        return '心情导向';
      case 'engagement_based':
        return '参与度导向';
      case 'satisfaction_based':
        return '满意度导向';
      case 'diversity':
        return '多样性';
      default:
        return key;
    }
  }

  Widget _buildPerformanceMetrics() {
    if (_systemStats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('暂无性能数据'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple),
                const SizedBox(width: 8),
                Text('性能指标', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildPerformanceItem('心情预测模型', _systemStats!['mood_predictor']),
            _buildPerformanceItem('参与度预测模型', _systemStats!['engagement_predictor']),
            _buildPerformanceItem('满意度预测模型', _systemStats!['satisfaction_predictor']),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String title, Map<String, dynamic>? modelData) {
    if (modelData == null || modelData['latest_performance'] == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('$title: 暂无性能数据'),
      );
    }

    final performance = modelData['latest_performance'] as Map<String, dynamic>;
    final mse = performance['mse'];
    final accuracy = performance['accuracy'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          if (mse != null)
            Text('MSE: ${mse.toStringAsFixed(3)}')
          else if (accuracy != null)
            Text('准确率: ${(accuracy * 100).toStringAsFixed(1)}%')
          else
            const Text('无数据'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
