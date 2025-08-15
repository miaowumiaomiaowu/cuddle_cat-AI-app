import 'package:flutter/material.dart';
import '../services/advanced_ai_service.dart';
import '../theme/artistic_theme.dart';
import '../models/happiness_checkin.dart';
import '../models/mood_record.dart';

class AnalyticsDashboard extends StatefulWidget {
  final List<MoodEntry> moodRecords;
  final List<HappinessCheckin> checkins;
  final Map<String, dynamic> userStats;

  const AnalyticsDashboard({
    super.key,
    required this.moodRecords,
    required this.checkins,
    required this.userStats,
  });

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final AdvancedAIService _aiService = AdvancedAIService();
  
  Map<String, dynamic>? _moodPrediction;
  Map<String, dynamic>? _clusterAnalysis;
  Map<String, dynamic>? _trainingResult;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    
    try {
      // 构建用户上下文
      final userContext = _aiService.buildUserContext(
        moodRecords: widget.moodRecords,
        checkins: widget.checkins,
      );

      // 预测心情
      _moodPrediction = await _aiService.predictMood(userContext: userContext);

      // 构建用户档案用于聚类分析
      final userProfile = _aiService.buildUserProfile(
        moodRecords: widget.moodRecords,
        checkins: widget.checkins,
        userStats: widget.userStats,
      );

      // 用户聚类分析（需要多个用户数据，这里模拟）
      final userData = [userProfile]; // 实际应用中需要多个用户数据
      if (userData.length >= 10) {
        _clusterAnalysis = await _aiService.analyzeUserClusters(userData: userData);
      }

    } catch (e) {
      debugPrint('Analytics loading failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _trainMoodModel() async {
    setState(() => _loading = true);
    
    try {
      final trainingData = _aiService.buildTrainingData(
        moodRecords: widget.moodRecords,
        checkins: widget.checkins,
      );

      if (trainingData.length >= 50) {
        _trainingResult = await _aiService.trainMoodPredictor(
          trainingData: trainingData,
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('心情预测模型训练完成')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('训练数据不足，需要至少50条心情记录')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模型训练失败: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 数据分析'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAnalytics,
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
                  _buildMoodPredictionCard(),
                  const SizedBox(height: 16),
                  _buildModelTrainingCard(),
                  const SizedBox(height: 16),
                  _buildClusterAnalysisCard(),
                  const SizedBox(height: 16),
                  _buildDataSummaryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildMoodPredictionCard() {
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
                Text('心情预测', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_moodPrediction != null) ...[
              _buildPredictionItem(
                '预测心情',
                _moodPrediction!['mood_category'] ?? '未知',
                _moodPrediction!['predicted_mood']?.toStringAsFixed(1) ?? '0.0',
              ),
              _buildPredictionItem(
                '置信度',
                '${((_moodPrediction!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                '',
              ),
              
              if (_moodPrediction!['suggestions'] != null) ...[
                const SizedBox(height: 8),
                Text('建议:', style: ArtisticTheme.titleSmall),
                const SizedBox(height: 4),
                ...(_moodPrediction!['suggestions'] as List).map((suggestion) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        const Text('• '),
                        Expanded(child: Text(suggestion.toString())),
                      ],
                    ),
                  ),
                ),
              ],
            ] else
              const Text('暂无预测数据，请确保AI服务已启用'),
          ],
        ),
      ),
    );
  }

  Widget _buildModelTrainingCard() {
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
                Text('模型训练', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_trainingResult != null) ...[
              _buildPredictionItem(
                '训练样本数',
                _trainingResult!['training_samples']?.toString() ?? '0',
                '',
              ),
              _buildPredictionItem(
                'R² 分数',
                _trainingResult!['r2_score']?.toStringAsFixed(3) ?? '0.000',
                '',
              ),
              _buildPredictionItem(
                '均方误差',
                _trainingResult!['mse']?.toStringAsFixed(3) ?? '0.000',
                '',
              ),
              
              if (_trainingResult!['feature_importance'] != null) ...[
                const SizedBox(height: 8),
                Text('特征重要性:', style: ArtisticTheme.titleSmall),
                const SizedBox(height: 4),
                ...(_trainingResult!['feature_importance'] as Map<String, dynamic>)
                    .entries
                    .map((entry) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text((entry.value as double).toStringAsFixed(3)),
                        ],
                      ),
                    )),
              ],
            ] else
              Column(
                children: [
                  const Text('模型尚未训练'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _trainMoodModel,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始训练'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterAnalysisCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.orange),
                const SizedBox(width: 8),
                Text('用户聚类', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_clusterAnalysis != null) ...[
              _buildPredictionItem(
                '最优聚类数',
                _clusterAnalysis!['optimal_clusters']?.toString() ?? '0',
                '',
              ),
              
              if (_clusterAnalysis!['cluster_analysis'] != null) ...[
                const SizedBox(height: 8),
                Text('聚类分析:', style: ArtisticTheme.titleSmall),
                const SizedBox(height: 4),
                ...(_clusterAnalysis!['cluster_analysis'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                  final cluster = entry.value as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cluster['label']} (${cluster['percentage']?.toStringAsFixed(1)}%)',
                          style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (cluster['characteristics'] != null)
                          ...((cluster['characteristics'] as List).map((char) =>
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 2),
                              child: Text('• $char', style: ArtisticTheme.caption),
                            ),
                          )),
                      ],
                    ),
                  );
                }),
              ],
            ] else
              const Text('需要更多用户数据进行聚类分析'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummaryCard() {
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
                Text('数据概览', style: ArtisticTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildPredictionItem(
              '心情记录数',
              widget.moodRecords.length.toString(),
              '',
            ),
            _buildPredictionItem(
              '任务完成数',
              widget.checkins.length.toString(),
              '',
            ),
            _buildPredictionItem(
              '数据质量',
              widget.moodRecords.length >= 50 ? '良好' : '需要更多数据',
              '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(String label, String value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: ArtisticTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: ArtisticTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
