import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../providers/mood_provider.dart';
import '../providers/travel_provider.dart';
import '../widgets/enhanced_chart_widget.dart';
import '../widgets/hand_drawn_card.dart';
import '../models/mood_record.dart';

/// 记录总结页面
class RecordsSummaryScreen extends StatefulWidget {
  const RecordsSummaryScreen({super.key});

  @override
  State<RecordsSummaryScreen> createState() => _RecordsSummaryScreenState();
}

class _RecordsSummaryScreenState extends State<RecordsSummaryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0; // 0: 本周, 1: 本月, 2: 本年

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          '记录总结',
          style: ArtisticTheme.headlineLarge.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('本周')),
              const PopupMenuItem(value: 1, child: Text('本月')),
              const PopupMenuItem(value: 2, child: Text('本年')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mood), text: '心情'),
            Tab(icon: Icon(Icons.location_on), text: '旅行'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodSummary(),
          _buildTravelSummary(),
        ],
      ),
    );
  }

  Widget _buildMoodSummary() {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = _getMoodEntriesByPeriod(moodProvider);
        final analytics = moodProvider.analytics;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 心情统计卡片
              _buildMoodStatsCard(entries, analytics),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 心情趋势图
              if (entries.isNotEmpty)
                EnhancedChartWidget(
                  chartType: ChartType.line,
                  data: moodProvider.getMoodTrendData(_getPeriodDays()),
                  title: '心情趋势',
                  subtitle: _getPeriodText(),
                  primaryColor: ArtisticTheme.joyColor,
                  height: 200,
                ),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 心情分布饼图
              if (entries.isNotEmpty)
                EnhancedChartWidget(
                  chartType: ChartType.pie,
                  data: moodProvider.getMoodDistributionData(),
                  title: '心情分布',
                  subtitle: '各种心情的占比',
                  height: 250,
                ),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // AI洞察
              if (analytics != null && analytics.insights.isNotEmpty)
                _buildAIInsights(analytics),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 最近心情记录
              _buildRecentMoodRecords(entries.take(5).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseSummary() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = _getExpenseRecordsByPeriod(expenseProvider);
        final stats = ExpenseStats.fromRecords(records);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 支出统计卡片
              _buildExpenseStatsCard(stats),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 支出趋势图
              EnhancedChartWidget(
                chartType: ChartType.bar,
                data: expenseProvider.getExpenseTrendData(_getPeriodDays()),
                title: '支出趋势',
                subtitle: _getPeriodText(),
                primaryColor: ArtisticTheme.warningColor,
                height: 200,
              ),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 分类分布饼图
              if (stats.categoryDistribution.isNotEmpty)
                EnhancedChartWidget(
                  chartType: ChartType.pie,
                  data: expenseProvider.getCategoryDistributionData(),
                  title: '支出分类',
                  subtitle: '各类支出的占比',
                  height: 250,
                ),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 最近支出记录
              _buildRecentExpenseRecords(records.take(5).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTravelSummary() {
    return Consumer<TravelProvider>(
      builder: (context, travelProvider, child) {
        if (travelProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = _getTravelRecordsByPeriod(travelProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 旅行统计卡片
              _buildTravelStatsCard(records),
              const SizedBox(height: ArtisticTheme.spacingLarge),

              // 最近旅行记录
              _buildRecentTravelRecords(records.take(5).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodStatsCard(MoodStats stats) {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('😊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: ArtisticTheme.spacingSmall),
                Text(
                  '心情统计',
                  style: ArtisticTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '记录总数',
                    '${stats.totalRecords}',
                    Icons.note_alt,
                    ArtisticTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '主导心情',
                    stats.dominantMood,
                    Icons.mood,
                    ArtisticTheme.joyColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均强度',
                    stats.averageIntensity.toStringAsFixed(1),
                    Icons.trending_up,
                    ArtisticTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseStatsCard(ExpenseStats stats) {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 24)),
                const SizedBox(width: ArtisticTheme.spacingSmall),
                Text(
                  '支出统计',
                  style: ArtisticTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总支出',
                    stats.formattedTotalAmount,
                    Icons.account_balance_wallet,
                    ArtisticTheme.warningColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '记录数',
                    '${stats.totalRecords}',
                    Icons.receipt,
                    ArtisticTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '日均支出',
                    stats.formattedAverageDailyExpense,
                    Icons.trending_up,
                    ArtisticTheme.infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelStatsCard(List records) {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: ArtisticTheme.spacingSmall),
                Text(
                  '旅行统计',
                  style: ArtisticTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '记录总数',
                    '${records.length}',
                    Icons.location_on,
                    ArtisticTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '本期新增',
                    '${records.length}',
                    Icons.add_location,
                    ArtisticTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均评分',
                    '4.5',
                    Icons.star,
                    ArtisticTheme.joyColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: ArtisticTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: ArtisticTheme.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentMoodRecords(List<MoodRecord> records) {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近心情记录',
              style: ArtisticTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            ...records.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(record.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.mood, style: ArtisticTheme.bodyMedium),
                        if (record.note != null)
                          Text(
                            record.note!,
                            style: ArtisticTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${record.timestamp.month}/${record.timestamp.day}',
                    style: ArtisticTheme.caption,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenseRecords(List<ExpenseRecord> records) {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近支出记录',
              style: ArtisticTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            ...records.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    ExpenseCategories.getCategoryEmoji(record.category),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.title, style: ArtisticTheme.bodyMedium),
                        Text(
                          ExpenseCategories.getCategoryName(record.category),
                          style: ArtisticTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${record.amount.toStringAsFixed(2)}',
                        style: ArtisticTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ArtisticTheme.warningColor,
                        ),
                      ),
                      Text(
                        '${record.timestamp.month}/${record.timestamp.day}',
                        style: ArtisticTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTravelRecords(List records) {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近旅行记录',
              style: ArtisticTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            if (records.isEmpty)
              Center(
                child: Text(
                  '暂无旅行记录',
                  style: ArtisticTheme.bodyMedium.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
              )
            else
              ...records.map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.title, style: ArtisticTheme.bodyMedium),
                          Text(
                            record.locationName,
                            style: ArtisticTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${record.date.month}/${record.date.day}',
                      style: ArtisticTheme.caption,
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  List<MoodRecord> _getMoodRecordsByPeriod(MoodProvider provider) {
    switch (_selectedPeriod) {
      case 0:
        return provider.getWeeklyMoodRecords();
      case 1:
        return provider.getMonthlyMoodRecords();
      case 2:
        final now = DateTime.now();
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1);
        return provider.getMoodRecordsByDateRange(startOfYear, endOfYear);
      default:
        return provider.getWeeklyMoodRecords();
    }
  }

  List<ExpenseRecord> _getExpenseRecordsByPeriod(ExpenseProvider provider) {
    switch (_selectedPeriod) {
      case 0:
        return provider.getWeeklyExpenseRecords();
      case 1:
        return provider.getMonthlyExpenseRecords();
      case 2:
        final now = DateTime.now();
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1);
        return provider.getExpenseRecordsByDateRange(startOfYear, endOfYear);
      default:
        return provider.getWeeklyExpenseRecords();
    }
  }

  List _getTravelRecordsByPeriod(TravelProvider provider) {
    // 简化实现，返回所有记录
    return provider.records;
  }

  int _getPeriodDays() {
    switch (_selectedPeriod) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 365;
      default:
        return 7;
    }
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 0:
        return '最近7天';
      case 1:
        return '最近30天';
      case 2:
        return '本年度';
      default:
        return '最近7天';
    }
  }
}
