import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/artistic_theme.dart';
import '../widgets/artistic_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 设置项状态
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _autoSaveEnabled = true;
  bool _darkModeEnabled = false;
  double _interactionSensitivity = 0.5;
  String _selectedLanguage = 'zh_CN';
  String _userName = '暖猫用户';
  
  // 控制器
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _nameController.text = _userName;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      _autoSaveEnabled = prefs.getBool('auto_save_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _interactionSensitivity = prefs.getDouble('interaction_sensitivity') ?? 0.5;
      _selectedLanguage = prefs.getString('selected_language') ?? 'zh_CN';
      _userName = prefs.getString('user_name') ?? '暖猫用户';
      _nameController.text = _userName;
    });
  }
  
  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('haptic_enabled', _hapticEnabled);
    await prefs.setBool('auto_save_enabled', _autoSaveEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setDouble('interaction_sensitivity', _interactionSensitivity);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setString('user_name', _userName);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('设置已保存'),
          backgroundColor: ArtisticTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '设置',
          style: ArtisticTheme.headlineLarge.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              '保存',
              style: ArtisticTheme.bodyMedium.copyWith(
                color: ArtisticTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 个人信息设置
            _buildPersonalSection(),
            const SizedBox(height: ArtisticTheme.spacingLarge),
            
            // 应用设置
            _buildAppSection(),
            const SizedBox(height: ArtisticTheme.spacingLarge),
            
            // 交互设置
            _buildInteractionSection(),
            const SizedBox(height: ArtisticTheme.spacingLarge),
            
            // 数据管理
            _buildDataSection(),
            const SizedBox(height: ArtisticTheme.spacingLarge),
            
            // 关于应用
            _buildAboutSection(),
            const SizedBox(height: ArtisticTheme.spacingXXLarge),
          ],
        ),
      ),
    );
  }
  
  // 个人信息设置
  Widget _buildPersonalSection() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
      decoration: ArtisticTheme.artisticCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👤', style: TextStyle(fontSize: 24)),
              const SizedBox(width: ArtisticTheme.spacingSmall),
              Text(
                '个人信息',
                style: ArtisticTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtisticTheme.spacingMedium),
          
          // 用户名设置
          Text(
            '用户名',
            style: ArtisticTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingSmall),
          Container(
            decoration: ArtisticTheme.glassEffect,
            child: TextField(
              controller: _nameController,
              onChanged: (value) {
                setState(() {
                  _userName = value;
                });
              },
              decoration: InputDecoration(
                hintText: '请输入用户名',
                hintStyle: ArtisticTheme.bodyMedium.copyWith(
                  color: ArtisticTheme.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 应用设置
  Widget _buildAppSection() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
      decoration: ArtisticTheme.artisticCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚙️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: ArtisticTheme.spacingSmall),
              Text(
                '应用设置',
                style: ArtisticTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtisticTheme.spacingMedium),
          
          // 通知设置
          _buildSwitchTile(
            title: '推送通知',
            subtitle: '接收猫咪状态和活动提醒',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          // 声音设置
          _buildSwitchTile(
            title: '音效',
            subtitle: '播放交互音效和背景音乐',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          
          // 触觉反馈
          _buildSwitchTile(
            title: '触觉反馈',
            subtitle: '交互时的震动反馈',
            value: _hapticEnabled,
            onChanged: (value) {
              setState(() {
                _hapticEnabled = value;
              });
            },
          ),
          
          // 深色模式
          _buildSwitchTile(
            title: '深色模式',
            subtitle: '使用深色主题（即将支持）',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              // 主题切换暂未提供
            },
          ),
        ],
      ),
    );
  }
  
  // 交互设置
  Widget _buildInteractionSection() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
      decoration: ArtisticTheme.artisticCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤏', style: TextStyle(fontSize: 24)),
              const SizedBox(width: ArtisticTheme.spacingSmall),
              Text(
                '交互设置',
                style: ArtisticTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtisticTheme.spacingMedium),
          
          // 交互灵敏度
          Text(
            '手势灵敏度',
            style: ArtisticTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingSmall),
          Row(
            children: [
              const Text('低', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _interactionSensitivity,
                  onChanged: (value) {
                    setState(() {
                      _interactionSensitivity = value;
                    });
                    if (_hapticEnabled) {
                      HapticFeedback.selectionClick();
                    }
                  },
                  activeColor: ArtisticTheme.primaryColor,
                  inactiveColor: ArtisticTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              const Text('高', style: TextStyle(fontSize: 12)),
            ],
          ),
          
          const SizedBox(height: ArtisticTheme.spacingMedium),
          
          // 语言设置
          Text(
            '语言',
            style: ArtisticTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: ArtisticTheme.spacingSmall),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: ArtisticTheme.spacingMedium),
            decoration: ArtisticTheme.glassEffect,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: 'zh_CN',
                    child: Text('简体中文'),
                  ),
                  DropdownMenuItem(
                    value: 'en_US',
                    child: Text('English (即将支持)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 数据管理
  Widget _buildDataSection() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
      decoration: ArtisticTheme.artisticCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: ArtisticTheme.spacingSmall),
              Text(
                '数据管理',
                style: ArtisticTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtisticTheme.spacingMedium),
          
          // 自动保存
          _buildSwitchTile(
            title: '自动保存',
            subtitle: '自动保存猫咪状态和旅行记录',
            value: _autoSaveEnabled,
            onChanged: (value) {
              setState(() {
                _autoSaveEnabled = value;
              });
            },
          ),
          
          const SizedBox(height: ArtisticTheme.spacingMedium),
          
          // 数据操作按钮
          Row(
            children: [
              Expanded(
                child: ArtisticButton(
                  text: '导出数据',
                  icon: Icons.download,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据导出暂未提供。')),
                    );
                  },
                  style: ArtisticButtonStyle.secondary,
                ),
              ),
              const SizedBox(width: ArtisticTheme.spacingMedium),
              Expanded(
                child: ArtisticButton(
                  text: '导入数据',
                  icon: Icons.upload,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据导入暂未提供。')),
                    );
                  },
                  style: ArtisticButtonStyle.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 关于应用
  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
      decoration: ArtisticTheme.artisticCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: ArtisticTheme.spacingSmall),
              Text(
                '关于应用',
                style: ArtisticTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtisticTheme.spacingMedium),

          _buildInfoRow('应用版本', '1.0.0'),
          _buildInfoRow('开发者', '韩嘉仪 / Han Jiayi'),
          _buildInfoRow('项目主页', 'github.com/miaowumiaomiaowu'),

          const SizedBox(height: ArtisticTheme.spacingMedium),

          ArtisticButton(
            text: '用户协议与隐私政策',
            icon: Icons.description,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('隐私与协议页面暂未提供。')),
              );
            },
            style: ArtisticButtonStyle.outline,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
  
  // 构建开关项
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArtisticTheme.spacingSmall),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtisticTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: ArtisticTheme.bodySmall.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ArtisticTheme.primaryColor,
          ),
        ],
      ),
    );
  }
  
  // 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArtisticTheme.spacingXSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ArtisticTheme.bodyMedium.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: ArtisticTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
