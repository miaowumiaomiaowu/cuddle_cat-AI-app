import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/artistic_theme.dart';
import '../widgets/hand_drawn_card.dart';
import '../services/error_handling_service.dart';

/// 帮助中心页面
class HelpCenterScreen extends StatefulWidget {
  static const String routeName = '/help_center';

  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _feedbackController = TextEditingController();
  final ErrorHandlingService _errorService = ErrorHandlingService();

  final List<FAQItem> _faqItems = [
    FAQItem(
      question: '如何开始记录心情？',
      answer: '点击右下角的浮动按钮，选择"快速心情"进行简单记录，或选择"详细记录"进行完整的心情记录，包括强度、标签、触发事件等。',
      category: '基础使用',
    ),
    FAQItem(
      question: 'AI小暖是如何工作的？',
      answer: 'AI小暖会分析你的心情记录模式，提供个性化的心理支持和建议。你可以通过AI聊天功能与小暖对话，获得即时的情绪支持。',
      category: 'AI功能',
    ),

    FAQItem(
      question: '我的数据安全吗？',
      answer: '应用默认将数据保存在本地（如 SharedPreferences），未接入云同步。请注意自行备份设备数据。',
      category: '隐私安全',
    ),
    FAQItem(
      question: '如何导出我的数据？',
      answer: '当前版本暂未提供导出功能。如需导出，请关注项目更新或在 GitHub 提交需求。',
      category: '数据管理',
    ),
    FAQItem(
      question: '应用卡顿或崩溃怎么办？',
      answer: '请尝试重启应用。如果问题持续，可以在设置中清除缓存，或通过帮助中心反馈问题给我们。',
      category: '技术支持',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
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
          '帮助中心',
          style: ArtisticTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.help_outline), text: '常见问题'),
            Tab(icon: Icon(Icons.feedback), text: '意见反馈'),
            Tab(icon: Icon(Icons.contact_support), text: '联系我们'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildFeedbackTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final categories = _faqItems.map((item) => item.category).toSet().toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索问题...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: ArtisticTheme.backgroundColor,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: ArtisticTheme.spacingLarge),
          
          // FAQ分类
          ...categories.map((category) {
            final categoryItems = _faqItems.where((item) => item.category == category).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    category,
                    style: ArtisticTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ArtisticTheme.primaryColor,
                    ),
                  ),
                ),
                ...categoryItems.map((item) => _buildFAQItem(item)),
                const SizedBox(height: ArtisticTheme.spacingMedium),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item) {
    return HandDrawnCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: ArtisticTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
            child: Text(
              item.answer,
              style: ArtisticTheme.bodyMedium.copyWith(
                height: 1.5,
                color: ArtisticTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
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
                  Row(
                    children: [
                      const Icon(Icons.feedback, color: ArtisticTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '意见反馈',
                        style: ArtisticTheme.headlineSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '你的反馈对我们很重要！请告诉我们你的使用体验、建议或遇到的问题。',
                    style: ArtisticTheme.bodyMedium.copyWith(
                      color: ArtisticTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: '请详细描述你的反馈...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitFeedback,
                      icon: const Icon(Icons.send),
                      label: const Text('提交反馈'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtisticTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: ArtisticTheme.spacingLarge),
          
          // 快速反馈选项
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快速反馈',
                    style: ArtisticTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickFeedbackChip('功能建议', Icons.lightbulb),
                      _buildQuickFeedbackChip('界面优化', Icons.palette),
                      _buildQuickFeedbackChip('性能问题', Icons.speed),
                      _buildQuickFeedbackChip('Bug报告', Icons.bug_report),
                      _buildQuickFeedbackChip('使用困难', Icons.help),
                      _buildQuickFeedbackChip('其他', Icons.more_horiz),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFeedbackChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () {
        _feedbackController.text = '$label: ';
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
      child: Column(
        children: [
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 64,
                    color: ArtisticTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '联系我们',
                    style: ArtisticTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '我们随时为你提供帮助',
                    style: ArtisticTheme.bodyMedium.copyWith(
                      color: ArtisticTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: ArtisticTheme.spacingLarge),
          
          _buildContactItem(
            icon: Icons.web,
            title: '项目主页',
            subtitle: 'github.com/miaowumiaomiaowu',
            onTap: () => _copyToClipboard('https://github.com/miaowumiaomiaowu'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return HandDrawnCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: ArtisticTheme.primaryColor),
        ),
        title: Text(title, style: ArtisticTheme.bodyLarge),
        subtitle: Text(subtitle, style: ArtisticTheme.bodyMedium),
        trailing: const Icon(Icons.copy),
        onTap: onTap,
      ),
    );
  }

  void _submitFeedback() {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      _errorService.showUserFriendlyError(
        context,
        '请输入反馈内容',
        severity: ErrorSeverity.low,
      );
      return;
    }

    // 模拟提交反馈
    _errorService.showSuccessMessage(context, '感谢你的反馈！我们会认真考虑你的建议。');
    _feedbackController.clear();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _errorService.showSuccessMessage(context, '已复制到剪贴板');
  }

}

/// FAQ项目模型
class FAQItem {
  final String question;
  final String answer;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
