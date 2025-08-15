import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/artistic_theme.dart';
import '../providers/mood_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/hand_drawn_card.dart';
import '../models/mood_record.dart';

/// 增强的心情记录页面
class EnhancedMoodEntryScreen extends StatefulWidget {
  static const String routeName = '/enhanced_mood_entry';

  const EnhancedMoodEntryScreen({super.key});

  @override
  State<EnhancedMoodEntryScreen> createState() => _EnhancedMoodEntryScreenState();
}

class _EnhancedMoodEntryScreenState extends State<EnhancedMoodEntryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  MoodType? _selectedMood;
  int _intensity = 5;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _triggerController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<String> _gratitudeList = [];
  final TextEditingController _gratitudeController = TextEditingController();
  bool _isPrivate = false;

  final List<String> _availableTags = [
    '工作', '家庭', '健康', '学习', '社交', '运动', '娱乐', '购物', '天气'
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    _triggerController.dispose();
    _gratitudeController.dispose();
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
          '记录心情',
          style: ArtisticTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _selectedMood != null ? _saveMoodEntry : null,
            child: Text(
              '保存',
              style: TextStyle(
                color: _selectedMood != null 
                    ? ArtisticTheme.primaryColor 
                    : ArtisticTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoodSelector(),
                const SizedBox(height: ArtisticTheme.spacingLarge),
                if (_selectedMood != null) ...[
                  _buildIntensitySlider(),
                  const SizedBox(height: ArtisticTheme.spacingLarge),
                  _buildDescriptionInput(),
                  const SizedBox(height: ArtisticTheme.spacingLarge),
                  _buildTriggerInput(),
                  const SizedBox(height: ArtisticTheme.spacingLarge),
                  _buildTagSelector(),
                  const SizedBox(height: ArtisticTheme.spacingLarge),
                  _buildGratitudeSection(),
                  const SizedBox(height: ArtisticTheme.spacingLarge),
                  _buildPrivacySettings(),
                  const SizedBox(height: ArtisticTheme.spacingLarge),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你现在的心情如何？',
              style: ArtisticTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: MoodTypeConfig.getAllMoodTypes().length,
              itemBuilder: (context, index) {
                final mood = MoodTypeConfig.getAllMoodTypes()[index];
                final isSelected = _selectedMood == mood;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? MoodTypeConfig.getMoodColor(mood).withValues(alpha: 0.2)
                          : ArtisticTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                      border: Border.all(
                        color: isSelected 
                            ? MoodTypeConfig.getMoodColor(mood)
                            : ArtisticTheme.textSecondary.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          MoodTypeConfig.getMoodEmoji(mood),
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MoodTypeConfig.getMoodName(mood),
                          style: ArtisticTheme.caption.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '强度等级',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getIntensityDescription(_intensity),
              style: ArtisticTheme.bodySmall.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Row(
              children: [
                Text('1', style: ArtisticTheme.caption),
                Expanded(
                  child: Slider(
                    value: _intensity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _selectedMood != null 
                        ? MoodTypeConfig.getMoodColor(_selectedMood!)
                        : ArtisticTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _intensity = value.round();
                      });
                    },
                  ),
                ),
                Text('10', style: ArtisticTheme.caption),
              ],
            ),
            Center(
              child: Text(
                '$_intensity',
                style: ArtisticTheme.headlineLarge.copyWith(
                  color: _selectedMood != null 
                      ? MoodTypeConfig.getMoodColor(_selectedMood!)
                      : ArtisticTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细描述（可选）',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述一下你的感受...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerInput() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '触发事件（可选）',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '是什么让你有这种感受？',
              style: ArtisticTheme.bodySmall.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            TextField(
              controller: _triggerController,
              decoration: InputDecoration(
                hintText: '例如：工作压力、好消息、天气等...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '相关标签',
              style: ArtisticTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? ArtisticTheme.primaryColor.withValues(alpha: 0.2)
                          : ArtisticTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? ArtisticTheme.primaryColor
                            : ArtisticTheme.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: ArtisticTheme.bodySmall.copyWith(
                        color: isSelected 
                            ? ArtisticTheme.primaryColor
                            : ArtisticTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGratitudeSection() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '感恩记录',
                  style: ArtisticTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '记录今天感恩的事情，培养积极心态',
              style: ArtisticTheme.bodySmall.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            ..._gratitudeList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('${index + 1}. ', style: ArtisticTheme.bodyMedium),
                    Expanded(
                      child: Text(item, style: ArtisticTheme.bodyMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _gratitudeList.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gratitudeController,
                    decoration: InputDecoration(
                      hintText: '我感恩...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                      ),
                    ),
                    onSubmitted: _addGratitudeItem,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addGratitudeItem(_gratitudeController.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPrivacySettings() {
    return HandDrawnCard(
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
        child: Row(
          children: [
            const Icon(Icons.privacy_tip, color: ArtisticTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '隐私设置',
                    style: ArtisticTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '私密记录不会用于数据分析',
                    style: ArtisticTheme.bodySmall.copyWith(
                      color: ArtisticTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getIntensityDescription(int intensity) {
    if (intensity <= 2) return '很轻微';
    if (intensity <= 4) return '轻微';
    if (intensity <= 6) return '中等';
    if (intensity <= 8) return '强烈';
    return '非常强烈';
  }

  void _addGratitudeItem(String text) {
    if (text.trim().isNotEmpty) {
      setState(() {
        _gratitudeList.add(text.trim());
        _gratitudeController.clear();
      });
    }
  }

  Future<void> _saveMoodEntry() async {
    if (_selectedMood == null) return;

    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户未登录')),
      );
      return;
    }

    try {
      final entry = MoodTypeConfig.createMoodEntry(
        userId: userProvider.currentUser!.id,
        moodType: _selectedMood!,
        intensity: _intensity,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        tags: _selectedTags,
        trigger: _triggerController.text.trim().isEmpty 
            ? null 
            : _triggerController.text.trim(),
        gratitude: _gratitudeList,
        isPrivate: _isPrivate,
      );

      await moodProvider.addMoodEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('心情记录已保存 ${MoodTypeConfig.getMoodEmoji(_selectedMood!)}'),
            backgroundColor: ArtisticTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: ArtisticTheme.errorColor,
          ),
        );
      }
    }
  }
}
