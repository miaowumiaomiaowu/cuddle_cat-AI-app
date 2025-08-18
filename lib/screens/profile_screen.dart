import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/artistic_theme.dart';
import '../providers/cat_provider.dart';
import '../models/cat.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import 'help_center_screen.dart';
import '../providers/happiness_provider.dart';

import 'more_stats_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'developer_tools_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👤', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '个人中心',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.pushNamed(context, HelpCenterScreen.routeName);
            },
            tooltip: '帮助中心',
          ),
          IconButton(
            icon: const Text('⚙️', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: '设置',
          ),
          IconButton(
            icon: const Icon(Icons.build_outlined),
            onPressed: () {
              Navigator.pushNamed(context, DeveloperToolsScreen.routeName);
            },
            tooltip: '开发者工具',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            children: [
              _buildUserInfoCard(context),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildMyCatSection(context),
              const SizedBox(height: AppTheme.spacingLarge),
              // AI聊天设置已由“猫咪性格”统一决定，移除冗余入口
              _buildStatsWithCalendarSection(context),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildLiteAchievementsSection(context),
              const SizedBox(height: AppTheme.spacingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  // 手绘风格用户信息卡片
  Widget _buildUserInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: AppTheme.handDrawnCard.copyWith(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.primaryColorLight.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // 手绘风格头像
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFFAF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🧑‍💼',
                style: TextStyle(fontSize: 50),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '暖猫用户 🐱',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今天也要好好照顾猫咪哦~',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '新手铲屎官',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 编辑按钮
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Text('✏️', style: TextStyle(fontSize: 20)),
              onPressed: () {
                // TODO: 实现编辑个人信息
              },
            ),
          ),
        ],
      ),
    );
  }
  // 统计数据（可视化 + 日历）
  Widget _buildStatsWithCalendarSection(BuildContext context) {
    return Consumer<HappinessProvider>(
      builder: (context, hp, _) {
        final stats = hp.stats;
        final checkins = hp.checkins;
        final completedDates = checkins.map((c) {
          final d = DateTime.parse('${c.ymdDate}T12:00:00');
          return DateTime(d.year, d.month, d.day);
        }).toSet();
        final int uniqueDays = checkins.map((c) => c.ymdDate).toSet().length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: AppTheme.handDrawnCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'AI 相关统计',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, MoreStatsScreen.routeName),
                    child: const Text('更多统计'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniGauge(emoji: '💬', label: '活跃天数', valueText: '$uniqueDays天'),
                  _MiniGauge(emoji: '🎯', label: '完成任务', valueText: '${checkins.length}次'),
                  _MiniGauge(emoji: '🔥', label: '连续打卡', valueText: '${stats?.currentStreak ?? 0}天'),
                  _MiniGauge(emoji: '✅', label: '近7天完成率', valueText: '${(((stats?.completionRate7d ?? 0.0) * 100).round())}%'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text('历史日历', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              _HistoryCalendar(completedDays: completedDates),
            ],
          ),
        );
      },
    );
  }




  // 简化后的成就展示 + 查看更多
  Widget _buildLiteAchievementsSection(BuildContext context) {
    final achievements = [
      {
        'emoji': '🐱',
        'name': '猫咪铲屎官',
        'desc': '成功领养一只猫咪',
        'complete': true,
      },
      {
        'emoji': '💝',
        'name': '爱心满满',
        'desc': '与猫咪互动超过100次',
        'complete': true,
      },
      {
        'emoji': '🗺️',
        'name': '旅行达人',
        'desc': '记录第一个旅行地点',
        'complete': true,
      },
      {
        'emoji': '🏆',
        'name': '资深玩家',
        'desc': '连续使用7天',
        'complete': false,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: AppTheme.handDrawnCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '我的成就',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ...achievements.take(3).map((a) => _buildAchievementItem(a)),
          const SizedBox(height: AppTheme.spacingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/more_achievements'),
              child: const Text('查看更多'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final isComplete = achievement['complete'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: isComplete
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : AppTheme.textHint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isComplete
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.textHint.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            achievement['emoji'] as String,
            style: TextStyle(
              fontSize: 32,
              color: isComplete ? null : Colors.grey,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? AppTheme.textPrimary : AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['desc'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: isComplete ? AppTheme.textSecondary : AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete)
            const Text('✅', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }


  // 我的猫咪（与AI强绑定）
  Widget _buildMyCatSection(BuildContext context) {
    final cat = context.watch<CatProvider>().cat;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: AppTheme.handDrawnCard,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArtisticTheme.cardColor,
              boxShadow: ArtisticTheme.cardShadow,
            ),
            child: const Center(child: Text('🐱', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat?.name ?? '未领养', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  cat != null ? '性格：${_personalityText(cat.personality)}' : '还没有猫咪，去领养一只吧~',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/adopt_cat'),
            child: Text(cat == null ? '去领养' : '更换'),
          )
        ],
      ),
    );
  }



  // 废弃的 AI 偏好辅助样式保留不影响功能，若需可继续用于其他卡片。
  Widget _chipWrap(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColorLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }


  String _personalityText(CatPersonality p) {
    switch (p) {
      case CatPersonality.playful:
        return '可爱/活泼';
      case CatPersonality.calm:
        return '温柔/安静';
      case CatPersonality.curious:
        return '好奇/探索';
      case CatPersonality.lazy:
        return '慵懒/佛系';
      case CatPersonality.social:
        return '外向/亲人';
      case CatPersonality.independent:
        return '高冷/独立';
    }
}
}


// 迷你指标组件（顶层声明）
class _MiniGauge extends StatelessWidget {
  final String emoji;
  final String label;
  final String valueText;
  const _MiniGauge({required this.emoji, required this.label, required this.valueText});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(valueText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// 历史日历（table_calendar 简易接入，顶层声明）
class _HistoryCalendar extends StatefulWidget {
  final Set<DateTime> completedDays;
  const _HistoryCalendar({required this.completedDays});
  @override
  State<_HistoryCalendar> createState() => _HistoryCalendarState();
}
class _HistoryCalendarState extends State<_HistoryCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _showMonthSummary = false;

  @override
  Widget build(BuildContext context) {
    // 计算当前月度完成情况
    final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final next = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    final totalDays = next.difference(first).inDays;
    final completedThisMonth = List.generate(totalDays, (i) => DateTime(_focusedDay.year, _focusedDay.month, i + 1))
        .where((d) => widget.completedDays.contains(DateTime(d.year, d.month, d.day)))
        .length;
    final completionRate = totalDays == 0 ? 0.0 : completedThisMonth / totalDays;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(_showMonthSummary ? '月度汇总' : '历史日历', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showMonthSummary = !_showMonthSummary),
                  icon: Icon(_showMonthSummary ? Icons.calendar_month : Icons.summarize),
                  label: Text(_showMonthSummary ? '查看日历' : '看月汇总'),
                ),
              ],
            ),
          ),
          if (_showMonthSummary)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniGauge(emoji: '✅', label: '本月完成', valueText: '$completedThisMonth天'),
                  _MiniGauge(emoji: '📈', label: '完成率', valueText: '${(completionRate * 100).round()}%'),
                  _MiniGauge(emoji: '🗓️', label: '总天数', valueText: '$totalDays天'),
                ],
              ),
            )
          else
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                defaultTextStyle: TextStyle(color: AppTheme.textPrimary),
                weekendTextStyle: TextStyle(color: AppTheme.textSecondary),
                markersAlignment: Alignment.bottomCenter,
                markersAutoAligned: true,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final d = DateTime(day.year, day.month, day.day);
                  final done = widget.completedDays.contains(d);
                  if (!done) return null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('•', style: TextStyle(color: AppTheme.successColor)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
