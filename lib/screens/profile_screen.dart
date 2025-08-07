import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'records_summary_screen.dart';
import 'ai_chat_screen.dart';
import 'mood_map_screen.dart';
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
          children: [
            const Text('👤', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              '个人中心',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
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
              _buildStatisticsSection(context),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildAchievementsSection(context),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildQuickActionsSection(context),
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

  // 手绘风格统计数据
  Widget _buildStatisticsSection(BuildContext context) {
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
                '我的统计',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🐱', '猫咪等级', '5级'),
              _buildStatItem('💖', '互动次数', '128次'),
              _buildStatItem('🗺️', '旅行足迹', '3个城市'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('📅', '使用天数', '15天'),
              _buildStatItem('🏆', '获得成就', '5个'),
              _buildStatItem('✨', '特殊记录', '3个'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColorLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 成就展示
  Widget _buildAchievementsSection(BuildContext context) {
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
          ...achievements.map((achievement) => _buildAchievementItem(achievement)),
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
          Container(
            child: Text(
              achievement['emoji'] as String,
              style: TextStyle(
                fontSize: 32,
                color: isComplete ? null : Colors.grey,
              ),
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

  // 快捷操作
  Widget _buildQuickActionsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: AppTheme.handDrawnCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '快捷操作',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton('📊', '记录总结', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecordsSummaryScreen(),
                    ),
                  );
                }),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildQuickActionButton('🔄', '数据备份', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('数据备份功能即将开放！')),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton('🤖', 'AI聊天', () {
                  Navigator.pushNamed(context, AIChatScreen.routeName);
                }),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildQuickActionButton('🗺️', '心情地图', () {
                  Navigator.pushNamed(context, MoodMapScreen.routeName);
                }),
              ),
            ],
          ),
          // 开发者工具（仅在调试模式下显示）
          if (kDebugMode) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton('🛠️', '开发者工具', () {
                    Navigator.pushNamed(context, DeveloperToolsScreen.routeName);
                  }),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(child: Container()), // 占位符保持对称
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
